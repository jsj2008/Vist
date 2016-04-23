//
//  BuiltinInst.swift
//  Vist
//
//  Created by Josef Willsher on 02/03/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//


/**
 A call to a builtin VIR function
 
 `%a = builtin i_add %1:%Builtin.Int %2:$Builtin.Int`
 */
final class BuiltinInstCall : InstBase {
    override var type: Type? { return returnType }
    let inst: BuiltinInst
    var instName: String { return inst.rawValue }
    var returnType: Type
    
    private init?(inst: BuiltinInst, args: [Operand], irName: String?) {
        self.inst = inst
        guard let argTypes = try? args.map(InstBase.getType(_:)), let retTy = inst.returnType(params: argTypes) else { return nil }
        self.returnType = retTy
        super.init(args: args, irName: irName)
    }
    
    static func trapInst() -> BuiltinInstCall { return BuiltinInstCall(inst: .trap, args: [], irName: nil)! }
    
    // utils for bin instructions
    lazy var lhs: LLVMValue! = { return self.args[0].loweredValue }()
    lazy var rhs: LLVMValue! = { return self.args[1].loweredValue }()
    
    override var instVIR: String {
        let a = args.map{$0.valueName}
        let w = a.joinWithSeparator(", ")
        switch inst {
        case .condfail:
            return "cond_fail \(w)"
        default:
            return "\(name) = builtin \(instName) \(w) \(useComment)"
        }
    }
    
    override var hasSideEffects: Bool {
        switch inst {
        case .condfail, .memcpy, .trap: return true
        default: return false
        }
    }
    override var isTerminator: Bool {
        switch inst {
        case .trap: return true
        default: return false
        }
    }
}

/// A builtin VIR function. Each can be called in Vist code (stdlib only)
/// by doing Builtin.intrinsic
enum BuiltinInst : String {
    case iadd = "i_add", isub = "i_sub", imul = "i_mul", idiv = "i_div", irem = "i_rem", ieq = "i_eq", ineq = "i_neq"
    case iaddoverflow = "i_add_overflow"
    case condfail = "cond_fail"
    case ilte = "i_cmp_lte", igte = "i_cmp_gte", ilt = "i_cmp_lt", igt = "i_cmp_gt"
    case ishl = "i_shl", ishr = "i_shr", iand = "i_and", ior = "i_or", ixor = "i_xor"
    case and = "b_and", or = "b_or"
    
    case expect, trap
    case allocstack = "stack_alloc", allocheap = "heap_alloc", memcpy = "mem_copy"
    case advancepointer = "advance_pointer", opaqueload = "opaque_load"
    
    case fadd = "f_add", fsub = "f_sub", fmul = "f_mul", fdiv = "f_div", frem = "f_rem", feq = "f_eq", fneq = "f_neq"
    case flte = "f_cmp_lte", fgte = "f_cmp_gte", flt = "f_cmp_lt", fgt = "f_cmp_gt"
    
    var expectedNumOperands: Int {
        switch  self {
        case .memcpy: return 3
        case .iadd, .isub, .imul, .idiv, .iaddoverflow, .irem, .ilte, .igte, .ilt, .igt,
             .expect, .ieq, .ineq, .ishr, .ishl, .iand, .ior, .ixor, .fgt, .and, .or,
             .fgte, .flt, .flte, .fadd, .fsub, .fmul, .fdiv, .frem, .feq, .fneq, .advancepointer: return 2
        case .condfail, .allocstack, .allocheap, .opaqueload: return 1
        case .trap: return 0
        }
    }
    func returnType(params params: [Type]) -> Type? {
        switch self {
        case .iadd, .isub, .imul:
            return TupleType(members: [params.first!, Builtin.boolType]) // overflowing arithmetic
            
        case .idiv, .iaddoverflow, .irem, .ishl, .ishr, .iand, .ior,
             .ixor, .fadd, .fsub, .fmul, .fdiv, .frem, .feq, .fneq:
            return params.first // normal arithmetic
            
        case .ilte, .igte, .ilt, .igt, .flte, .fgte, .flt,
             .fgt, .expect, .ieq, .ineq, .and, .or:
            return Builtin.boolType // bool ops
           
        case .allocstack, .allocheap, .advancepointer:
            return Builtin.opaquePointerType
            
        case .opaqueload:
            return BuiltinType.int(size: 8)
            
        case .condfail, .trap, .memcpy:
            return Builtin.voidType // void return
        }
    }
}


extension Builder {
    
    // change name back when not crashing
    func buildBuiltinInstructionCall(i: BuiltinInst, args: Operand..., irName: String? = nil) throws -> BuiltinInstCall {
        return try buildBuiltinInstruction(i, args: args, irName: irName)
    }
    
    func buildBuiltinInstruction(i: BuiltinInst, args: [Operand], irName: String? = nil) throws -> BuiltinInstCall {
        guard args.count == i.expectedNumOperands, let binInst = BuiltinInstCall(inst: i, args: args, irName: irName) else { throw VIRError.builtinIncorrectOperands(inst: i, recieved: args.count) }
        return try _add(binInst)
    }
}