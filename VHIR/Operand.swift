//
//  Operand.swift
//  Vist
//
//  Created by Josef Willsher on 29/02/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//


class Operand: RValue {
    /// The underlying value
    var value: RValue?
    
    init(_ value: RValue) {
        self.value = value
        value.addUse(self)
    }
    
    deinit {
        try! value?.removeUse(self)
    }
    
    private(set) var loweredValue: LLVMValueRef = nil
    
    // forward all interface to `value`
    var type: Ty? { return value?.type }
    var irName: String? {
        get { return value?.irName }
        set { value?.irName = newValue }
    }
    var parentBlock: BasicBlock! {
        get { return value?.parentBlock }
        set { value?.parentBlock = newValue }
    }
    var uses: [Operand] {
        get { return value?.uses ?? [] }
        set { value?.uses = newValue }
    }
    var name: String {
        get { return value!.name }
        set { value?.name = newValue }
    }
    var operandName: String { return "<operand of \(name) by \(user?.name)>" }
    
    var user: Inst? {
        return parentBlock?.userOf(self)
    }
        
    func setLoweredValue(val: LLVMValueRef) { loweredValue = val }
    
    func dumpIR() { if loweredValue != nil { LLVMDumpValue(loweredValue) } else { print("\(irName) <NULL>") } }
}


/// An operand applied to a block, loweredValue is lazily evaluated
/// so phi nodes can be created when theyre needed, allowing their values
/// to be calculated
final class BlockOperand: Operand {
    
    init(value: RValue, param: BBParam) {
        self.param = param
        self.predBlock = value.parentBlock
        super.init(value)
    }
    
    private let param: BBParam
    private unowned let predBlock: BasicBlock
    
    /// Sets the phi's value for the incoming block `self.predBlock`
    override func setLoweredValue(val: LLVMValueRef) {
        guard val != nil else {
            loweredValue = nil
            return
        }
        let incoming = [val].ptr(), incomingBlocks = [predBlock.loweredBlock].ptr()
        defer { incoming.destroy(); incomingBlocks.destroy() }
        LLVMAddIncoming(param.phi, incoming, incomingBlocks, 1)
    }
    
    var phi: LLVMValueRef {
        get { return loweredValue }
        set(phi) { loweredValue = phi }
    }
}

