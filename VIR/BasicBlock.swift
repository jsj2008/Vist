//
//  BasicBlock.swift
//  Vist
//
//  Created by Josef Willsher on 29/02/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

/**
 A collection of instructions
 
 Params are passed between blocks in parameters, blocks can
 reference insts in other blocks. The entry block of a function
 is called with params of the function
 */
final class BasicBlock : VIRElement {
    /// A name for the block
    var name: String
    /// The collection of instructions in this block
    private(set) var instructions: [Inst] = []
    
    weak var parentFunction: Function?
    var loweredBlock: LLVMBasicBlock? = nil
    
    /// The params passed into the block, a list of params
    var parameters: [Param]?

    /// The applications to this block. A list of predecessors
    /// and the arguments they applied
    private(set) var applications: [BlockApplication]
    
    /// A list of the predecessor blocks. These blocks broke to `self`
    var predecessors: [BasicBlock] { return applications.flatMap { application in application.predecessor } }
    
    init(name: String, parameters: [Param]?, parentFunction: Function) {
        self.name = name
        self.parameters = parameters
        self.parentFunction = parentFunction
        applications = []
    }
    
    /// The application of a block, how you jump into the block. `nil` preds
    /// and breakInst implies it it an entry block
    final class BlockApplication {
        var args: [Operand]?, predecessor: BasicBlock?, breakInst: BreakInstruction?
        
        init(params: [Operand]?, predecessor: BasicBlock?, breakInst: BreakInstruction?) {
            self.args = params
            self.predecessor = predecessor
            self.breakInst = breakInst
        }
        
    }
}


extension BasicBlock {
    
    
    func insert(inst: Inst, after: Inst) throws {
        instructions.insert(inst, atIndex: try indexOf(after).successor())
    }
    func append(inst: Inst) {
        instructions.append(inst)
    }
    
    /// Get param named `name` or throw
    func paramNamed(name: String) throws -> Param {
        guard let param = parameters?.find({ param in param.paramName == name }) else { throw VIRError.noParamNamed(name) }
        return param
    }
    /// Get an array of the arguments that were applied for `param`
    func appliedArgs(for param: Param) throws -> [BlockOperand] {
        
        guard let paramIndex = parameters?.indexOf({ blockParam in blockParam === param}),
            let args = applications.optionalMap({ application in application.args?[paramIndex] as? BlockOperand })
            else { throw VIRError.noParamNamed(param.name) }
        
        return args
    }
    
    /// Adds the entry application to a block -- used by Function builder
    func addEntryApplication(args: [Param]) throws {
        applications.insert(.entry(args), atIndex: 0)
    }
    
    /// Applies the parameters to this block, `from` sepecifies the
    /// predecessor to associate these `params` with
    func addApplication(from block: BasicBlock, args: [BlockOperand]?, breakInst: BreakInstruction) throws {
        
        // make sure application is correctly typed
        if let vals = try parameters?.map(InstBase.getType(_:)) {
            guard let equal = try args?.map(InstBase.getType(_:))
                .elementsEqual(vals, isEquivalent: ==)
                where equal else { throw VIRError.paramsNotTyped }
        }
        else { guard args == nil else { throw VIRError.paramsNotTyped }}
        
        applications.append(.body(block, params: args, breakInst: breakInst))
//        block.successors.append(self)
    }
    
    /// Helper, the index of `inst` in self or throw
    private func indexOf(inst: Inst) throws -> Int {
        guard let i = instructions.indexOf({ $0 === inst }) else { throw VIRError.instNotInBB }
        return i
    }
    
    // instructions
    func set(inst: Inst, newValue: Inst) throws {
        instructions[try indexOf(inst)] = newValue
    }
    
    /// Remove `inst` from self
    /// - precondition: `inst` is a member of `self`
    func remove(inst: Inst) throws {
        try instructions.removeAtIndex(indexOf(inst))
        inst.parentBlock = nil
    }
    
    /// Adds a param to the block
    /// - precondition: This block is an entry block
    func addEntryBlockParam(param: Param) throws {
        guard let entry = applications.first where entry.isEntry else { fatalError() }
        parameters?.append(param)
        entry.args?.append(Operand(param))
    }
    
    
    var module: Module { return parentFunction!.module }
    func dump() { print(vir) }
}


extension BasicBlock.BlockApplication {
    /// Get an entry instance
    static func entry(params: [Param]?) -> BasicBlock.BlockApplication {
        return BasicBlock.BlockApplication(params: params?.map(Operand.init), predecessor: nil, breakInst: nil)
    }
    /// Get a non entry instance
    static func body(predecessor: BasicBlock, params: [BlockOperand]?, breakInst: BreakInstruction) -> BasicBlock.BlockApplication {
        return BasicBlock.BlockApplication(params: params, predecessor: predecessor, breakInst: breakInst)
    }
    /// is self an entry application
    var isEntry: Bool { return predecessor == nil }
}

extension Builder {
    
    /// Appends this block to the function. Thus does not modify the insert
    /// point, make any breaks to this block, or apply any params to it
    func appendBasicBlock(name name: String, parameters: [Param]? = nil) throws -> BasicBlock {
        guard let function = insertPoint.function, let b = function.blocks where !b.isEmpty else { throw VIRError.noFunctionBody }
        
        let bb = BasicBlock(name: name, parameters: parameters, parentFunction: function)
        function.append(block: bb)
        for p in parameters ?? [] { p.parentBlock = bb }
        return bb
    }
}


extension Inst {
    
    /// The successor to `self`
    func successor() throws -> Inst? {
        return try parentBlock.map { parent in parent.instructions[try parent.indexOf(self).successor()] }
    }
    /// The predecessor of `self`
    func predecessor() throws -> Inst? {
        return try parentBlock.map { parent in parent.instructions[try parent.indexOf(self).predecessor()] }
    }
    
}
