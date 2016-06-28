//
//  LiteralInst.swift
//  Vist
//
//  Created by Josef Willsher on 02/03/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

import class Foundation.NSString

/**
 An int literal
 
 `%a = int_literal 1`
 */
final class IntLiteralInst : InstBase {
    var value: LiteralValue<Int>, size: Int
    
    override var type: Type? { return BuiltinType.int(size: size) }
    
    init(val: Int, size: Int, irName: String? = nil) {
        self.value = LiteralValue(val: val, irName: nil)
        self.size = size
        super.init(args: [], irName: irName)
    }
    
    override var instVIR: String {
        return "\(name) = int_literal \(value.value)\(useComment)"
    }
    
    override func copyInst() -> IntLiteralInst {
        return IntLiteralInst(val: value.value, size: size, irName: irName)
    }
}
/**
 An boolean literal
 
 `%a = bool_literal false`
 */
final class BoolLiteralInst : InstBase {
    var value: LiteralValue<Bool>
    
    override var type: Type? { return value.type }
    
    init(val: Bool, irName: String? = nil) {
        self.value = LiteralValue(val: val, irName: nil)
        super.init(args: [], irName: irName)
    }
    
    override var instVIR: String {
        return "\(name) = bool_literal \(value.value)\(useComment)"
    }
    
    override func copyInst() -> BoolLiteralInst {
        return BoolLiteralInst(val: value.value, irName: irName)
    }
}


/**
 A string literal, specifying an encoding
 
 `%a = string_literal utf16 "hello 😎"`
 */
final class StringLiteralInst : InstBase {
    var value: LiteralValue<String>
    
    var isUTF8Encoded: Bool { return value.value.smallestEncoding == .utf8 || value.value.smallestEncoding == .ascii }
    override var type: Type? { return value.type }
    
    init(val: String, irName: String? = nil) {
        self.value = LiteralValue(val: val, irName: nil)
        super.init(args: [], irName: irName)
    }
    
    override var instVIR: String {
        return "\(name) = string_literal \(isUTF8Encoded ? "utf8" : "utf16") \"\(value.value)\" \(useComment)"
    }
    
    override func copyInst() -> StringLiteralInst {
        return StringLiteralInst(val: value.value, irName: irName)
    }
}

/// A literal's contained object
final class LiteralValue<Literal> : Value {
    var value: Literal
    
    var irName: String?
    var type: Type? {
        switch value {
        case is Int: return BuiltinType.int(size: 64)
        case is Bool: return BuiltinType.bool
        case is String: return BuiltinType.opaquePointer
        case is (): return BuiltinType.void
        default: fatalError("Invalid literal")
        }
    }
    weak var parentBlock: BasicBlock?
    var uses: [Operand] = []
    
    private init(val: Literal, irName: String?) {
        self.value = val
        self.irName = irName
    }
}

/// A void literal: `()`
final class VoidLiteralValue : Value {
    var type: Type? { return BuiltinType.void }
    weak var parentBlock: BasicBlock?
    var uses: [Operand] = []
    var irName: String? = nil
    
    var name: String {
        get { return "()" }
        set { }
    }
}


