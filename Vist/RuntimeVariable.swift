//
//  RuntimeVariable.swift
//  Vist
//
//  Created by Josef Willsher on 18/12/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//

import Foundation


protocol RuntimeVariable {
    var type: LLVMTypeRef { get }
    
    func load(builder: LLVMBuilderRef, name: String) -> LLVMValueRef
    func isValid() -> Bool
}

protocol MutableVariable {
    func store(builder: LLVMBuilderRef, val: LLVMValueRef)
    var mutable: Bool { get }
}

/// A variable type passed by reference
/// Instances are called in IR using `load` and `store`
/// mem2reg optimisation pass moves these down to SSA register vars
class ReferenceVariable : RuntimeVariable, MutableVariable {
    var type: LLVMTypeRef
    var ptr: LLVMValueRef
    let mutable: Bool
    
    init(type: LLVMTypeRef, ptr: LLVMValueRef, mutable: Bool) {
        self.type = type
        self.mutable = mutable
        self.ptr = ptr
    }
    
    func load(builder: LLVMBuilderRef, name: String = "") -> LLVMValueRef {
        return LLVMBuildLoad(builder, ptr, name)
    }
    
    func isValid() -> Bool {
        return ptr != nil
    }
    
    /// returns pointer to allocated memory
    class func alloc(builder: LLVMBuilderRef, type: LLVMTypeRef, name: String = "", mutable: Bool) -> ReferenceVariable {
        let ptr = LLVMBuildAlloca(builder, type, name)
        return ReferenceVariable(type: type, ptr: ptr, mutable: mutable)
    }
    
    func store(builder: LLVMBuilderRef, val: LLVMValueRef) {
        LLVMBuildStore(builder, val, ptr)
    }
    
    
}


/// A variable type passed by value
/// Instances use SSA
class StackVariable : RuntimeVariable {
    var type: LLVMTypeRef
    var val: LLVMValueRef
    
    init(val: LLVMValueRef) {
        self.type = LLVMTypeOf(val)
        self.val = val
    }
    
    func load(builder: LLVMBuilderRef, name: String = "") -> LLVMValueRef {
        return val
    }
    
    func isValid() -> Bool {
        return val != nil
    }
}

class ArrayVariable : RuntimeVariable {
    var elementType: LLVMTypeRef    // ty Type
    var ptr: LLVMValueRef   // ty*
    var arr: LLVMValueRef   // [sz x ty]*
    var base: LLVMValueRef  // ty*
    var count: Int
    var mutable: Bool
    
    var type: LLVMTypeRef {
        return LLVMArrayType(elementType, UInt32(count))
    }
    
    func load(builder: LLVMBuilderRef, name: String = "") -> LLVMValueRef {
        return base
    }
    
    func isValid() -> Bool {
        return ptr != nil
    }
    
    func assignFrom(builder: LLVMBuilderRef, arr: ArrayVariable) {
        
        assert(elementType == arr.elementType)
        
        LLVMBuildStore(builder, arr.base, ptr)
        count = arr.count
        base = arr.base
    }
    
    init(name: String = "arrhead", ptr: LLVMValueRef, elType: LLVMTypeRef, builder: LLVMBuilderRef, vars: [LLVMValueRef]) {
        
        let pt = LLVMPointerType(elType, 0)
        // case array as ptr to get base pointer
        let base = LLVMBuildBitCast(builder, ptr, pt, "base")
        
        for n in 0..<vars.count {
            // llvm num type as the index
            let index = [LLVMConstInt(LLVMInt64Type(), UInt64(n), LLVMBool(false))].ptr()
            // Get pointer to element n
            let el = LLVMBuildGEP(builder, base, index, 1, "el\(n)")
            
            // load val into memory
            LLVMBuildStore(builder, vars[n], el)
        }
        
        self.elementType = elType
        self.base = base
        self.arr = ptr
        self.count = vars.count
        self.mutable = false
        self.ptr = nil
    }
    
    func allocHead(builder: LLVMBuilderRef, name: String, mutable: Bool) {
        let pt = LLVMPointerType(elementType, 0)
        self.ptr = LLVMBuildAlloca(builder, pt, name)
        LLVMBuildStore(builder, base, self.ptr)
    }
    
        
}


