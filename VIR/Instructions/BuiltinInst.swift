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
final class BuiltinInstCall : Inst {
    var type: Type? { return returnType }
    let inst: BuiltinInst
    var instName: String { return inst.rawValue }
    var returnType: Type
    
    var uses: [Operand] = []
    var args: [Operand]
    
    weak var parentBlock: BasicBlock?
    var irName: String?
    
    convenience init(inst: BuiltinInst, args: [Value], irName: String? = nil) throws {
        try self.init(inst: inst, operands: args.map(Operand.init), irName: irName)
    }
    convenience init(inst: BuiltinInst, operands: [Operand], irName: String? = nil) throws {
        
        guard operands.count == inst.expectedNumOperands else {
            throw VIRError.builtinIncorrectOperands(inst: inst, recieved: operands.count)
        }
        guard let retTy = try inst.returnType(params: operands.map(getType(of:))) else {
            throw VIRError.noType(#file)
        }
        
        self.init(inst: inst, retType: retTy, operands: operands, irName: irName)
    }
    
    private init(inst: BuiltinInst, retType: Type, operands: [Operand], irName: String?) {
        self.inst = inst
        self.returnType = retType
        self.args = operands
        initialiseArgs()
        self.irName = irName
    }
    
    static func trapInst() -> BuiltinInstCall { return try! BuiltinInstCall(inst: .trap, args: [], irName: nil) }
    
    // utils for bin instructions
    lazy var lhs: LLVMValue! = { return self.args[0].loweredValue }()
    lazy var rhs: LLVMValue! = { return self.args[1].loweredValue }()
    
    var vir: String {
        let a = args.map{$0.valueName}
        let w = a.joined(separator: ", ")
        switch inst {
        case .condfail:
            return "cond_fail \(w) // id: \(name)"
        default:
            return "\(name) = builtin \(instName) \(w)\(useComment)"
        }
    }
    
    var hasSideEffects: Bool {
        switch inst {
        case .condfail, .memcpy, .trap, .opaquestore, .heapfree: return true
        default: return false
        }
    }
    var isTerminator: Bool {
        switch inst {
        case .trap: return true
        default: return false
        }
    }
    
    func copy() -> BuiltinInstCall {
        return BuiltinInstCall(inst: inst, retType: returnType, operands: args.map { $0.formCopy() }, irName: irName)
    }
}


/// A builtin VIR function. Each can be called in Vist code (stdlib only)
/// by doing Builtin.intrinsic
enum BuiltinInst : String {
    case iadd = "i_add", isub = "i_sub", imul = "i_mul", idiv = "i_div", irem = "i_rem", ieq = "i_eq", ineq = "i_neq", beq = "b_eq", bneq = "b_neq"
    case iaddunchecked = "i_add_unchecked" , imulunchecked = "i_mul_unchecked", ipow = "i_pow"
    case condfail = "cond_fail"
    case ilte = "i_cmp_lte", igte = "i_cmp_gte", ilt = "i_cmp_lt", igt = "i_cmp_gt"
    case ishl = "i_shl", ishr = "i_shr", iand = "i_and", ior = "i_or", ixor = "i_xor"
    case and = "b_and", or = "b_or", not = "b_not"
    
    case expect, trap
    case allocstack = "stack_alloc", allocheap = "heap_alloc", heapfree = "heap_free", memcpy = "mem_copy", opaquestore = "opaque_store"
    case advancepointer = "advance_pointer", opaqueload = "opaque_load"
    
    case fadd = "f_add", fsub = "f_sub", fmul = "f_mul", fdiv = "f_div", frem = "f_rem", feq = "f_eq", fneq = "f_neq"
    case flte = "f_cmp_lte", fgte = "f_cmp_gte", flt = "f_cmp_lt", fgt = "f_cmp_gt"
    
    case trunc8 = "trunc_int_8", trunc16 = "trunc_int_16", trunc32 = "trunc_int_32"
    case sext64 = "sext_int_64", zext64 = "zext_int_64"
    
    case withptr = "with_ptr", isuniquelyreferenced = "is_uniquely_referenced"
    
    var expectedNumOperands: Int {
        switch  self {
        case .memcpy: return 3
        case .iadd, .isub, .imul, .idiv, .iaddunchecked, .imulunchecked, .irem, .ilte, .igte, .ilt, .igt,
             .expect, .ieq, .ineq, .ishr, .ishl, .iand, .ior, .ixor, .fgt, .and, .or,
             .fgte, .flt, .flte, .fadd, .fsub, .fmul, .fdiv, .frem, .feq, .fneq, .beq, .bneq,
             .opaquestore, .advancepointer, .ipow:
            return 2
        case .condfail, .allocstack, .allocheap, .heapfree, .isuniquelyreferenced,
             .opaqueload, .trunc8, .trunc16, .trunc32, .withptr, .not, .sext64, .zext64:
            return 1
        case .trap:
            return 0
        }
    }
    func returnType(params: [Type]) -> Type? {
        switch self {
        case .iadd, .isub, .imul:
            return TupleType(members: [params.first!, Builtin.boolType]) // overflowing arithmetic
            
        case .idiv, .iaddunchecked, .imulunchecked, .irem, .ishl, .ishr,
             .iand, .ior, .ixor, .fadd, .fsub, .fmul, .fdiv, .frem, .ipow:
            return params.first // normal arithmetic
            
        case .ilte, .igte, .ilt, .igt, .flte, .fgte, .flt, .fgt, .isuniquelyreferenced,
             .expect, .ieq, .ineq, .and, .or, .not, .beq, .bneq, .feq, .fneq:
            return Builtin.boolType // bool ops
           
        case .allocstack, .allocheap, .advancepointer, .withptr:
            return Builtin.opaquePointerType
            
        case .opaqueload, .trunc8:
            return BuiltinType.int(size: 8)
        case .trunc16:
            return BuiltinType.int(size: 16)
        case .trunc32:
            return BuiltinType.int(size: 32)
        case .sext64, .zext64:
            return BuiltinType.int(size: 64)
            
        case .condfail, .trap, .memcpy, .heapfree, .opaquestore:
            return Builtin.voidType // void return
        }
    }
}

