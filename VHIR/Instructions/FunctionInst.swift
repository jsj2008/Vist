//
//  FunctionInst.swift
//  Vist
//
//  Created by Josef Willsher on 02/03/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//


final class FunctionCallInst: InstBase {
    var function: Function
    
    override var type: Ty? { return function.type.returns }
    
    private init(function: Function, args: [Operand], irName: String?) {
        self.function = function
        super.init(args: args, irName: irName)
    }
    
    override var instVHIR: String {
        return "\(name) = call @\(function.name) \(args.vhirValueTuple()) \(useComment)"
    }
    
    override var hasSideEffects: Bool { return true }
}


extension Builder {
    
    func buildFunctionCall(function: Function, args: [Operand], irName: String? = nil) throws -> FunctionCallInst {
        let s = FunctionCallInst(function: function, args: args, irName: irName)
        try addToCurrentBlock(s)
        return s
    }
}