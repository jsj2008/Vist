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
        
    case "LLVM.i_add":
        return {
            LLVMBuildAdd(builder, $0, $1, "add_res")
        }
        
        
        
    default:
        return nil
    }
}