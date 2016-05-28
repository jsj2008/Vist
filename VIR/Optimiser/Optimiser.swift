//
//  Optimiser.swift
//  Vist
//
//  Created by Josef Willsher on 12/03/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

enum OptLevel: Int {
    case off = 0, low = 1, high = 3
}

extension CompileOptions {
    func optLevel() -> OptLevel {
        if contains(.Ohigh) { return .high }
        else if contains(.O) { return .low }
        else { return .off }
    }
}

extension Module {
    
    func runPasses(optLevel optLevel: OptLevel) throws {
        
        for function in functions {
            try StdLibInlinePass.create(function, optLevel: optLevel)
//            try ConstantFoldingPass.create(function, optLevel: optLevel)
            try DCEPass.create(function, optLevel: optLevel)
//            try CFGSimplificationPass.create(function, optLevel: optLevel)
        }
        
        try DeadFunctionPass.create(self, optLevel: optLevel)
        
    }
}


protocol OptimisationPass {
    /// What the pass is run on, normally function or module
    associatedtype Element
    /// The minimum opt level this pass will be run
    static var minOptLevel: OptLevel { get }
    init()
    /// Runs the pass
    func runOn(element: Element) throws
}

extension OptimisationPass {
    static func create(function: Element, optLevel: OptLevel) throws {
        guard optLevel.rawValue >= minOptLevel.rawValue else { return }
        return try Self().runOn(function)
    }
}

// utils

extension Function {
    var instructions: LazyCollection<[Inst]> { return blocks.map { $0.flatMap { $0.instructions }.lazy } ?? LazyCollection([]) }
}

struct Explosion<InstType : Inst> {
    let inst: InstType
    private(set) var explodedInstructions: [Inst] = []
    init(inst: InstType) { self.inst = inst }
    
//    @discardibleResult
    mutating func insert<I : Inst>(inst: I) -> I {
        explodedInstructions.append(inst)
        return inst
    }
    
    var tail: Inst { return explodedInstructions.last ?? inst }
    
    func replaceInst() throws {
        
        guard let block = inst.parentBlock else { fatalError("throw error -- no block") }
        
        var pos = inst as Inst
        // add the insts to this scope
        for i in explodedInstructions {
            try block.insert(i, after: pos)
            pos = i // insert next after this inst
        }
        
        inst.replaceAllUses(with: tail)
        try inst.eraseFromParent()
    }
}



