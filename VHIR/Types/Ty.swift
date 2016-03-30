//
//  Ty.swift
//  Vist
//
//  Created by Josef Willsher on 27/12/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//

protocol Ty : Printable, VHIRElement {
    
    /// Name used in mangling function signatures
    var mangledName: String { get }
    
    func lowerType(module: Module) -> LLVMTypeRef
    /// Replaces the function's memeber types with the module's typealias
    func usingTypesIn(module: Module) -> Ty
    
    /// The explicit name of this type. The same as the
    /// mangled name, unless the mangled name uses a different
    /// naming system, like the builtin types
    var explicitName: String { get }
}

extension Ty {
    // implement default behaviour
    var explicitName: String {
        return mangledName
    }
}


// MARK: Cannonical equality functions, compares their module-agnostic type info

@warn_unused_result
func == (lhs: Ty?, rhs: Ty) -> Bool {
    if let l = lhs { return l == rhs } else { return false }
}
@warn_unused_result
func == (lhs: Ty?, rhs: Ty?) -> Bool {
    if let l = lhs, let r = rhs { return l == r } else { return false }
}
@warn_unused_result
func != (lhs: Ty?, rhs: Ty) -> Bool {
    if let l = lhs { return l != rhs } else { return false }
}

@warn_unused_result
func == (lhs: Ty, rhs: Ty) -> Bool {
    switch (lhs, rhs) {
    case (let l as StorageType, let r as ConceptType):
        return l.models(r)
    case (let l as ConceptType, let r as StorageType):
        return r.models(l)
    case (let l as StorageType, let r as GenericType):
        return l.validSubstitutionFor(r)
    case (let l as GenericType, let r as StorageType):
        return r.validSubstitutionFor(l)
        
    case let (l as FnType, r as FnType):
        return r == l
    case (let lhs as StorageType, let rhs as StorageType):
        return lhs.name == rhs.name && lhs.members.elementsEqual(rhs.members, isEquivalent: ==) && lhs.methods.elementsEqual(rhs.methods, isEquivalent: ==)
    case let (l as BuiltinType, r as BuiltinType):
        return l == r
    case let (l as TupleType, r as TupleType):
        return l == r
    case let (l as TypeAlias, r as TypeAlias):
        return l == r
    default:
        return false
    }
}

@warn_unused_result
func != (lhs: Ty, rhs: Ty) -> Bool {
    return !(lhs == rhs)
}
