//
//  IRGen.swift
//  Vist
//
//  Created by Josef Willsher on 15/11/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//

import Foundation

enum IRError : ErrorType {
    case NoOperator
    case MisMatchedTypes, WrongFunctionApplication(String), NoLLVMType
    case NoBody, InvalidFunction, NoVariable(String), NoType(String), NoFunction(String), NoBool, TypeNotFound, NotMutable(String)
    case CannotAssignToVoid, CannotAssignToType(Expr.Type)
    case SubscriptingNonVariableTypeNotAllowed, SubscriptOutOfBounds
    case NoProperty(String), NotAStruct, CannotMutateParam
}


// global builder and module references
private var builder: LLVMBuilderRef = nil
private var module: LLVMModuleRef = nil


/// A type which can generate LLVM IR code
private protocol IRGenerator {
    func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef
}

private protocol BasicBlockGenerator {
    func bbGen(innerStackFrame stackFrame: StackFrame, fn: LLVMValueRef) throws -> LLVMBasicBlockRef
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Helpers
//-------------------------------------------------------------------------------------------------------------------------

private func isFloatType(t: LLVMTypeKind) -> Bool {
    return [LLVMFloatTypeKind, LLVMDoubleTypeKind, LLVMHalfTypeKind, LLVMFP128TypeKind].contains(t)
}

extension Expr {
    
    private func exprCodeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        if let x = try (self as? IRGenerator)?.codeGen(stackFrame) { return x }
        fatalError("\(self.dynamicType) not IR Generator")
    }
    
    private func exprbbGen(innerStackFrame stackFrame: StackFrame, fn: LLVMValueRef) throws -> LLVMBasicBlockRef {
        if let x = try (self as? BasicBlockGenerator)?.bbGen(innerStackFrame: stackFrame, fn: fn) { return x }
        fatalError("\(self.dynamicType) not IR Generator")
    }
}


extension CollectionType where
    Generator.Element == COpaquePointer,
    Index == Int,
    Index.Distance == Int {
    
    /// get a ptr to the memory of the collection
    func ptr() -> UnsafeMutablePointer<Generator.Element> {
        
        let p = UnsafeMutablePointer<Generator.Element>.alloc(count)
        
        for i in self.startIndex..<self.endIndex {
            p.advancedBy(i).initialize(self[i])
        }
        
        return p
    }
    
}

extension LLVMBool : Swift.BooleanType {
    init(_ b: Bool) {
        self.init(b ? 1 : 0)
    }
    
    public var boolValue: Bool {
        return self == 1
    }
}

private func codeGenIn(stackFrame: StackFrame) -> Expr throws -> LLVMValueRef {
    return { e in
        try e.exprCodeGen(stackFrame)
    }
}





/**************************************************************************************************************************/
// MARK: -                                                 IR GEN


//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Literals
//-------------------------------------------------------------------------------------------------------------------------

extension IntegerLiteral : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) -> LLVMValueRef {
        let rawType = NativeType.Int(size: size)
        let value = LLVMConstInt(rawType.ir(), UInt64(val), LLVMBool(false))
        
        guard let type = self.type as? StructType else { fatalError("Int literal with no type") }
        return type.initialiseWithBuiltin(value, module: module, builder: builder)
    }
}


extension FloatingPointLiteral : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) -> LLVMValueRef {
        return LLVMConstReal(type!.ir(), val)
    }
}


extension BooleanLiteral : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) -> LLVMValueRef {
        let rawType = NativeType.Bool
        let value = LLVMConstInt(rawType.ir(), UInt64(val.hashValue), LLVMBool(false))
        
        guard let type = self.type as? StructType else { fatalError("Bool literal with no type") }
        return type.initialiseWithBuiltin(value, module: module, builder: builder)
    }
}


extension StringLiteral : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) -> LLVMValueRef {
        
        var s: COpaquePointer = nil
        str
            .cStringUsingEncoding(NSUTF8StringEncoding)?
            .withUnsafeBufferPointer { ptr in
            s = LLVMConstString(ptr.baseAddress, UInt32(ptr.count), LLVMBool(true))
        }
        
        return s
//        return arr!.codeGen(stackFrame)
    }
}

//extension CharacterExpr : IRGenerator {
//    
//    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
//        
//        let x = String(val).cStringUsingEncoding(NSUTF8StringEncoding)![0]
//        return LLVMConstInt(LLVMIntType(8), UInt64(x), LLVMBool(false))
//    }
//}


//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Variables
//-------------------------------------------------------------------------------------------------------------------------

extension Variable : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        let variable = try stackFrame.variable(name ?? "")
        
        return try variable.load(name ?? "")
    }
}


extension AssignmentExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        if let arr = value as? ArrayExpr{
            //if asigning to array
            
            let a = try arr.arrInstance(stackFrame)
            a.allocHead(builder, name: name, mutable: isMutable)
            stackFrame.addVariable(name, val: a)
            
            return a.ptr
        }
        else if let ty = value.type as? FnType {
            // handle assigning a closure
            
            // Function being made
            let fn = LLVMAddFunction(module, name, ty.ir())
            
            // make and move into entry block
            let entryBlock = LLVMAppendBasicBlock(fn, "entry")
            LLVMPositionBuilderAtEnd(builder, entryBlock)
            
            // stack frame of fn
            let fnStackFrame = StackFrame(block: entryBlock, function: fn, parentStackFrame: stackFrame)
            
            // value’s IR, this needs to be called and returned
            let v = try value.exprCodeGen(fnStackFrame)
            
            let num = LLVMCountParams(fn)
            for i in 0..<num {
                let param = LLVMGetParam(fn, i)
                let name = ("$\(Int(i))")
                LLVMSetValueName(param, name)
            }
            
            // args of `fn`
            let args = (0..<num)
                .map { LLVMGetParam(fn, $0) }
                .ptr()
            defer { args.dealloc(Int(num)) }
            
            // call function pointer `v`
            let call = LLVMBuildCall(builder, v, args, num, "")
            
            // return this value from `fn`
            LLVMBuildRet(builder, call)
            
            // move into bb from before
            LLVMPositionBuilderAtEnd(builder, stackFrame.block)
            
            return fn
        }
        else {
            // all other types
            
            // create value
            let v = try value.exprCodeGen(stackFrame)
            
            // checks
            guard v != nil else { throw IRError.CannotAssignToType(value.dynamicType) }
            let type = LLVMTypeOf(v)
            guard type != LLVMVoidType() else { throw IRError.CannotAssignToVoid }
            
            // create variable
            let variable: MutableVariable
            if let t = value.type as? StructType where value.type is StructType {
                let properties = t.members.map {
                    ($0.0, $0.1.ir(), $0.2)
                }
                variable = MutableStructVariable.alloc(builder, type: type, mutable: isMutable, properties: properties)
            }
            else {
                variable = ReferenceVariable.alloc(builder, type: type, name: name ?? "", mutable: isMutable)
            }
            // Load in memory
            try variable.store(v)
            
            // update stack frame variables
            stackFrame.addVariable(name, val: variable)
            
            return v
        }
    }
}


extension MutationExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        if let object = object as? Variable {
            // object = newValue
            
            let variable = try stackFrame.variable(object.name)
            
            if let arrayVariable = variable as? ArrayVariable, arrayExpression = value as? ArrayExpr {
                
                let newArray = try arrayExpression.arrInstance(stackFrame)
                arrayVariable.assignFrom(builder, arr: newArray)
            }
            else {
                let new = try value.exprCodeGen(stackFrame)
                
                guard let v = variable as? MutableVariable where v.mutable else { throw IRError.NotMutable("") }
                try v.store(new)
            }
        }
        else if let sub = object as? ArraySubscriptExpr {
            
            let arr = try sub.backingArrayVariable(stackFrame)
            
            let i = try sub.index.exprCodeGen(stackFrame)
            let val = try value.exprCodeGen(stackFrame)
            
            arr.store(val, inElementAtIndex: i)
        }
        else if let prop = object as? PropertyLookupExpr {
            // foo.bar = meme
            
            guard let n = prop.object as? Variable else { fatalError("CannotGetPropertyFromNonVariableType") }
            guard let variable = try stackFrame.variable(n.name) as? MutableStructVariable else {
                if try stackFrame.variable(n.name) is ParameterStructVariable { throw IRError.CannotMutateParam }
                throw IRError.NoVariable(n.name)
            }
            
            guard variable.mutable else { throw IRError.NotMutable(n.name) }
            guard try variable.propertyIsMutable(prop.name) else { throw IRError.NotMutable("\(n.name).\(prop.name)") }
            
            let val = try value.exprCodeGen(stackFrame)
            
            try variable.store(val, inPropertyNamed: prop.name)
        }
        
        return nil
    }
    
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Exprs
//-------------------------------------------------------------------------------------------------------------------------

extension BinaryExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        let lIR = try lhs.exprCodeGen(stackFrame), rIR = try rhs.exprCodeGen(stackFrame)
        
        // make function
        let fn = LLVMGetNamedFunction(module, mangledName)
        
        // arguments
        let argBuffer = [lIR, rIR].ptr()
        defer { argBuffer.dealloc(2) }
        
        guard fn != nil && LLVMCountParams(fn) == UInt32(2) else { throw IRError.WrongFunctionApplication(op) }
        
        let doNotUseName = self.type == NativeType.Void || self.type == NativeType.Null || self.type == nil
        let n = doNotUseName ? "" : "\(op)_res"
        
        // add call to IR
        return LLVMBuildCall(builder, fn, argBuffer, UInt32(2), n)
        
    }
}


extension Void : IRGenerator {
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        return nil
    }
}


//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Functions
//-------------------------------------------------------------------------------------------------------------------------

extension FunctionCallExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        let argCount = self.args.elements.count
        let args = try self.args.elements.map(codeGenIn(stackFrame))

        // Lookup
        if let function = builtinBinaryInstruction(name, builder: builder, module: module) {
            guard args.count == 2 else { throw IRError.WrongFunctionApplication(name) }
            return try function(args[0], args[1])
        }
        else if let function = builtinInstruction(name, builder: builder, module: module) {
            guard args.count == 0 else { throw IRError.WrongFunctionApplication(name) }
            return function()
        }
        
        // make function
        let fn = LLVMGetNamedFunction(module, mangledName)
        
        // arguments
        let argBuffer = args.ptr()
        defer { argBuffer.dealloc(argCount) }
        
        guard fn != nil && LLVMCountParams(fn) == UInt32(argCount) else {
            throw IRError.WrongFunctionApplication(name) }
        
        let doNotUseName = type == NativeType.Void || type == NativeType.Null || type == nil
        let n = doNotUseName ? "" : "\(name)_res"
        
        // add call to IR
        return LLVMBuildCall(builder, fn, argBuffer, UInt32(argCount), n)
    }
    
}


private extension FunctionType {
    
    private func params() throws -> [LLVMTypeRef] {
        guard let res = (type as? FnType)?.nonVoid else { throw IRError.TypeNotFound }
        return try res.map(ir)
    }
}


extension FunctionDecl : IRGenerator {
    // function definition
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        let type: FnType
        let startIndex: Int // where do the user's params start being used, 0 for free funcs and 1 for methods
        let parentType: StructType? // the type of self is its a method
        
        let args = fnType.args, argCount = args.elements.count
        
        if let parent = self.parent {
            guard let _parentType = parent.type as? StructType else { fatalError("Parent not a struct type") }
            guard let _type = self.fnType.type as? FnType else { throw IRError.TypeNotFound }
            
            type = FnType(params: [_parentType] + _type.params, returns: _type.returns)
            startIndex = 1
            parentType = _parentType
        }
        else {
            let args = fnType.args, argCount = args.elements.count
            guard let t = self.fnType.type as? FnType else { throw IRError.TypeNotFound }
            
            type = t
            startIndex = 0
            parentType = nil
        }
        
        // If existing function definition
        let _fn = LLVMGetNamedFunction(module, mangledName)
        if _fn != nil && LLVMCountParams(_fn) == UInt32(argCount + startIndex) && LLVMCountBasicBlocks(_fn) != 0 && LLVMGetEntryBasicBlock(_fn) != nil {
            return _fn
        }
        
        // Set params
        let argBuffer = try fnType.params().ptr()
        defer { argBuffer.dealloc(argCount) }
        
        // make function
        let functionType = type.ir()
        let function = LLVMAddFunction(module, mangledName, functionType)
        LLVMSetFunctionCallConv(function, LLVMCCallConv.rawValue)
        
        // add attrs
        for a in attrs {
            a.addAttrTo(function)
        }
        
        // setup function block
        let entryBlock = LLVMAppendBasicBlock(function, "entry")
        LLVMPositionBuilderAtEnd(builder, entryBlock)
        
        // Add function type to stack frame
        stackFrame.addFunctionType(mangledName, val: functionType)
        
        // stack frame internal to function, needs params setting and then the block should be added *inside* the bbGen function
        let functionStackFrame = StackFrame(block: entryBlock, function: function, parentStackFrame: stackFrame)
            
        // set function param names and update table
        for i in 0..<argCount {
            let param = LLVMGetParam(function, UInt32(i + startIndex))
            let name = (impl?.params.elements[i] as? ValueType)?.name ?? ("$\(i)")
            LLVMSetValueName(param, name)
            
            let ty = LLVMTypeOf(param)
            if LLVMGetTypeKind(ty) == LLVMStructTypeKind {
                
                let tyName = (args.elements[i] as! ValueType).name
                let t = try stackFrame.type(tyName)
                
                let memTys = t.members.map { ($0.0, $0.1.ir(), $0.2) }
                
                let s = ParameterStructVariable(type: ty, val: param, builder: builder, properties: memTys)
                functionStackFrame.addVariable(name, val: s)
            }
            else {
                let s = StackVariable(val: param, builder: builder)
                functionStackFrame.addVariable(name, val: s)
            }
        }
        
        // if is a method
        if let parentType = parentType {
            // set up access to self's properties here
            let param = LLVMGetParam(function, 0)
            LLVMSetValueName(param, "self")
            
            let memTys = parentType.members.map { ($0.0, $0.1.ir(), $0.2) }
            
            let s = ParameterStructVariable(type: parentType.ir(), val: param, builder: builder, properties: memTys)
            functionStackFrame.addVariable("self", val: s)
        }
        
        // generate bb for body
        do {
            try impl?.body.bbGen(innerStackFrame: functionStackFrame, ret: type.returns.ir())
        }
        catch {
            LLVMDeleteFunction(function)
            throw error
        }
        
        return function
    }
}


extension ReturnExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        if expr.type?.ir() == LLVMVoidType() {
            return LLVMBuildRetVoid(builder)
        }
        
        let v = try expr.exprCodeGen(stackFrame)
        return LLVMBuildRet(builder, v)
    }
    
}


extension BlockExpr {
    
    private func bbGen(innerStackFrame stackFrame: StackFrame, ret: LLVMValueRef) throws {
        
        // code gen for function
        for exp in exprs {
            try exp.exprCodeGen(stackFrame)
        }
        
        if exprs.isEmpty || (ret != nil && ret == LLVMVoidType()) {
            LLVMBuildRetVoid(builder)
        }
        
        // reset builder head to parent’s stack frame
        LLVMPositionBuilderAtEnd(builder, stackFrame.parentStackFrame!.block)
    }
    
}


extension ClosureExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        guard let type = type as? FnType else { fatalError() }
        
        let argBuffer = try type.params.map(ir).ptr()
        defer { argBuffer.dealloc(type.params.count) }
        
        let name = "closure"//.mangle()
        
        let functionType = type.ir()
        let function = LLVMAddFunction(module, name, functionType)
        
        // setup function block
        let entryBlock = LLVMAppendBasicBlock(function, "entry")
        LLVMPositionBuilderAtEnd(builder, entryBlock)
        
        stackFrame.addFunctionType(name, val: functionType)
        
        let functionStackFrame = StackFrame(function: function, parentStackFrame: stackFrame)
        
        // set function param names and update table
        for i in 0..<type.params.count {
            let param = LLVMGetParam(function, UInt32(i))
            let name = parameters.isEmpty ? "$\(i)" : parameters[i]
            LLVMSetValueName(param, name)
            
//            let ty = LLVMTypeOf(param)
//            if LLVMGetTypeKind(ty) == LLVMStructTypeKind {
//                let ptr = LLVMBuildAlloca(builder, ty, "ptr\(name)")
//                LLVMBuildStore(builder, param, ptr)
//                
//                let tyName = type.params[i].name
//                let t = try stackFrame.type(tyName)
//                
//                let memTys = try t.members.map { ($0.0, try $0.1.ir(), $0.2) }
//                
//                let s = MutableStructVariable(type: ty, ptr: ptr, mutable: false, builder: builder, properties: memTys)
//                functionStackFrame.addVariable(name, val: s)
//            }
//            else {
                let s = StackVariable(val: param, builder: builder)
                functionStackFrame.addVariable(name, val: s)
//            }
        }
        
        do {
            try BlockExpr(exprs: exprs).bbGen(innerStackFrame: functionStackFrame, ret: type.returns.ir())
        } catch {
            LLVMDeleteFunction(function)
            throw error
        }
        
        return function
    }
}


//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                              Control flow
//-------------------------------------------------------------------------------------------------------------------------

extension ElseIfBlockExpr {
    
    private func ifBBID(n n: Int) -> String {
        return condition == nil ? "else\(n)" : "then\(n)"
    }
}

extension ConditionalExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        // block leading into and out of current if block
        var ifIn: LLVMBasicBlockRef = stackFrame.block
        var ifOut: LLVMBasicBlockRef = nil
        
        let leaveIf = LLVMAppendBasicBlock(stackFrame.function, "cont")
        var rets = true // whether all blocks return
        
        for (i, statement) in statements.enumerate() {
            
            LLVMPositionBuilderAtEnd(builder, ifIn)
            
            /// States whether the block being appended returns from the current scope
            let returnsFromScope = statement.block.exprs.contains { $0 is ReturnExpr }
            rets = rets && returnsFromScope
            
            // condition
            let cond = try statement.condition?.exprCodeGen(stackFrame)
            if i < statements.count-1 {
                ifOut = LLVMAppendBasicBlock(stackFrame.function, "cont\(i)")
            }
            else { //else or final else-if statement
                if rets { // If the block returns from the current scope, remove the cont block
                    LLVMRemoveBasicBlockFromParent(leaveIf)
                }
                ifOut = leaveIf
            }
            
            // block and associated stack frame - the then / else block
            let tStackFrame = StackFrame(function: stackFrame.function, parentStackFrame: stackFrame)
            let block = try statement.bbGen(innerStackFrame: tStackFrame, contBlock: leaveIf, name: statement.ifBBID(n: i))
            
            // move builder to in scope
            LLVMPositionBuilderAtEnd(builder, ifIn)
            
            if let cond = cond { //if statement, make conditonal jump
                
                let v = try cond.load("value", type: statement.condition?.type, builder: builder)
                
                LLVMBuildCondBr(builder, v, block, ifOut)
            }
            else { // else statement, uncondtional jump
                LLVMBuildBr(builder, block)
                break
            }
            
            ifIn = ifOut
        }
        
        LLVMPositionBuilderAtEnd(builder, leaveIf)
        stackFrame.block = ifOut
        
        return nil
    }
}


private extension ElseIfBlockExpr {
    
    /// Create the basic block for the if Expr
    private func bbGen(innerStackFrame stackFrame: StackFrame, contBlock: LLVMBasicBlockRef, name: String) throws -> LLVMBasicBlockRef {
        
        // add block
        let basicBlock = LLVMAppendBasicBlock(stackFrame.function, name)
        LLVMPositionBuilderAtEnd(builder, basicBlock)
        
        // parse code
        try block.bbGenInline(stackFrame: stackFrame)
        
        // if the block does continues to the contBlock, move the builder there
        let returnsFromScope = block.exprs.contains { $0 is ReturnExpr }
        if !returnsFromScope {
            LLVMBuildBr(builder, contBlock)
            LLVMPositionBuilderAtEnd(builder, contBlock)
        }
        
        return basicBlock
    }
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Loops
//-------------------------------------------------------------------------------------------------------------------------


extension ForInLoopExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        // generate loop and termination blocks
        let loop = LLVMAppendBasicBlock(stackFrame.function, "loop")
        let afterLoop = LLVMAppendBasicBlock(stackFrame.function, "afterloop")
        
        let rangeIterator = try iterator.exprCodeGen(stackFrame)
        
        let start = try rangeIterator.load("start", type: iterator.type, builder: builder)
        let endValue = try rangeIterator.load("end", type: iterator.type, builder: builder).load("value", type: stackFrame.type("Int"), builder: builder)
        
        // move into loop block
        LLVMBuildBr(builder, loop)
        LLVMPositionBuilderAtEnd(builder, loop)
        
        let stdIntType = try stackFrame.type("Int")
        
        // define variable phi node
        let name = binded.name ?? ""
        let loopCount = LLVMBuildPhi(builder, stdIntType.ir(), name)
        
        // add incoming value to phi node
        let num1 = [start].ptr(), incoming1 = [stackFrame.block].ptr()
        defer { num1.dealloc(1); incoming1.dealloc(1) }
        LLVMAddIncoming(loopCount, num1, incoming1, 1)
        
        // iterate and add phi incoming
        let one = LLVMConstInt(LLVMInt64Type(), UInt64(1), LLVMBool(false))
        let value = try loopCount.load("value", type: stdIntType, builder: builder)
        let next = LLVMBuildAdd(builder, one, value, "n\(name)")
        
        // initialise next i value with the iterated num
        let nextInt = stdIntType.initialiseWithBuiltin(next, module: module, builder: builder)
        
        // gen the IR for the inner block
        let lv = StackVariable(val: loopCount, builder: builder)
        let loopStackFrame = StackFrame(block: loop, vars: [name: lv], function: stackFrame.function, parentStackFrame: stackFrame)
        try block.bbGenInline(stackFrame: loopStackFrame)
        
        // conditional break
        let comp = LLVMBuildICmp(builder, LLVMIntSLE, next, endValue, "looptest")
        LLVMBuildCondBr(builder, comp, loop, afterLoop)
        
        // move back to loop / end loop
        let num2 = [nextInt].ptr(), incoming2 = [loopStackFrame.block].ptr()
        defer { num2.dealloc(1); incoming2.dealloc(1) }
        LLVMAddIncoming(loopCount, num2, incoming2, 1)
        
        LLVMPositionBuilderAtEnd(builder, afterLoop)
        stackFrame.block = afterLoop
        
        return nil
    }
    
}


// TODO: Break statements and passing break-to bb in scope
extension WhileLoopExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        // generate loop and termination blocks
        let loop = LLVMAppendBasicBlock(stackFrame.function, "loop")
        let afterLoop = LLVMAppendBasicBlock(stackFrame.function, "afterloop")
        
        // whether to enter the while, first while check
        let initialCond = try iterator.condition.exprCodeGen(stackFrame)
        let initialCondV = try initialCond.load("value", type: iterator.condition.type, builder: builder)

        // move into loop block
        LLVMBuildCondBr(builder, initialCondV, loop, afterLoop)
        LLVMPositionBuilderAtEnd(builder, loop)
        
        // gen the IR for the inner block
        let loopStackFrame = StackFrame(block: loop, function: stackFrame.function, parentStackFrame: stackFrame)
        try block.bbGenInline(stackFrame: loopStackFrame)
        
        // conditional break
        let conditionalRepeat = try iterator.condition.exprCodeGen(stackFrame)
        let conditionalRepeatV = try conditionalRepeat.load("value", type: iterator.condition.type, builder: builder)
        LLVMBuildCondBr(builder, conditionalRepeatV, loop, afterLoop)
        
        // move back to loop / end loop
        LLVMPositionBuilderAtEnd(builder, afterLoop)
        stackFrame.block = afterLoop
        
        return nil
    }
    
}


private extension ScopeExpr {
    
    /// Generates children’s code directly into the current scope & block
    private func bbGenInline(stackFrame stackFrame: StackFrame) throws {
        
        // code gen for function
        for exp in exprs {
            try exp.exprCodeGen(stackFrame)
        }
    }
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Arrays
//-------------------------------------------------------------------------------------------------------------------------

extension ArrayExpr : IRGenerator {
    
    private func arrInstance(stackFrame: StackFrame) throws -> ArrayVariable {
        
        // assume homogeneous
        guard let elementType = elType?.ir() else { throw IRError.TypeNotFound }
        let arrayType = LLVMArrayType(elementType, UInt32(arr.count))
        
        // allocate memory for arr
        let a = LLVMBuildArrayAlloca(builder, arrayType, nil, "arr")
        
        // obj
        let vars = try arr.map { try $0.exprCodeGen(stackFrame) }
        let variable = ArrayVariable(ptr: a, elType: elementType, arrType: arrayType, builder: builder, vars: vars)
        
        return variable
    }
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        return try arrInstance(stackFrame).load()
    }
    
}


extension ArraySubscriptExpr : IRGenerator {
    
    private func backingArrayVariable(stackFrame: StackFrame) throws -> ArrayVariable {
        
        guard let v = arr as? Variable else { throw IRError.SubscriptingNonVariableTypeNotAllowed }
        guard let arr = try stackFrame.variable(v.name) as? ArrayVariable else { throw IRError.SubscriptingNonVariableTypeNotAllowed }
        
        return arr
    }
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {

        let arr = try backingArrayVariable(stackFrame)
        let idx = try index.exprCodeGen(stackFrame)
        
        return arr.loadElementAtIndex(idx)
    }
    
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Structs
//-------------------------------------------------------------------------------------------------------------------------

extension StructExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        stackFrame.addType(name, val: self.type! as! StructType)

        for i in initialisers {
            try i.codeGen(stackFrame)
        }
        
        for m in methods {
            try m.codeGen(stackFrame)
        }

        return nil
    }
    
}


extension InitialiserDecl : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        let args = ty.args, argCount = args.elements.count
        guard let
            type = type as? FnType,
            name = parent?.name,
            parentType = parent?.type,
            parentProperties = parent?.properties else { throw IRError.TypeNotFound }
        
        // make function
        let functionType = type.ir()
        let function = LLVMAddFunction(module, mangledName, functionType)
        LLVMSetFunctionCallConv(function, LLVMCCallConv.rawValue)
        LLVMAddFunctionAttr(function, LLVMAlwaysInlineAttribute)
        
        guard let impl = self.impl else {
            return function
        }
        
        let entry = LLVMAppendBasicBlock(function, "entry")
        LLVMPositionBuilderAtEnd(builder, entry)

        // Add function type to stack frame
        stackFrame.addFunctionType(name, val: functionType)
        
        // stack frame internal to initialiser, cannot capture from surrounding scope
        let initStackFrame = StackFrame(function: function, parentStackFrame: nil)
        
        // set function param names and update table
        // TODO: Split this out into a function for funcs & closures to use as well
        for i in 0..<argCount {
            let param = LLVMGetParam(function, UInt32(i))
            let name = (impl.params.elements[i] as? ValueType)?.name ?? ("$\(i)")
            LLVMSetValueName(param, name)
            
            let ty = LLVMTypeOf(param)
            if LLVMGetTypeKind(ty) == LLVMStructTypeKind {
                
                // TODO: Fix how this info is brought down
                let tyName = (args.elements[i] as! ValueType).name
                let t = try stackFrame.type(tyName)
                
                let memTys = t.members.map { ($0.0, $0.1.ir(), $0.2) }
                
                let s = ParameterStructVariable(type: ty, val: param, builder: builder, properties: memTys)
                initStackFrame.addVariable(name, val: s)
                
            }
            else {
                let s = StackVariable(val: param, builder: builder)
                initStackFrame.addVariable(name, val: s)
            }
        }
        // 3 ways of passing a struct into a function
        //  - Pass in pointer to copy
        //  - Pass in object and make copy there
        //  - Expand struct to params of function, so a fn taking ({i64 i32} i32) becomes (i64 i32 i32)
        //      - This is harder bacause all property lookups have to be remapped to a param
        
        // property types, names, & mutability for stack frame
        let properties = try parentProperties.map { assignment -> (String, LLVMValueRef, Bool) in
            if let t = assignment.value.type { return (assignment.name, t.ir(), assignment.isMutable) } else { throw IRError.NoProperty(assignment.name) }
        }
        
        // allocate struct
        let s = MutableStructVariable.alloc(builder, type: parentType.ir(), mutable: true, properties: properties)
        stackFrame.addVariable(name, val: s)
        
        // add struct properties into scope
        for el in parentProperties {
            let p = AssignablePropertyVariable(name: el.name, str: s)
            initStackFrame.addVariable(el.name, val: p)
        }
        
        // add args into scope
        for exp in impl.body.exprs {
            try exp.exprCodeGen(initStackFrame)
        }
        
        // return struct instance from init function
        let str = s.load()
        LLVMBuildRet(builder, str)
        
        LLVMPositionBuilderAtEnd(builder, stackFrame.block)
        return function
    }
}

extension PropertyLookupExpr : IRGenerator {
        
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        guard let n = object as? Variable else { fatalError("Cannot Get Property From Non Variable Type") }
        guard let variable = try stackFrame.variable(n.name) as? StructVariable else { throw IRError.NoVariable(n.name) }
        
        let val = try variable.loadPropertyNamed(name)
        
        return val
    }
}


extension MethodCallExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        // get method from module
        let f = LLVMGetNamedFunction(module, mangledName)
        let c = self.params.elements.count + 1
        
        // need to add self to beginning of params
        let params = try ([object as Expr] + self.params.elements)
            .map(codeGenIn(stackFrame))
            .ptr()
        defer { params.dealloc(c) }
        
        let doNotUseName = type == NativeType.Void || type == NativeType.Null || type == nil
        let n = doNotUseName ? "" : "\(name)_res"
        
        return LLVMBuildCall(builder, f, params, UInt32(c), n)
    }
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 Tuples
//-------------------------------------------------------------------------------------------------------------------------

extension TupleExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        if elements.count == 0 { return nil }
        
        guard let type = self.type as? StructType else { fatalError("No type for tuple") }
        let typeIR = type.ir()
        
        let memeberIR = try elements.map { try $0.exprCodeGen(stackFrame) }
        
        let membersWithLLVMTypes = type.members.map { ($0.0, $0.1.ir(), $0.2) }
        let s = MutableStructVariable.alloc(builder, type: typeIR, mutable: false, properties: membersWithLLVMTypes)
        
        for (i, el) in memeberIR.enumerate() {
            try s.store(el, inPropertyNamed: "\(i)")
        }
        
        return s.load()
    }
}

extension TupleMemberLookupExpr : IRGenerator {
    
    private func codeGen(stackFrame: StackFrame) throws -> LLVMValueRef {
        
        guard let n = object as? Variable else { fatalError("Cannot Get Property From Non Variable Type") }
        guard let variable = try stackFrame.variable(n.name) as? StructVariable else { throw IRError.NoVariable(n.name) }
        
        let val = try variable.loadPropertyNamed(String(index))
        
        return val
    }
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                                 AST Gen
//-------------------------------------------------------------------------------------------------------------------------


extension AST {
    
    func IRGen(module m: LLVMModuleRef, isLibrary: Bool, stackFrame s: StackFrame) throws {
        
        // initialise global objects
        builder = LLVMCreateBuilder()
        module = m
        
        // main arguments
        let argBuffer = [LLVMTypeRef]().ptr()
        defer { argBuffer.dealloc(0) }
        
        // make main function & add to IR
        let functionType = LLVMFunctionType(LLVMInt64Type(), argBuffer, UInt32(0), LLVMBool(false))
        let mainFunction = LLVMAddFunction(module, "main", functionType)
        
        // Setup BB & stack frame
        let programEntryBlock = LLVMAppendBasicBlock(mainFunction, "entry")
        LLVMPositionBuilderAtEnd(builder, programEntryBlock)
        
        let stackFrame = StackFrame(block: programEntryBlock, function: mainFunction, parentStackFrame: s)
        
        if isLibrary {
            let e = exprs.filter {
                $0 is FunctionDecl || $0 is StructExpr
            }
            
            for exp in e {
                try exp.exprCodeGen(stackFrame)
            }
        }
        else {
            for exp in exprs {
                try exp.exprCodeGen(stackFrame)
            }
        }
        
        if isLibrary {
            LLVMDeleteFunction(mainFunction)
        }
        else {
            LLVMBuildRet(builder, LLVMConstInt(LLVMInt64Type(), 0, LLVMBool(false)))
        }
    }
}










