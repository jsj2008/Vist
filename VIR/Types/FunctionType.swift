//
//  FunctionType.swift
//  Vist
//
//  Created by Josef Willsher on 17/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

struct FunctionType : Type {
    var params: [Type], returns: Type
    var callingConvention: CallingConvention
    
    init(params: [Type], returns: Type = BuiltinType.void, callingConvention: CallingConvention? = nil, yieldType: Type? = nil) {
        self.params = params
        self.returns = returns
        self.callingConvention = callingConvention ?? .thin
        self.yieldType = yieldType
    }
    
    enum CallingConvention {
        case thin, initialiser, deinitialiser, runtime
        case method(selfType: Type, mutating: Bool)
        
        var name: String {
            switch self {
            case .thin: return "&thin"
            case .initialiser: return "&init"
            case .deinitialiser: return "&deinit"
            case .runtime: return "&runtime"
            case .method: return "&method"
            }
        }
    }
    
    // Generator functions yield this type
    // use this field to store the return type as the producced signature is complicated
    var yieldType: Type?
    var isCanonicalType: Bool = false
}

extension FunctionType {
    // get the generator type of the function
    mutating func setGeneratorVariantType(yielding yieldType: Type) {
        guard case .method(let s, let m) = callingConvention else { return }
        self = FunctionType(params: [BuiltinType.pointer(to:
                FunctionType(params: [yieldType],
                            returns: BuiltinType.void,
                            callingConvention: .thin,
                            yieldType: nil))],
                        returns: BuiltinType.void,
                        callingConvention: .method(selfType: s, mutating: m),
                        yieldType: yieldType)
    }
    var isGeneratorFunction: Bool { return yieldType != nil }
    var isAddressOnly: Bool { return true }
    
    func lowered(module: Module) -> LLVMType {
        
        var ret = returns.lowered(module: module)
        if returns.isAddressOnly {
            ret = ret.getPointerType()
        }
        
        let params: [LLVMType] = nonVoidParams.map {
            let ret = $0.lowered(module: module)
            if $0.isAddressOnly {
                return ret.getPointerType()
            }
            return ret
        }
        
        return LLVMType.functionType(params: params, returns: ret)
    }
    
    /// Replaces the function's memeber types with the module's typealias
    func importedType(in module: Module) -> Type {
        let params = self.params.map { $0.importedType(in: module) }
        let returns = self.returns.importedType(in: module)
        return FunctionType(params: params, returns: returns, callingConvention: callingConvention, yieldType: yieldType)
    }
    
    
    /**
     The type used by the IR -- it lowers the calling convention
     
     The function arguments are lowered as follows:
     - Thick functions add their implicit context reference to the beginning
     of the paramether list
     - Methods add their implicit self parameter to the beginning of the param
     list. It is a pointer if the method is mutating or if self is a reference
     type. Otherwise self is passed by value
     */
    func cannonicalType(module: Module) -> FunctionType {
        if isCanonicalType { return self }
        
        var t = persistentFunctionType(module: module)
        
        if case .method(let selfType, _) = callingConvention {
            t.params.insert(BuiltinType.pointer(to: selfType), at: 0)
        }
        t.isCanonicalType = true
        return t
    }
    
    /// the ptr type this fn is stored as
    func persistentType(module: Module) -> Type {
        return persistentFunctionType(module: module).ptrType()
    }
    
    func persistentFunctionType(module: Module) -> FunctionType {
        let ret = returns.importedType(in: module).persistentType(module: module)
        
        let pars = params.map { param in param.importedType(in: module).persistentType(module: module) }
        return FunctionType(params: pars, returns: ret, callingConvention: callingConvention, yieldType: yieldType)
    }
    
    func cannonicalisedParamTypes() -> [Type] {
        return params.map { $0.isAddressOnly ? $0.ptrType() : $0 }
    }
    
    static func taking(params: Type..., ret: Type = BuiltinType.void) -> FunctionType {
        return FunctionType(params: params, returns: ret)
    }
    static func returning(ret: Type) -> FunctionType {
        return FunctionType(params: [], returns: ret)
    }
    
    private var nonVoidParams: [Type]  {
        return params.filter { if case BuiltinType.void = $0 { return false } else { return true } }
    }
    
    var mangledName: String {
        let conventionPrefix: String
        switch callingConvention {
        case .method(let selfType, _): // method
            conventionPrefix = "m" + selfType.mangledName
        case .thin: // thin
            conventionPrefix = "t"
        case .initialiser: // init
            conventionPrefix = "i"
        case .deinitialiser: // deinit
            conventionPrefix = "d"
        case .runtime: // deallocator/copy constructor
            conventionPrefix = "r"
        }
        return conventionPrefix + params
            .map { $0.mangledName }
            .joined(separator: "")
    }
    
    var prettyName: String {
        return TupleType(members: nonVoidParams).prettyName + " -> " + returns.prettyName
    }
    
    /// Returns a version of this type, but with a defined parent
    func asMethod(withSelf parent: NominalType, mutating: Bool) -> FunctionType {
        return FunctionType(params: params, returns: returns, callingConvention: .method(selfType: parent, mutating: mutating), yieldType: yieldType)
    }
    /// Returns a version of this type, but with a parent of type i8 (so ptrs to it are i8*)
    func asMethodWithOpaqueParent() -> FunctionType {
        return FunctionType(params: params, returns: returns, callingConvention: .method(selfType: BuiltinType.int(size: 8), mutating: false), yieldType: yieldType)
    }
    
    func isInModule() -> Bool {
        return !params.contains { !$0.isInModule() } && returns.isInModule()
    }
    
    func machineType() -> AIRType {
        return .function(params: params.map { $0.machineType() }, returns: returns.machineType())
    }
}

extension FunctionType : Equatable {
    static func == (lhs: FunctionType, rhs: FunctionType) -> Bool {
        return lhs.params.elementsEqual(rhs.params, by: ==) && lhs.returns == rhs.returns
    }
}


