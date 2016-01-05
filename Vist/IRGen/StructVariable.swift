//
//  StructVariable.swift
//  Vist
//
//  Created by Josef Willsher on 25/12/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//


class StructVariable : MutableVariable {
    var type: LLVMTypeRef
    var ptr: LLVMValueRef
    let mutable: Bool
    
    var builder: LLVMBuilderRef
    var properties: [(String, LLVMTypeRef, Bool)]
    
    func indexOfProperty(name: String) -> Int? {
        return properties.indexOf { $0.0 == name }
    }
    
    
    init(type: LLVMTypeRef, ptr: LLVMValueRef, mutable: Bool, builder: LLVMBuilderRef, properties: [(String, LLVMTypeRef, Bool)]) {
        self.type = type
        self.mutable = mutable
        self.ptr = ptr
        self.builder = builder
        self.properties = properties
    }
    
    func load(name: String = "") -> LLVMValueRef {
        return LLVMBuildLoad(builder, ptr, name)
    }
    
    func isValid() -> Bool {
        return ptr != nil
    }
    
    /// returns pointer to allocated memory
    class func alloc(builder: LLVMBuilderRef, type: LLVMTypeRef, name: String = "", mutable: Bool, properties: [(String, LLVMTypeRef, Bool)]) -> StructVariable {
        let ptr = LLVMBuildAlloca(builder, type, name)
        return StructVariable(type: type, ptr: ptr, mutable: mutable, builder: builder, properties: properties)
    }
    
    func store(val: LLVMValueRef) {
        LLVMBuildStore(builder, val, ptr)
    }
    
    private func ptrToPropertyNamed(name: String) throws -> LLVMValueRef {
        guard let i = indexOfProperty(name) else { throw SemaError.NoPropertyNamed(name) }
        
        return LLVMBuildStructGEP(builder, ptr, UInt32(i), "\(name)_ptr")
    }
    
    func loadPropertyNamed(name: String) throws -> LLVMValueRef {
        return LLVMBuildLoad(builder, try ptrToPropertyNamed(name), "\(name)")
    }
    
    func store(val: LLVMValueRef, inPropertyNamed name: String) throws {
        LLVMBuildStore(builder, val, try ptrToPropertyNamed(name))
    }
    
    func propertyIsMutable(name: String) throws -> Bool {
        guard let i = indexOfProperty(name) else { throw SemaError.NoPropertyNamed(name) }
        return properties[i].2
    }
    
}

/// Variable kind referenced by initialisers
final class AssignablePropertyVariable : MutableVariable {
    var type: LLVMTypeRef = nil // dont care -- initialiser has this info
    var name: String
    let mutable = true // initialiser can always assign
    private unowned var str: StructVariable // unowned ref to struct this belongs to
    
    init(name: String, str: StructVariable) {
        self.name = name
        self.str = str
    }
    
    func store(val: LLVMValueRef) throws {
        try str.store(val, inPropertyNamed: name)
    }
    
    func load(name: String) throws -> LLVMValueRef {
        return try str.loadPropertyNamed(self.name)
    }
    
    func isValid() -> Bool {
        return true
    }
}



