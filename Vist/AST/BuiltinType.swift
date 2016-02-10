//
//  BuiltinType.swift
//  Vist
//
//  Created by Josef Willsher on 17/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//



enum BuiltinType : Ty {
    case Null, Void
    case Int(size: UInt32), Float(size: UInt32), Bool
    indirect case Array(el: Ty, size: UInt32?)
    indirect case Pointer(to: Ty)
    case OpaquePointer
    
    func ir() -> LLVMTypeRef {
        switch self {
        case .Null:                     return nil
        case .Void:                     return LLVMVoidType()
        case .Int(let s):               return LLVMIntType(s)
        case Bool:                      return LLVMInt1Type()
        case .Array(let el, let size):  return LLVMArrayType(el.ir(), size ?? 0)
        case .Pointer(let to):          return LLVMPointerType(to.ir(), 0)
        case .OpaquePointer:            return BuiltinType.Pointer(to: BuiltinType.Int(size: 8)).ir()
        case .Float(let s):
            switch s {
            case 16:                    return LLVMHalfType()
            case 32:                    return LLVMFloatType()
            case 64:                    return LLVMDoubleType()
            case 128:                   return LLVMFP128Type()
            default:                    fatalError(SemaError.InvalidFloatType(s).description)
            }
        }
    }
    
    func globalType(module: LLVMModuleRef) -> LLVMTypeRef {
        return ir()
    }
    
    init?(_ str: String) {
        switch str {
        case "LLVM.Int", "LLVM.Int64":  self = .Int(size: 64)
        case "LLVM.Int32":              self = .Int(size: 32)
        case "LLVM.Int16":              self = .Int(size: 16)
        case "LLVM.Int8":               self = .Int(size: 8)
        case "LLVM.Bool":               self = .Bool
        case "LLVM.Double":             self = .Float(size: 64)
        case "LLVM.Float":              self = .Float(size: 32)
        case "Void":                    self = .Void
        case "LLVM.String":             self = .Array(el: BuiltinType.Int(size: 8), size: nil)
        case _ where str.characters.first == "[" && str.characters.last == "]":
            guard let el = BuiltinType(String(str.characters.dropFirst().dropLast())) else { return nil }
            self = .Array(el: el, size: nil)
            // hack: array type IR has no size which is wrong
        default: return nil
        }
    }
    
}
