//
//  FunctionAttribute.swift
//  Vist
//
//  Created by Josef Willsher on 06/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

protocol AttributeExpr { }

enum ASTAttributeExpr: AttributeExpr {
    case Operator(prec: Int)
}

enum FunctionAttributeExpr: String, AttributeExpr {
    case Inline = "inline"
    case NoReturn = "noreturn"
    case NoInline = "noinline"
    case Mutating = "mutating"
    case Private = "private", Public = "public"
    
    func addAttrTo(function: LLVMValueRef) {
        switch self {
        case .Inline: LLVMAddFunctionAttr(function, LLVMAlwaysInlineAttribute)
        case .NoReturn: LLVMAddFunctionAttr(function, LLVMNoReturnAttribute)
        case .NoInline: LLVMAddFunctionAttr(function, LLVMNoInlineAttribute)
        case .Private: LLVMSetLinkage(function, LLVMPrivateLinkage)
        case .Public: LLVMSetLinkage(function, LLVMExternalLinkage)
        default: break
        }
    }
}

