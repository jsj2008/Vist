//
//  TypeProvider.swift
//  Vist
//
//  Created by Josef Willsher on 27/12/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//

protocol TypeProvider {
    /// Function used to traverse AST and get type information for all its objects
    ///
    /// Each implementation of this function should **call `.llvmType` on all of its sub expressions**
    ///
    /// The function implementation **should assign the result type to self** as well as returning it
    func llvmType(scope: SemaScope) throws -> LLVMType
}

extension TypeProvider {
    func llvmType(scope: SemaScope) throws -> LLVMType {
        return .Null
    }
}

func ==<T : LLVMTyped>(lhs: T, rhs: T) -> Bool {
    let l = (try? lhs.ir()), r = (try? rhs.ir())
    if let l = l, let r = r { return l == r } else { return false }
}


extension LLVMType : Equatable {}
extension LLVMFnType : Equatable {}







extension IntegerLiteral : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        let ty = LLVMType.Int(size: size)
        self.type = ty
        return ty
    }
}

extension FloatingPointLiteral : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        let ty = LLVMType.Float(size: size)
        self.type = ty
        return ty
    }
}

extension BooleanLiteral : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        self.type = LLVMType.Bool
        return LLVMType.Bool
    }
}

extension Variable : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // lookup variable type in scope
        guard let v = scope[variable: name] else { throw SemaError.NoVariable(name) }
        
        // assign type to self and return
        self.type = v
        return v
    }
}

extension BinaryExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // FIXME: this is kinda a hack: these should be stdlib implementations -- operators should be user definable and looked up from the vars scope like functions
        switch op {
        case "<", ">", "==", "!=", ">=", "<=":
            try lhs.llvmType(scope)
            try rhs.llvmType(scope)
            
            self.type = LLVMType.Bool
            return LLVMType.Bool
            
        default:
            let a = try lhs.llvmType(scope)
            let b = try rhs.llvmType(scope)
            
            // if same object
            if (try a.ir()) == (try b.ir()) {
                // assign type to self and return
                self.type = a
                return a
                
            } else { throw IRError.MisMatchedTypes }
        }
        
        
    }
}

extension Void : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        self.type = LLVMType.Void
        return .Void
    }
}






private extension FunctionType {
    
    func params() throws -> [LLVMType] {
        let res = args.mapAs(ValueType).flatMap { LLVMType($0.name) }
        if res.count == args.elements.count { return res } else { throw IRError.TypeNotFound }
    }
    
    func returnType() throws -> LLVMType {
        let res = returns.mapAs(ValueType).flatMap { LLVMType($0.name) }
        if res.count == returns.elements.count && res.count == 0 { return LLVMType.Void }
        if let f = res.first where res.count == returns.elements.count { return f } else { throw IRError.TypeNotFound }
    }
    
}

extension FunctionCallExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // get from table
        guard let fnType = scope[function: name] else { throw SemaError.NoFunction(name) }
        
        // gen types for objects in call
        for (i, arg) in args.elements.enumerate() {
            let ti = try arg.llvmType(scope)
            let expected = fnType.params[i]
            guard try ti == expected else { throw SemaError.WrongFunctionApplication(applied: ti, expected: expected, paramNum: i) }
        }
        
        // assign type to self and return
        self.type = fnType.returns
        return fnType.returns
    }
}

extension FunctionPrototypeExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        let ty = LLVMFnType(params: try fnType.params(), returns: try fnType.returnType())
        // update function table
        scope[function: name] = ty
        fnType.type = ty // store type in fntype
        type = LLVMType.Void     // retult of prototype is void
        
        guard var functionScopeExpression = impl?.body else { return .Void }
        // if body construct scope and parse inside it
        
        let fnScope = SemaScope(parent: scope, returnType: ty.returns)
        
        for (i, v) in (impl?.params.elements ?? []).enumerate() {
            
            let n = (v as? ValueType)?.name ?? "$\(i)"
            let t = try fnType.params()[i]
            
            fnScope[variable: n] = t
        }
        
        // type gen for inner scope
        try variableTypeSema(forScopeExpression: &functionScopeExpression, scope: fnScope)
        
        return .Void
    }
}

extension AssignmentExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        // handle redeclaration
        if let _ = scope[variable: name] { throw SemaError.InvalidRedeclaration(name, value) }
        
        // get val type
        let inferredType = try value.llvmType(scope)
        
        type = LLVMType.Void        // set type to self
        value.type = inferredType   // store type in value’s type
        scope[variable: name] = inferredType   // store in arr
        return .Void                // return void type for assignment expression
    }
}



extension ArrayExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // element types
        var types: [LLVMType] = []
        for i in 0..<arr.count {
            let el = arr[i]
            let t = try el.llvmType(scope)
            types.append(t)
        }
        
        // make sure array is homogeneous
        guard Set(try types.map { try $0.ir() }).count == 1 else { throw SemaError.HeterogenousArray(description) }
        
        // get element type and assign to self
        guard let elementType = types.first else { throw SemaError.EmptyArray }
        self.elType = elementType
        
        // assign array type to self and return
        let t = LLVMType.Array(el: elementType, size: UInt32(arr.count))
        self.type = t
        return t
    }
    
}

extension ArraySubscriptExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // get array variable
        guard let name = (arr as? Variable<AnyExpression>)?.name else { throw SemaError.NotVariableType }
        
        // make sure its an array
        guard case .Array(let type, _)? = scope[variable: name] else { throw SemaError.CannotSubscriptNonArrayVariable }
        
        // gen type for subscripting value
        guard case .Int = try index.llvmType(scope) else { throw SemaError.NonIntegerSubscript }
        
        // assign type to self and return
        self.type = type
        return type
    }
    
}

extension ReturnExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        let returnType = try expression.llvmType(scope)
        guard let ret = scope.returnType where ret == returnType else { throw SemaError.WrongFunctionReturnType(applied: returnType, expected: scope.returnType ?? .Void) }
        
        self.type = LLVMType.Null
        return .Null
    }
    
}

extension RangeIteratorExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // gen types for start and end
        let s = try start.llvmType(scope)
        let e = try end.llvmType(scope)
        
        // make sure range has same start and end types
        guard try e.ir() == s.ir() else { throw SemaError.RangeWithInconsistentTypes }
        
        self.type = LLVMType.Null
        return .Null
    }
    
}

extension ForInLoopExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // scopes for inner loop
        let loopScope = SemaScope(parent: scope, returnType: scope.returnType)
        
        // add bound name to scopes
        loopScope[variable: binded.name] = .Int(size: 64)
        
        // gen types for iterator
        try iterator.llvmType(scope)
        
        // parse inside of loop in loop scope
        try variableTypeSema(forScopeExpression: &block, scope: loopScope)
        
        return .Null
    }
    
}

extension WhileLoopExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // scopes for inner loop
        let loopScope = SemaScope(parent: scope, returnType: scope.returnType)
        
        // gen types for iterator
        let it = try iterator.llvmType(scope)
        guard try it.ir() == LLVMInt1Type() else { throw SemaError.NonBooleanCondition }
        
        // parse inside of loop in loop scope
        try variableTypeSema(forScopeExpression: &block, scope: loopScope)
        
        type = LLVMType.Null
        return .Null
    }
}
extension WhileIteratorExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // make condition variable and make sure bool
        let t = try condition.llvmType(scope)
        guard try t.ir() == LLVMInt1Type() else { throw SemaError.NonBooleanCondition }
        
        type = LLVMType.Bool
        return .Bool
    }
}


extension ConditionalExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // call on child `ElseIfBlockExpressions`
        for statement in statements {
            // inner scopes
            let ifScope = SemaScope(parent: scope, returnType: scope.returnType)
            
            try statement.llvmType(ifScope)
        }
        
        type = LLVMType.Null
        return .Null
    }
}

extension ElseIfBlockExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // get condition type
        let cond = try condition?.llvmType(scope)
        guard try cond?.ir() == LLVMInt1Type() || cond == nil else { throw SemaError.NonBooleanCondition }
        
        // gen types for cond block
        try variableTypeSema(forScopeExpression: &block, scope: scope)
        
        self.type = LLVMType.Null
        return .Null
    }
    
}

extension MutationExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        // gen types for variable and value
        let old = try object.llvmType(scope)
        let new = try value.llvmType(scope)
        guard try old.ir() == new.ir() else { throw SemaError.DifferentTypeForMutation }
        
        return .Null
    }
}

extension StructExpression : TypeProvider {
    
    func llvmType(scope: SemaScope) throws -> LLVMType {
        
        let structScope = SemaScope(parent: scope, returnType: nil) // cannot return from Struct scope
        
        // maps over properties and gens types
        let members = try properties.flatMap { (a: AssignmentExpression) -> LLVMType? in
            try a.llvmType(structScope)
            return a.value.type as? LLVMType
        }
        guard members.count == properties.count else { throw SemaError.StructPropertyNotTyped }
        
        let memberFunctions = try methods.flatMap { (f: FunctionPrototypeExpression) -> LLVMFnType? in
            try f.llvmType(structScope)
            return f.fnType.type as? LLVMFnType
        }
        guard memberFunctions.count == methods.count else { throw SemaError.StructMethodNotTyped }
        
        let ty = LLVMType.Struct(members: members, methods: memberFunctions)
        
        self.type = ty
        return ty
    }
}


