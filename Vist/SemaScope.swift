//
//  SemaScope.swift
//  Vist
//
//  Created by Josef Willsher on 27/12/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//

class SemaScope {
    
    var variables: [String: LLVMTyped]
    var functions: [String: LLVMFnType]
    var types: [String: LLVMStType]
    var returnType: LLVMTyped?
    let parent: SemaScope?
    
    /// Hint about what type the object should have
    ///
    /// Used for blocks’ types
    var objectType: LLVMTyped?
    
    subscript (variable variable: String) -> LLVMTyped? {
        get {
            if let v = variables[variable] { return v }
            return parent?[variable: variable]
        }
        set {
            variables[variable] = newValue
        }
    }
    subscript (function function: String) -> LLVMFnType? {
        get {
            if let v = functions[function] { return v }
            return parent?[function: function]
        }
        set {
            functions[function] = newValue
        }
    }
    subscript (type type: String) -> LLVMStType? {
        get {
            if let v = types[type] { return v }
            return parent?[type: type]
        }
        set {
            types[type] = newValue
        }
    }
    
    init(parent: SemaScope?, returnType: LLVMTyped? = LLVMType.Void) {
        self.parent = parent
        self.returnType = returnType
        self.variables = [:]
        self.functions = [:]
        self.types = [:]
    }
}
