//
//  VIRGen.swift
//  Vist
//
//  Created by Josef Willsher on 01/03/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

import class Foundation.NSString

protocol ValueEmitter {
    /// Emit the get-accessor for a VIR rvalue
    func emitRValue(module: Module, scope: Scope) throws -> Accessor
}
protocol StmtEmitter {
    /// Emit the VIR for an AST statement
    func emitStmt(module: Module, scope: Scope) throws
}

protocol LValueEmitter: ValueEmitter {
    /// Emit the get/set-accessor for a VIR lvalue
    func emitLValue(module: Module, scope: Scope) throws -> GetSetAccessor
}

/// A libaray without a main function can emit vir for this
protocol LibraryTopLevel: ASTNode {}


extension Expr {
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        throw VIRError.notGenerator
    }
}
extension Stmt {
    func emitStmt(module: Module, scope: Scope) throws {
        throw VIRError.notGenerator
    }
}
extension Decl {
    func emitStmt(module: Module, scope: Scope) throws {
        throw VIRError.notGenerator
    }
}
extension ASTNode {
    func emit(module: Module, scope: Scope) throws {
        if case let rval as ValueEmitter = self {
            let unusedAccessor = try rval.emitRValue(module: module, scope: scope)
            // function calls return values at -1
            // unused values could have a ref count of 0 and not be deallocated
            // any unused function calls should have dealloc_unowned_object called on them
            if rval is FunctionCallExpr {
                try unusedAccessor.deallocUnowned()
            }
        }
        else if case let stmt as StmtEmitter = self {
            try stmt.emitStmt(module: module, scope: scope)
        }
    }
}

extension Collection where Iterator.Element == ASTNode {
    
    func emitBody(module: Module, scope: Scope) throws {
        for x in self {
            try x.emit(module: module, scope: scope)
        }
    }
    
}

infix operator .+ {}
/// Used for constructing string descriptions
/// eg `irName: irName .+ "subexpr"`
func .+ (lhs: String?, rhs: String) -> String? {
    guard let l = lhs else { return nil }
    return "\(l).\(rhs)"
}

extension AST {
    
    func emitVIR(module: Module, isLibrary: Bool) throws {
        
        let builder = module.builder!
        let scope = Scope(module: module)
        
        if isLibrary {
            // if its a library we dont emit a main, and just virgen on any decls/statements
            for case let g as LibraryTopLevel in exprs {
                try g.emit(module: module, scope: scope)
            }
        }
        else {
            let mainTy = FunctionType(params: [], returns: BuiltinType.void)
            let main = try builder.buildFunction(name: "main", type: mainTy, paramNames: [])
            
            try exprs.emitBody(module: module, scope: scope)
            
            builder.insertPoint.function = main
            try scope.releaseVariables(deleting: true)
            try builder.buildReturnVoid()
        }
        
    }
}



// MARK: Lower AST nodes to instructions

extension IntegerLiteral : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        let int = try module.builder.build(inst: IntLiteralInst(val: val, size: 64))
        let std = try module.builder.build(inst: StructInitInst(type: StdLib.intType, values: int))
        return try std.accessor()
    }
}

extension BooleanLiteral : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        let bool = try module.builder.build(inst: BoolLiteralInst(val: val))
        let std = try module.builder.build(inst: StructInitInst(type: StdLib.boolType, values: bool))
        return try std.accessor()
    }
}

extension StringLiteral : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
       
        // string_literal lowered to:
        //  - make global string constant
        //  - GEP from it to get the first element
        //
        // String initialiser allocates %1 bytes of memory and stores %0 into it
        // String exposes methods to move buffer and change size
        // String `print` passes `base` into a cshim functions which print the buffer
        //    - wholly if its contiguous UTF8
        //    - char by char if it contains UTF16 ocde units
        
        let string = try module.builder.build(inst: StringLiteralInst(val: str))
        let length = try module.builder.build(inst: IntLiteralInst(val: str.utf8.count + 1, size: 64, irName: "size"))
        let isUTFU = try module.builder.build(inst: BoolLiteralInst(val: string.isUTF8Encoded, irName: "isUTF8"))
        
        let initialiser = try module.getOrInsertStdLibFunction(named: "String",
                                                               argTypes: [BuiltinType.opaquePointer, BuiltinType.int(size: 64), BuiltinType.bool])!
        let std = try module.builder.buildFunctionCall(function: initialiser,
                                                       args: [Operand(string), Operand(length), Operand(isUTFU)])
        
        return try std.accessor()
    }
}


extension VariableDecl : ValueEmitter {
        
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        let val = try value.emitRValue(module: module, scope: scope)
        
        if isMutable {
            // if its mutable, allocate stack memory to store into
            let variable = try val.getMemCopy()
            scope.insert(variable: variable, name: name)
            return variable
        }
        else {
            // if immutable, pass by reg value
            let variable = try module.builder.build(inst: VariableInst(value: val.aggregateGetValue(), irName: name)).accessor()
            try variable.retain()
            scope.insert(variable: variable, name: name)
            return variable
        }
    }
}

extension FunctionCall/*: VIRGenerator*/ {
    
    func argOperands(module: Module, scope: Scope) throws -> [Operand] {
        guard case let fnType as FunctionType = fnType?.importedType(in: module) else {
            throw VIRError.paramsNotTyped
        }
        
        return try zip(argArr, fnType.params).map { rawArg, paramType in
            let arg = try rawArg.emitRValue(module: module, scope: scope)
            try arg.retain()
            return try arg.boxedAggregateGetValue(expectedType: paramType)
            }
            .map(Operand.init(_:))
    }
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        guard case let fnType as FunctionType = fnType?.importedType(in: module) else {
            throw VIRError.paramsNotTyped
        }
        let args = try argOperands(module: module, scope: scope)
        
        if let stdlib = try module.getOrInsertStdLibFunction(named: name, argTypes: fnType.params) {
            return try module.builder.buildFunctionCall(function: stdlib, args: args).accessor()
        }
        else if
            let prefixRange = name.range(of: "Builtin."),
            let instruction = BuiltinInst(rawValue: name.replacingCharacters(in: prefixRange, with: "")) {
            
            let a = args.map { $0.value! }
            return try module.builder.build(inst: BuiltinInstCall(inst: instruction, args: a)).accessor()
        }
        else if let function = module.function(named: mangledName) {
            return try module.builder.buildFunctionCall(function: function, args: args).accessor()
        }
        else {
            fatalError("No function name=\(name), mangledName=\(mangledName)")
        }
    }
}


extension FuncDecl : StmtEmitter {
        
    func emitStmt(module: Module, scope: Scope) throws {
        
        guard let type = fnType.type else { throw VIRError.noType(#file) }
        
        // if has body
        guard let impl = impl else {
            try module.builder.buildFunctionPrototype(name: mangledName, type: type, attrs: attrs)
            return
        }
        
        let originalInsertPoint = module.builder.insertPoint
        
        // find proto/make function and move into it
        let function = try module.builder.getOrBuildFunction(name: mangledName, type: type, paramNames: impl.params, attrs: attrs)
        module.builder.insertPoint.function = function
        
        // make scope and occupy it with params
        let fnScope = Scope(parent: scope, function: function)
        
        // add the explicit method parameters
        for paramName in impl.params {
            let paramAccessor = try function.param(named: paramName).accessor()
            fnScope.insert(variable: paramAccessor, name: paramName)
        }
        // A method calling convention means we have to pass `self` in, and tell vars how
        // to access it, and `self`’s properties
        if case .method(let selfType, _) = type.callingConvention {
            // We need self to be passed by ref as a `RefParam`
            let selfParam = function.params![0]
            let selfVar = try selfParam.accessor()
            fnScope.insert(variable: selfVar, name: "self") // add `self`
            
            if case let type as NominalType = selfType {
                
                switch selfVar {
                // if it is a ref self the self accessors are lazily calculated struct GEP
                case let selfRef as GetSetAccessor:
                    for property in type.members {
                        let pVar = LazyRefAccessor {
                            try module.builder.build(inst: StructElementPtrInst(object: selfRef.reference(), property: property.name, irName: property.name))
                        }
                        fnScope.insert(variable: pVar, name: property.name)
                    }
                // If it is a value self then we do a struct extract to get self elements
                // case is Accessor:
                default:
                    for property in type.members {
                        let pVar = LazyAccessor(module: module) {
                            try module.builder.build(inst: StructExtractInst(object: selfVar.getValue(), property: property.name, irName: property.name))
                        }
                        fnScope.insert(variable: pVar, name: property.name)
                    }
                }
                
            }
            
        }
        
        // vir gen for body
        try impl.body.emitStmt(module: module, scope: fnScope)

        // TODO: look at exit nodes of block, not just place we're left off
        // add implicit `return ()` for a void function without a return expression
        if type.returns == BuiltinType.void && !function.instructions.contains({$0 is ReturnInst}) {
            try fnScope.releaseVariables(deleting: true)
            try module.builder.buildReturnVoid()
        }
        else {
            fnScope.removeVariables()
        }
        
        module.builder.insertPoint = originalInsertPoint
    }
}




extension VariableExpr : LValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        return try scope.variable(named: name)!
    }
    func emitLValue(module: Module, scope: Scope) throws -> GetSetAccessor {
        return try scope.variable(named: name)! as! GetSetAccessor
    }
}

extension ReturnStmt : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        let retVal = try expr.emitRValue(module: module, scope: scope)
        
        // before returning, we release all variables in the scope...
        try scope.releaseVariables(deleting: false, except: retVal)
        // ...and release-unowned the return value if its owned by the scope
        //    - we exepct the caller of the function to retain the value or
        //      dealloc it, so we return it as +0
        if scope.isInScope(variable: retVal) {
            try retVal.releaseUnowned()
        } else {
            // if its brought in by another scope, we can safely release
            try retVal.release() // FIXME: CHECK THIS
        }
        
        let boxed = try retVal.boxedAggregateGetValue(expectedType: expectedReturnType)
        return try module.builder.buildReturn(value: boxed).accessor()
    }
}

extension TupleExpr : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        if self.elements.isEmpty { return try VoidLiteralValue().accessor() }
        
        guard let type = try _type?.importedType(in: module).getAsTupleType() else { throw VIRError.noType(#file) }
        let elements = try self.elements.map { try $0.emitRValue(module: module, scope: scope).aggregateGetValue() }
        
        return try module.builder.build(inst: TupleCreateInst(type: type, elements: elements)).accessor()
    }
}

extension TupleMemberLookupExpr : ValueEmitter, LValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        let tuple = try object.emitRValue(module: module, scope: scope).getValue()
        return try module.builder.build(inst: TupleExtractInst(tuple: tuple, index: index)).accessor()
    }
    
    func emitLValue(module: Module, scope: Scope) throws -> GetSetAccessor {
        guard case let o as LValueEmitter = object else { fatalError() }
        
        let tuple = try o.emitLValue(module: module, scope: scope)
        return try module.builder.build(inst: TupleElementPtrInst(tuple: tuple.reference(), index: index)).accessor
    }
}

extension PropertyLookupExpr : LValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        switch object._type {
        case is StructType:
            let object = try self.object.emitRValue(module: module, scope: scope)
            return try module.builder.build(inst: StructExtractInst(object: object.getValue(), property: propertyName)).accessor()
            
        case is ConceptType:
            let object = try self.object.emitRValue(module: module, scope: scope).referenceBacked().reference()
            let ptr = try module.builder.build(inst: OpenExistentialPropertyInst(existential: object, propertyName: propertyName))
            return try module.builder.build(inst: LoadInst(address: ptr)).accessor()
            
        default:
            fatalError()
        }
    }
    
    func emitLValue(module: Module, scope: Scope) throws -> GetSetAccessor {
        guard case let o as LValueEmitter = object else { fatalError() }
        
        switch object._type {
        case is StructType:
            let str = try o.emitLValue(module: module, scope: scope)
            return try module.builder.build(inst: StructElementPtrInst(object: str.reference(), property: propertyName)).accessor
            
        case is ConceptType:
            let object = try self.object.emitRValue(module: module, scope: scope).referenceBacked().reference()
            return try module.builder.build(inst: OpenExistentialPropertyInst(existential: object, propertyName: propertyName)).accessor
            
        default:
            fatalError()
        }
        
    }
    
}

extension BlockExpr : StmtEmitter {
    
    func emitStmt(module: Module, scope: Scope) throws {
        try exprs.emitBody(module: module, scope: scope)
    }
}

extension ConditionalStmt : StmtEmitter {
    
    func emitStmt(module: Module, scope: Scope) throws {
        
        // the if statement's exit bb
        let exitBlock = try module.builder.appendBasicBlock(name: "exit")
        
        for (index, branch) in statements.enumerated() {
            
            // the success block, and the failure
            let ifBlock = try module.builder.appendBasicBlock(name: branch.condition == nil ? "else.\(index)" : "if.\(index)")
            try exitBlock.move(after: ifBlock)
            let failBlock: BasicBlock
            
            if let c = branch.condition {
                let cond = try c.emitRValue(module: module, scope: scope).getValue()
                let v = try module.builder.build(inst: StructExtractInst(object: cond, property: "value"))
                
                // if its the last block, a condition fail takes
                // us to the exit
                if index == statements.index(before: statements.endIndex) {
                    failBlock = exitBlock
                }
                    // otherwise it takes us to a landing pad for the next
                    // condition to be evaluated
                else {
                    failBlock = try module.builder.appendBasicBlock(name: "fail.\(index)")
                    try exitBlock.move(after: failBlock)
                }
                
                try module.builder.buildCondBreak(if: Operand(v),
                                                  to: (block: ifBlock, args: nil),
                                                  elseTo: (block: failBlock, args: nil))
            }
                // if its unconditional, we go to the exit afterwards
            else {
                failBlock = exitBlock
                try module.builder.buildBreak(to: ifBlock)
            }
            
            // move into the if block, and evaluate its expressions
            // in a new scope
            let ifScope = Scope(parent: scope, function: scope.function)
            module.builder.insertPoint.block = ifBlock
            try branch.block.emitStmt(module: module, scope: ifScope)
            
            // once we're done in success, break to the exit and
            // move into the fail for the next round
            if !ifBlock.instructions.contains({$0.instIsTerminator}) {
                try module.builder.buildBreak(to: exitBlock)
                module.builder.insertPoint.block = failBlock
            }
                // if there is a return or break, we dont jump to exit
                // if its the last block and the exit is not used, we can remove
            else if index == statements.index(before: statements.endIndex) && exitBlock.predecessors.isEmpty {
                try exitBlock.eraseFromParent()
            }
                // otherwise, if its not the end, we move to the exit
            else {
                module.builder.insertPoint.block = failBlock
            }
            
        }
        
    }
    
}


extension ForInLoopStmt : StmtEmitter {
    
    
    /**
     For in loops rely on generators. Array could define a generator:
     
     ```vist
     extend Array {
        func generate::->Element = {
            for i in 0 ..< endIndex do
                yield self[i]
        }
     }
     ```
     
     A for in loop can revieve from the generator--the yielding allows it
     to look like the function returns many times. In reality `generate` is
     lowered to take a closure that takes its return type:
     
     ```vir
     // written type:
     func @generate : &method (%HalfOpenRange) -> %Int
     // lowered type:
     func @generate_mHalfOpenRangePtI : &method (%HalfOpenRange, %*(&thin (%Int) -> %Builtin.Void)) -> %Builtin.Void
     ```
     
     The `yield` applies this closure. The closure can also be thick, this allows
     it to capture state from the loop's scope.
     
     TODO:
     Returning from the loop requires longjmping out -- this is gross
     */
    func emitStmt(module: Module, scope: Scope) throws {
        
        // get generator function
        guard let functionName = generatorFunctionName,
            let generatorFunction = try module.function(named: functionName) ?? module.getOrInsertStdLibFunction(mangledName: functionName),
            let yieldType = generatorFunction.type.yieldType else { fatalError() }
        
        // If we got the generator function from the stdlib, remangle 
        // the name non cannonically
        if let t = StdLib.function(mangledName: functionName) {
            generatorFunction.name = functionName.demangleName().mangle(type: t)
        }
        let entryInsertPoint = module.builder.insertPoint
        
        // create a loop thunk, which stores the loop body
        let n = (entryInsertPoint.function?.name).map { "\($0)." } ?? "" // name
        let loopThunk = try module.builder.buildUniqueFunction(name: "\(n)loop_thunk",
                                                               type: FunctionType(params: [yieldType]),
                                                               paramNames: [binded.name])
        
        // save current position
        module.builder.insertPoint = entryInsertPoint
        
        // make the semantic scope for the loop
        // if the scope captures from the parent, it goes through a global variable
        let loopClosure = Closure.wrapping(function: loopThunk), generatorClosure = Closure.wrapping(function: generatorFunction)
        let loopScope = Scope.capturing(parent: scope,
                                        function: loopClosure.thunk,
                                        captureDelegate: loopClosure,
                                        breakPoint: module.builder.insertPoint)
        let loopVarAccessor = try loopClosure.thunk.param(named: binded.name).accessor()
        loopScope.insert(variable: loopVarAccessor, name: binded.name)
        
        // emit body for loop thunk
        module.builder.insertPoint.function = loopClosure.thunk // move to loop thunk
        try block.emitStmt(module: module, scope: loopScope)
        try module.builder.buildReturnVoid()
        
        // move back out
        module.builder.insertPoint = entryInsertPoint
        
        // require that we inline the loop thunks early
        loopClosure.thunk.inlineRequirement = .always
        loopClosure.thunk.inlineRequirement = .always
        
        // get the instance of the generator
        let generator = try self.generator.emitRValue(module: module, scope: scope).referenceBacked().aggregateReference()
        
        // call the generator function from loop position
        // apply the scope it requests
        
        let call = try module.builder.buildFunctionCall(function: generatorClosure.thunk,
                                                        args: [PtrOperand(generator), loopClosure.thunk.buildFunctionPointer()])
        
        if let entryInst = entryInsertPoint.inst, let entryFunction = entryInsertPoint.function {
            // set the captured global values' lifetimes
            for captured in loopClosure.capturedGlobals {
                captured.lifetime = GlobalValue.Lifetime(start: entryInst,
                                                         end: call,
                                                         globalName: captured.globalName,
                                                         owningFunction: entryFunction)
            }
        }
        
        try loopScope.releaseVariables(deleting: true)

    }
}


extension YieldStmt : StmtEmitter {
    func emitStmt(module: Module, scope: Scope) throws {
        
        guard case let loopThunk as RefParam = module.builder.insertPoint.function?.params?[1]
//            where loopThunk as
            else { fatalError() }
        
        let val = try expr.emitRValue(module: module, scope: scope)
        let param = try val.aggregateGetValue()
        
        try module.builder.buildFunctionApply(function: PtrOperand(loopThunk), returnType: BuiltinType.void, args: [Operand(param)])
    }
}


extension WhileLoopStmt : StmtEmitter {
    
    func emitStmt(module: Module, scope: Scope) throws {
        
        // setup blocks
        let condBlock = try module.builder.appendBasicBlock(name: "cond")
        let loopBlock = try module.builder.appendBasicBlock(name: "loop")
        let exitBlock = try module.builder.appendBasicBlock(name: "loop.exit")
        
        // condition check in cond block
        try module.builder.buildBreak(to: condBlock)
        module.builder.insertPoint.block = condBlock
        
        let condBool = try condition.emitRValue(module: module, scope: scope).getValue()
        let cond = try module.builder.build(inst: StructExtractInst(object: condBool, property: "value", irName: "cond"))
        
        // cond break into/past loop
        try module.builder.buildCondBreak(if: Operand(cond),
                                          to: (block: loopBlock, args: nil),
                                          elseTo: (block: exitBlock, args: nil))
        
        let loopScope = Scope(parent: scope, function: scope.function)
        // build loop block
        module.builder.insertPoint.block = loopBlock // move into
        try block.emitStmt(module: module, scope: loopScope) // gen stmts
        try loopScope.releaseVariables(deleting: true)
        try module.builder.buildBreak(to: condBlock) // break back to condition check
        module.builder.insertPoint.block = exitBlock  // move past -- we're done
    }
}

extension StructExpr : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        guard let type = type else { throw irGenError(.notTyped) }
        
        module.getOrInsert(type: type)
        
        for i in initialisers {
            try i.emitStmt(module: module, scope: scope)
        }
        
        for m in methods {
            guard let t = m.fnType.type else { fatalError() }
            try module.getOrInsertFunction(named: m.mangledName, type: t, attrs: m.attrs)
        }
        for m in methods {
            try m.emitStmt(module: module, scope: scope)
        }
        
        return try VoidLiteralValue().accessor()
    }
}

extension ConceptExpr : ValueEmitter {

    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        guard let type = type else { throw irGenError(.notTyped) }
        
        module.getOrInsert(type: type)
        
        for m in requiredMethods {
            try m.emitStmt(module: module, scope: scope)
        }
        
        return try VoidLiteralValue().accessor()
    }

}

extension InitialiserDecl : StmtEmitter {
    
    func emitStmt(module: Module, scope: Scope) throws {
        guard let initialiserType = ty.type, let selfType = parent?.type else { throw VIRError.noType(#file) }
        
        // if has body
        guard let impl = impl else {
            try module.builder.buildFunctionPrototype(name: mangledName, type: initialiserType)
            return
        }
        
        let originalInsertPoint = module.builder.insertPoint
        
        // make function and move into it
        let function = try module.builder.buildFunction(name: mangledName, type: initialiserType, paramNames: impl.params)
        module.builder.insertPoint.function = function
        
        function.inlineRequirement = .always
        
        // make scope and occupy it with params
        let fnScope = Scope(parent: scope, function: function)
        
        let selfVar: GetSetAccessor
        
        if selfType.isHeapAllocated {
            selfVar = try RefCountedAccessor.allocObject(type: selfType, module: module)
        }
        else {
            selfVar = try module.builder.build(inst: AllocInst(memType: selfType.importedType(in: module), irName: "self")).accessor
        }
        
        fnScope.insert(variable: selfVar, name: "self")
        
        // add self’s elements into the scope, whose accessors are elements of selfvar
        for member in selfType.members {
            let structElement = try module.builder.build(inst: StructElementPtrInst(object: selfVar.reference(),
                                                                                    property: member.name,
                                                                                    irName: member.name))
            fnScope.insert(variable: structElement.accessor, name: member.name)
        }
        
        // add the initialiser’s params
        for param in impl.params {
            try fnScope.insert(variable: function.param(named: param).accessor(), name: param)
        }
        
        // vir gen for body
        try impl.body.emitStmt(module: module, scope: fnScope)
        
        try fnScope.removeVariable(named: "self")?.releaseUnowned()
        try fnScope.releaseVariables(deleting: true)
        
        try module.builder.buildReturn(value: selfVar.aggregateGetValue())
        
        // move out of function
        module.builder.insertPoint = originalInsertPoint
    }
}


extension MutationExpr : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        let rval = try value.emitRValue(module: module, scope: scope).boxedAggregateGetValue(expectedType: object._type)
        guard case let lhs as LValueEmitter = object else { fatalError() }
        
        // TODO: test aggregate stuff
        
        // set the lhs to rval
        try lhs.emitLValue(module: module, scope: scope).setValue(rval)
        
        return try VoidLiteralValue().accessor()
    }
    
}

extension MethodCallExpr : ValueEmitter {
    
    func emitRValue(module: Module, scope: Scope) throws -> Accessor {
        
        // build self and args' values
        let args = try argOperands(module: module, scope: scope)
        let selfVar = try object.emitRValue(module: module, scope: scope)
        try selfVar.retain()
        let selfRef = try selfVar.referenceBacked().aggregateReference()
        
        guard let fnType = fnType else { fatalError() }
        
        // construct function call
        switch object._type {
        case is StructType:
            guard case .method = fnType.callingConvention else { fatalError() }
            
            let function = try module.getOrInsertFunction(named: mangledName, type: fnType)
            return try module.builder.buildFunctionCall(function: function, args: [PtrOperand(selfRef)] + args).accessor()
            
        case let existentialType as ConceptType:
            
            guard let argTypes = args.optionalMap(transform: {$0.type}) else { fatalError() }
            
            // get the witness from the existential
            let fn = try module.builder.build(inst: ExistentialWitnessInst(existential: selfRef,
                                                                           methodName: name,
                                                                           argTypes: argTypes,
                                                                           existentialType: existentialType,
                                                                           irName: "witness"))
            guard case let fnType as FunctionType = fn.memType?.importedType(in: module) else { fatalError() }
            
            // get the instance from the existential
            let unboxedSelf = try module.builder.build(inst: ExistentialProjectInst(existential: selfRef, irName: "unboxed"))
            // call the method by applying the opaque ptr to self as the first param
            return try module.builder.buildFunctionApply(function: PtrOperand(fn),
                                                         returnType: fnType.returns,
                                                         args: [PtrOperand(unboxedSelf)] + args).accessor()
        default:
            fatalError()
        }

        
    }
}






