//
//  VHIR.swift
//  Vist
//
//  Created by Josef Willsher on 29/02/2016.
//  Copyright © 2016 vistlang. All rights reserved.
//

//: [Previous](@previous)

protocol VHIR {
    /// VHIR code to print
    var vhir: String { get }
}

enum VHIRError: ErrorType {
    case noFunctionBody, instNotInBB, cannotMoveBuilderHere, noParentBlock, noParamNamed(String), noUse
}

// $instruction
// %identifier
// @function
// #basicblock

// MARK: VHIR gen, this is where I start making code to print

private extension CollectionType where Generator.Element == Ty {
    func typeTupleVHIR() -> String {
        let a = map { "\($0.vhir)" }
        return "(\(a.joinWithSeparator(", ")))"
    }
}


extension Value {
    var valueName: String {
        return "%\(name)\(type.map { ": \($0.vhir)" } ?? "")"
    }
}
extension Inst {
    var vhir: String {
        let a = args.map{$0.valueName}
        let w = a.joinWithSeparator(", ")
        return "%\(name) = $\(instName) \(w)"
    }
}
extension BasicBlock {
    var vhir: String {
        let p = parameters?.map { $0.vhir }
        let pString = p.map { "(\($0.joinWithSeparator(", ")))"} ?? ""
        let i = instructions.map { $0.vhir }
        let iString = "\n\t\(i.joinWithSeparator("\n\t"))\n"
        return "#\(name)\(pString):\(iString)"
    }
}
extension Function {
    var vhir: String {
        let b = blocks?.map { $0.vhir }
        let bString = b.map { " {\n\($0.joinWithSeparator("\n"))}" } ?? ""
        return "func @\(name) : \(type.vhir)\(bString)"
    }
}
extension FnType {
    var vhir: String {
        return "\(params.typeTupleVHIR()) -> \(returns.vhir)"
    }
}
extension BuiltinType {
    var vhir: String {
        return "%\(explicitName)"
    }
}
extension StorageType {
    var vhir: String {
        return "%\(irName)"
    }
}
extension TupleType {
    var vhir: String {
        return members.typeTupleVHIR()
    }
}
extension Module {
    var vhir: String {
        let t = typeList.map { $0.vhir }
        let f = functions.map { $0.vhir }
        return (t+f).joinWithSeparator("\n\n")
    }
}






//: [Next](@next)