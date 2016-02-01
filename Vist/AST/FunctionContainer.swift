//
//  FunctionContainer.swift
//  Vist
//
//  Created by Josef Willsher on 27/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

/// Holds functions, mangles them on initialisation and subscript
///
/// Used to tell the compiler about functions
///
struct FunctionContainer {
    
    private let functions: [String: FnType]
    private let types: [StructType]
    
    /// Initialiser takes a collection of tuples.
    ///
    /// Tuples are of the unmangled name and the type object
    ///
    /// Optionally takes an array of metadata to apply to all functions
    ///
    init (functions: [(String, FnType)], types: [StructType], metadata: [String] = []) {
        var t: [String: FnType] = [:]
        
        for (n, _ty) in functions {
            var ty = _ty
            let mangled = n.mangle(ty.params)
            ty.metadata += metadata
            t[mangled] = ty
        }
        
        self.functions = t
        self.types = types
    }
    
    /// Get a named function
    ///
    /// - parameter id: Unmangled name
    ///
    /// - parameter types: Applied arg types
    ///
    /// - returns: An optional tuple of `(mangled-name, type)`
    ///
    subscript(fn fn: String, types types: [Ty]) -> (String, FnType)? {
        get {
            let mangled = fn.mangle(types)
            guard let ty = functions[mangled] else { return nil }
            return (mangled, ty)
        }
    }
    
    /// Returns type from type name
    subscript(type type: String) -> StructType? {
        get {
            if let i = types.indexOf({ $0.name == type }) { return types[i] } else { return nil }
        }
    }
}

