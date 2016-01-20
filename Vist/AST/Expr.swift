//
//  Expr.swift
//  Vist
//
//  Created by Josef Willsher on 17/08/2015.
//  Copyright © 2015 vistlang. All rights reserved.
//


///  - Expression / Expr
///      - literals, tuples, parens, array, closure
///      - Call expression, operator, methods, casts
///      - Sub expressions of syntax structures, like `type name generic params`
protocol Expr : ASTNode, Typed {}



















// TODO: Notes from swift:
//
// they have different types -
//
//  - Pattern, as in pattern matching
//      - `is` pattern, tuple pattern, enum element pattern, case statement 'bool' patterns, x?
//  - Declarations / Decl
//      - Vars, funcs, types, and initalisers
//  - Statement / Stmt
//      - brace, return, defer, conditional, do/catch, if, while, for, for each, switch, break, fallthrough, continue, throw
//  - Expression / expr
//      - literals, tuples, parens, array, closure
//      - Call expression, operator, methods, casts,
//      - Sub expressions of syntax structures, like `type name generic params`
//  - TypeRepr & SourceLoc
//      - ‘Representation of a type as written in source’, generates human readable code to attach to AST objects
//      - Source code location information
//
// Swift has an explicit AST walker function











final class BlockExpr : Expr {
    var exprs: [ASTNode]
    var variables: [ValueType]
    
    init(exprs: [ASTNode], variables: [ValueType] = []) {
        self.exprs = exprs
        self.variables = variables
    }
    
    var type: Ty? = nil
}

final class ClosureExpr : Expr {
    
    var exprs: [ASTNode]
    var parameters: [String]
    
    init(exprs: [ASTNode], params: [String]) {
        self.exprs = exprs
        self.parameters = params
    }
    
    var type: Ty? = nil
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Literals
//-------------------------------------------------------------------------------------------------------------------------

protocol SizedExpr : Expr {
    var size: UInt32 { get set }
}

protocol ExplicitlyTyped {
    var explicitType: String { get }
}

final class FloatingPointLiteral : SizedExpr, ExplicitlyTyped {
    let val: Double
    var size: UInt32 = 64
    var explicitType: String {
        return size == 32 ? "Float" : size == 64 ? "Double" : "Float\(size)"
    }
    
    init(val: Double, size: UInt32 = 64) {
        self.val = val
    }
    
    var type: Ty? = nil
}

final class IntegerLiteral : SizedExpr, ExplicitlyTyped {
    let val: Int
    var size: UInt32
    var explicitType: String {
        return size == 32 ? "Int" : "Int\(size)"
    }
    
    init(val: Int, size: UInt32 = 64) {
        self.val = val
        self.size = size
    }
    
    var type: Ty? = nil
}

final class BooleanLiteral : Expr {
    let val: Bool
    
    init(val: Bool) {
        self.val = val
    }
    
    var type: Ty? = nil
}

final class StringLiteral : Expr {
    let str: String
    var count: Int { return str.characters.count }
    
    init(str: String) {
        self.str = str
    }
    
//    var arr: ArrayExpr? = nil
    
    var type: Ty? = nil
}
//final class CharacterExpr : Expr {
//    let val: Character
//    
//    init(c: Character) {
//        val =  c
//    }
//    
//    var type: Ty? = nil
//}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Variables
//-------------------------------------------------------------------------------------------------------------------------


/// A variable lookup Expr
///
/// Generic over the variable type, use AnyExpr if this is not known
final class Variable : AssignableExpr {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    var type: Ty? = nil
}

protocol AssignableExpr : Expr {}

final class MutationExpr : Expr {
    let object: AssignableExpr
    let value: Expr
    
    init(object: AssignableExpr, value: Expr) {
        self.object = object
        self.value = value
    }
    
    var type: Ty? = nil
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Operators
//-------------------------------------------------------------------------------------------------------------------------

final class BinaryExpr : Expr {
    let op: String
    let lhs: Expr, rhs: Expr
    
    init(op: String, lhs: Expr, rhs: Expr) {
        self.op = op
        self.lhs = lhs
        self.rhs = rhs
    }
    
    var mangledName: String = ""
    
    var type: Ty? = nil
}

final class PrefixExpr : Expr {
    let op: String
    let expr: Expr
    
    init(op: String, expr: Expr) {
        self.op = op
        self.expr = expr
    }
    
    var type: Ty? = nil
}

final class PostfixExpr : Expr {
    let op: String
    let expr: Expr
    
    init(op: String, expr: Expr) {
        self.op = op
        self.expr = expr
    }
    
    var type: Ty? = nil
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Functions
//-------------------------------------------------------------------------------------------------------------------------

final class FunctionCallExpr : Expr {
    let name: String
    let args: TupleExpr
    
    init(name: String, args: TupleExpr) {
        self.name = name
        self.args = args
        self.mangledName = name
    }
    
    var mangledName: String
    
    var type: Ty? = nil
}


final class FunctionImplementationExpr : Expr {
    let params: TupleExpr
    let body: BlockExpr
    
    init(params: TupleExpr, body: BlockExpr) {
        self.params = params
        self.body = body
    }
    
    var type: Ty? = nil
}

final class TupleMemberLookupExpr : AssignableExpr {
    let index: Int
    let object: Expr
    
    init(index: Int, object: Expr) {
        self.index = index
        self.object = object
    }
    
    var type: Ty? = nil
}

final class ReturnStmt : Stmt {
    let expr: Expr
    
    init(expr: Expr) {
        self.expr = expr
    }
}




final class FunctionType : Expr {
    let args: TupleExpr
    let returns: Expr
    
    init(args: TupleExpr, returns: Expr) {
        self.args = args
        self.returns = returns
    }
    
    var type: Ty? = nil
}



//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Array
//-------------------------------------------------------------------------------------------------------------------------


final class ArrayExpr : AssignableExpr {
    
    let arr: [Expr]
    
    init(arr: [Expr]) {
        self.arr = arr
    }
    
    var elType: Ty?
    var type: Ty? = nil
}

final class ArraySubscriptExpr : AssignableExpr {
    let arr: Expr
    let index: Expr
    
    init(arr: Expr, index: Expr) {
        self.arr = arr
        self.index = index
    }
    
    var type: Ty? = nil
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Struct
//-------------------------------------------------------------------------------------------------------------------------


protocol StructMember {
}


final class StructExpr : Expr {
    let name: String
    let properties: [VariableDecl]
    let methods: [FuncDecl]
    var initialisers: [InitialiserDecl]
    let attrs: [AttributeExpr]
    
    init(name: String, properties: [VariableDecl], methods: [FuncDecl], initialisers: [InitialiserDecl], attrs: [AttributeExpr]) {
        self.name = name
        self.properties = properties
        self.methods = methods
        self.initialisers = initialisers
        self.attrs = attrs
    }
    
    var type: Ty? = nil
}



final class MethodCallExpr <ObjectType : Expr> : Expr {
    let name: String
    let object: ObjectType
    let params: TupleExpr
    
    init(name: String, params: TupleExpr, object: ObjectType) {
        self.name = name
        self.params = params
        self.object = object
    }
    
    var mangledName: String = ""
    
    var type: Ty? = nil
}

final class PropertyLookupExpr : AssignableExpr {
    let name: String
    let object: Expr
    
    init(name: String, object: Expr) {
        self.name = name
        self.object = object
    }
    
    var type: Ty? = nil
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Other
//-------------------------------------------------------------------------------------------------------------------------


struct NullExpr : Expr {
    var type: Ty? = nil
}


// FIXME: find another way to do this
/// used to lowe type name information
final class ValueType : Expr {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    var type: Ty? = nil
}


final class TupleExpr : Expr {
    let elements: [Expr]
    
    init(elements: [Expr]) {
        self.elements = elements
    }
    init(element: Expr) {
        self.elements = [element]
    }
    
    static func void() -> TupleExpr{ return TupleExpr(elements: [])}
    
    func mapAs<T>(_: T.Type) -> [T] {
        return elements.flatMap { $0 as? T }
    }
    
    var type: Ty? = nil
}

struct CommentExpr : Expr {
    let str: String
    init(str: String) {
        self.str = str
    }
    
    var type: Ty? = nil
}

final class Void : Expr {
    var type: Ty? = BuiltinType.Void
}


