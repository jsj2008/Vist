//
//  StdLibInline.swift
//  Vist
//
//  Created by Josef Willsher on 26/05/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

/**
 An optimisation pass to inline simple stdlib functions.
 
 Operators in vist are implemented in the stdlib, which stops the compiler inlining them.
 Here we manually convert a function call to a bunch of operators to their VIR. This lets 
 the LLVM constant folder statically fold expressions, as well as speeding up the resulting 
 code by reducing call/ret overhead
 
 The VIR:
 
 `%4 = call @-T-R_tII (%1: #Int, %3: #Int)`
 
 is expanded to:
 
 ```
 %4 = struct_extract %1: #Int, !value
 %5 = struct_extract %3: #Int, !value
 %i_xor = builtin i_xor %4: #Builtin.Int64, %5: #Builtin.Int64
 %6 = struct %I (%i_xor: #Builtin.Int64)
 ```
 */
struct StdLibInlinePass : OptimisationPass {
    
    // Aggressive opt should only be enabled in -Ohigh
    static var minOptLevel: OptLevel = .high
    
    // Run the opt -- called on each function by the pass manager
    func runOn(function: Function) throws {
        
        for case let call as FunctionCallInst in function.instructions {
            
            /// Explode the call to a simple arithmetic op
            /// - parameter returnType: Specify the return type, if none specified then the input type is used
            ///                         as the return type
            func replaceWithBuiltin(inst: BuiltinInst, elType: BuiltinType, returnType: StructType? = nil) throws {
                try call.replace { explosion in
                    let structType = try call.function.type.returns.getAsStructType()
                    let extracted = call.args.map { arg in
                        explosion.insert(StructExtractInst(object: arg, property: "value", propertyType: elType, structType: structType))
                    }
                    let virInst = explosion.insert(BuiltinInstCall(inst: inst, args: extracted, irName: inst.rawValue)!)
                    
                    explosion.insert(StructInitInst(type: returnType ?? structType, args: [virInst], irName: call.irName))
                }
            }
            
            /// Explode the call to an overflow checking op
            func replaceWithOverflowCheckedBuiltin(inst: BuiltinInst, elType: BuiltinType) throws {
                try call.replace { explosion in
                    let structType = try call.function.type.returns.getAsStructType()
                    let extracted = call.args.map { arg in
                        explosion.insert(StructExtractInst(object: arg, property: "value", propertyType: elType, structType: structType))
                    }
                    let virInst = explosion.insert(BuiltinInstCall(inst: inst, args: extracted, irName: inst.rawValue)!)
                    
                    let checkBit = explosion.insert(TupleExtractInst(tuple: virInst, index: 1, elementType: BuiltinType.bool, irName: "overflow"))
                    explosion.insert(BuiltinInstCall(inst: .condfail, args: [checkBit])!)
                    
                    let val = explosion.insert(TupleExtractInst(tuple: virInst, index: 0, elementType: elType, irName: "value"))
                    explosion.insert(StructInitInst(type: structType, args: [val], irName: call.irName))
                }
            }
            
            // Now we switch over the mangled function name, if its a stdlib
            // one we know how to explode, do it!
            
            switch call.function.name {
            case "-A_tII": // l * r
                try replaceWithOverflowCheckedBuiltin(.imul, elType: Builtin.intType)
            case "-P_tII": // l + r
                try replaceWithOverflowCheckedBuiltin(.iadd, elType: Builtin.intType)
            case "-M_tII": // l - r
                try replaceWithOverflowCheckedBuiltin(.isub, elType: Builtin.intType)
            case "-D_tII": // l / r
                try replaceWithBuiltin(.idiv, elType: Builtin.intType)
            case "-C_tII": // l % r
                try replaceWithBuiltin(.irem, elType: Builtin.intType)
            case "-T-R_tII": // l ~^ r
                try replaceWithBuiltin(.ixor, elType: Builtin.intType)
            case "-L-L_tII": // l << r
                try replaceWithBuiltin(.ishl, elType: Builtin.intType)
            case "-G-G_tII": // l >> r
                try replaceWithBuiltin(.ishr, elType: Builtin.intType)
            case "-T-N_tII": // l ~& r
                try replaceWithBuiltin(.iand, elType: Builtin.intType)
            case "-T-O_tII": // l ~| r
                try replaceWithBuiltin(.ior, elType: Builtin.intType)
            case "-T-R_tII": // l ~^ r
                try replaceWithBuiltin(.ixor, elType: Builtin.intType)
                
            case "-L_tII": // l < r
                try replaceWithBuiltin(.ilt, elType: Builtin.intType, returnType: StdLib.boolType)
            case "-G_tII": // l > r
                try replaceWithBuiltin(.igt, elType: Builtin.intType, returnType: StdLib.boolType)
            case "-L-E_tII": // l <= r
                try replaceWithBuiltin(.ilte, elType: Builtin.intType, returnType: StdLib.boolType)
            case "-G-E_tII": // l >= r
                try replaceWithBuiltin(.igte, elType: Builtin.intType, returnType: StdLib.boolType)
            case "-E-E_tII": // l == r
                try replaceWithBuiltin(.ieq, elType: Builtin.intType, returnType: StdLib.boolType)
            case "-B-E_tII": // l != r
                try replaceWithBuiltin(.ineq, elType: Builtin.intType, returnType: StdLib.boolType)
                
            case "-N-N_tBB": // l && r
                try replaceWithBuiltin(.and, elType: Builtin.boolType, returnType: StdLib.boolType)
            case "-O-O_tBB": // l || r
                try replaceWithBuiltin(.or, elType: Builtin.boolType, returnType: StdLib.boolType)
                
            default:
                break // not a stdlib function so we're done
            }
            
        }
    }
}


/*
 
 
 So the vist
 ```
 func add :: Int Int -> Int = (a b) do return a + b
 ```
 
 instead of becoming
 ```
 _add_tII:                               ## @add_tII
	.cfi_startproc
 ## BB#0:                                ## %entry
	pushq	%rbp
 Ltmp6:
	.cfi_def_cfa_offset 16
 Ltmp7:
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
 Ltmp8:
	.cfi_def_cfa_register %rbp
	callq	"_-P_tII"                   ## FUNCTION CALL TO _-P_tII
	popq	%rbp
	retq
	.cfi_endproc
 ```
 
 becomes
 
 ```
 _add_tII:                               ## @add_tII
 ## BB#0:                                ## %entry
	pushq	%rbp
	movq	%rsp, %rbp
	addq	%rsi, %rdi
	seto	%al
	movq	%rdi, -8(%rbp)          ## 8-byte Spill
	movb	%al, -9(%rbp)           ## 1-byte Spill
	jo	LBB2_2
 ## BB#1:                                ## %entry.cont
	movq	-8(%rbp), %rax          ## 8-byte Reload
	popq	%rbp
	retq
 LBB2_2:                                 ## %add.trap
	ud2
 ```
 */

