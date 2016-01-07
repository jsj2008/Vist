//
//  BuiltinFunction.swift
//  Vist
//
//  Created by Josef Willsher on 06/01/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

import Foundation


func builtinInstruction(named: String, builder: LLVMBuilderRef) -> ((LLVMValueRef, LLVMValueRef) throws -> LLVMValueRef)? {
    switch named {
        
    case "LLVM.i_add": return { LLVMBuildAdd(builder, $0, $1, "add_res") }
    case "LLVM.i_sub": return { LLVMBuildSub(builder, $0, $1, "sub_res") }
    case "LLVM.i_mul": return { LLVMBuildMul(builder, $0, $1, "mul_res") }
    case "LLVM.i_div": return { LLVMBuildUDiv(builder, $0, $1, "div_res") }
    case "LLVM.i_rem": return { LLVMBuildURem(builder, $0, $1, "rem_res") }

    case "LLVM.i_cmp_lt": return { return LLVMBuildICmp(builder, LLVMIntSLT, $0, $1, "cmp_lt_res") }
    case "LLVM.i_cmp_lte": return { return LLVMBuildICmp(builder, LLVMIntSLE, $0, $1, "cmp_lte_res") }
    case "LLVM.i_cmp_gt": return { return LLVMBuildICmp(builder, LLVMIntSGT, $0, $1, "cmp_gt_res") }
    case "LLVM.i_cmp_gte": return { return LLVMBuildICmp(builder, LLVMIntSGE, $0, $1, "cmp_gte_res") }
    case "LLVM.i_eq": return { return LLVMBuildICmp(builder, LLVMIntEQ, $0, $1, "cmp_eq_res") }
    case "LLVM.i_neq": return { return LLVMBuildICmp(builder, LLVMIntNE, $0, $1, "cmp_neq_res") }
        
        
    case "LLVM.b_and": return { return LLVMBuildAnd(builder, $0, $1, "cmp_and_res") }
    case "LLVM.b_or": return { return LLVMBuildOr(builder, $0, $1, "cmp_or_res") }
        
        
    case "LLVM.f_add": return { LLVMBuildFAdd(builder, $0, $1, "add_res") }
    case "LLVM.f_mul": return { LLVMBuildFMul(builder, $0, $1, "mul_res") }
        
    default: return nil
    }
}
//        if LLVMGetTypeKind(type) == LLVMIntegerTypeKind {
//
//        } else if isFloatType(LLVMGetTypeKind(type)) {
//
//            switch op {
//            case "-": return LLVMBuildFSub(builder, lIR, rIR, "fsub_res")
//            case "/": return LLVMBuildFDiv(builder, lIR, rIR, "fdiv_res")
//            case "%": return LLVMBuildFRem(builder, lIR, rIR, "frem_res")
//            case "<": return LLVMBuildFCmp(builder, LLVMRealOLT, lIR, rIR, "fcmp_lt_res")
//            case ">": return LLVMBuildFCmp(builder, LLVMRealOGT, lIR, rIR, "fcmp_gt_res")
//            case "<=": return LLVMBuildFCmp(builder, LLVMRealOLE, lIR, rIR, "cmp_lte_res")
//            case ">=": return LLVMBuildFCmp(builder, LLVMRealOGE, lIR, rIR, "cmp_gte_res")
//            case "==": return LLVMBuildFCmp(builder, LLVMRealOEQ, lIR, rIR, "cmp_eq_res")
//            case "!=": return LLVMBuildFCmp(builder, LLVMRealONE, lIR, rIR, "cmp_neq_res")
//            default: throw IRError.NoOperator
//            }
