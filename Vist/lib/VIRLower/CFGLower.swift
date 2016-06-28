//
//  CFGLower.swift
//  Vist
//
//  Created by Josef Willsher on 22/04/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

extension ReturnInst : VIRLower {
    func virLower(IGF: inout IRGenFunction) throws -> LLVMValue {
        
        if case _ as VoidLiteralValue = returnValue.value {
            return try IGF.builder.buildRetVoid()
        }
        else {
            let v = try returnValue.virLower(IGF: &IGF)
            return try IGF.builder.buildRet(val: v)
        }
    }
}

extension BreakInst : VIRLower {
    func virLower(IGF: inout IRGenFunction) throws -> LLVMValue {
        return try IGF.builder.buildBr(to: call.block.loweredBlock!)
    }
}

extension CondBreakInst : VIRLower {
    func virLower(IGF: inout IRGenFunction) throws -> LLVMValue {
        return try IGF.builder.buildCondBr(if: condition.loweredValue!,
                                           to: thenCall.block.loweredBlock!,
                                           elseTo: elseCall.block.loweredBlock!)
    }
}

extension VIRFunctionCall {
    func virLower(IGF: inout IRGenFunction) throws -> LLVMValue {
        let call = try IGF.builder.buildCall(function: functionRef,
                                             args: args.map { $0.loweredValue! },
                                             name: irName)
        return call
    }
    
}
