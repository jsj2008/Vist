//
//  RefCountInst.swift
//  Vist
//
//  Created by Josef Willsher on 02/04/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

// MARK: Reference counting instructions

/**
 Allocate ref counted object on the heap. Lowered to a call
 of `vist_allocObject(size)`
 
 `%a = alloc_object %Foo.refcounted`
 */
final class AllocObjectInst : Inst, LValue {
    var storedType: StructType
    
    var uses: [Operand] = []
    var args: [Operand] = []
    
    init(memType: StructType, irName: String? = nil) {
        self.storedType = memType
        self.irName = irName
    }
    
    var refType: ModuleType { return storedType.refCountedBox(module: module) }
    var type: Type? { return memType.map { BuiltinType.pointer(to: $0) } }
    var memType: Type? { return refType }
    
    var vir: String {
        return "\(name) = alloc_object #\(storedType.prettyName)\(useComment)"
    }
    
    func copy() -> AllocObjectInst {
        return AllocObjectInst(memType: storedType, irName: irName)
    }
    
    weak var parentBlock: BasicBlock?
    var irName: String?
}

/**
 Retain a refcounted object - increments the ref count. Lowered to
 a call of `vist_retainObject()`
 
 `retain_object %0:%Foo.refcounted`
 */
final class RetainInst : Inst {
    var object: PtrOperand
    
    var uses: [Operand] = []
    var args: [Operand]
    
    convenience init(object: LValue, irName: String? = nil) {
        self.init(object: PtrOperand(object), irName: irName)
    }
    
    private init(object: PtrOperand, irName: String?) {
        self.object = object
        self.args = [object]
        initialiseArgs()
        self.irName = irName
    }
    
    var type: Type? { return object.memType.map { BuiltinType.pointer(to: $0) } }
    var memType: Type? { return object.memType }
    
    var hasSideEffects: Bool { return true }
    
    var vir: String {
        return "retain_object \(object.valueName)\(useComment) // id: \(name)"
    }
    
    func copy() -> RetainInst {
        return RetainInst(object: object.formCopy(), irName: irName)
    }
    func setArgs(_ args: [Operand]) {
        object = args[0] as! PtrOperand
    }
    
    weak var parentBlock: BasicBlock?
    var irName: String?
}

/**
 Release a refcounted object - decrements the ref count and it is dealloced
 if it falls to 0. Lowered to a call of `vist_releaseObject()`
 
 ```
 release_object %0:%Foo.refcounted
 ```
 */
final class ReleaseInst : Inst {
    var object: PtrOperand
    
    var uses: [Operand] = []
    var args: [Operand]
    
    convenience init(object: LValue, irName: String? = nil) {
        self.init(object: PtrOperand(object), irName: irName)
    }
    
    private init(object: PtrOperand, irName: String?) {
        self.object = object
        self.args = [object]
        initialiseArgs()
        self.irName = irName
    }
    
    var type: Type? { return object.memType.map { BuiltinType.pointer(to: $0) } }
    var memType: Type? { return object.memType }
    
    var hasSideEffects: Bool { return true }
    
    func copy() -> ReleaseInst {
        return ReleaseInst(object: object.formCopy(), irName: irName)
    }
    func setArgs(_ args: [Operand]) {
        object = args[0] as! PtrOperand
    }
    
    var vir: String {
        return "release_object \(object.valueName) // id: \(name)"
    }
    weak var parentBlock: BasicBlock?
    var irName: String?
}

/**
 Dealloc a refcounted object - if unowned only deallocs if the refcount 
 is 0. Lowered to a call of `vist_deallocObject()`
 
 ```
 dealloc_object %0:%Foo.refcounted
 ```
 */
final class DeallocObjectInst : Inst {
    var object: PtrOperand
    
    var uses: [Operand] = []
    var args: [Operand]

    convenience init(object: LValue, irName: String? = nil) {
        self.init(object: PtrOperand(object), irName: irName)
    }
    
    private init(object: PtrOperand, irName: String?) {
        self.object = object
        self.args = [object]
        initialiseArgs()
        self.irName = irName
    }
    
    var type: Type? { return object.memType.map { BuiltinType.pointer(to: $0) } }
    var memType: Type? { return object.memType }
    
    func copy() -> DeallocObjectInst {
        return DeallocObjectInst(object: object.formCopy(), irName: irName)
    }
    func setArgs(_ args: [Operand]) {
        object = args[0] as! PtrOperand
    }
    var hasSideEffects: Bool { return true }
    
    var vir: String {
        return "dealloc_object \(object.valueName) // id: \(name)"
    }
    weak var parentBlock: BasicBlock?
    var irName: String?
}


