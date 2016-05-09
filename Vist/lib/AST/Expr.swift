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
protocol Expr : ASTNode, _Typed, ExprTypeProvider, ValueEmitter {}
protocol TypedExpr : Expr, Typed {}

final class BlockExpr : TypedExpr, ScopeNode {
    var exprs: [ASTNode]
    var variables: [String]
    
    init(exprs: [ASTNode], variables: [String] = []) {
        self.exprs = exprs
        self.variables = variables
    }
    
    var type: FunctionType? = nil
    
    var childNodes: [ASTNode] {
        return exprs
    }
}

final class ClosureExpr : TypedExpr, ScopeNode {
    var exprs: [ASTNode]
    var parameters: [String]
    
    init(exprs: [ASTNode], params: [String]) {
        self.exprs = exprs
        self.parameters = params
    }
    
    var type: FunctionType? = nil
    
    var childNodes: [ASTNode] {
        return exprs
    }
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Literals
//-------------------------------------------------------------------------------------------------------------------------

final class FloatingPointLiteral: Typed, ChainableExpr {
    let val: Double
    var size: UInt32 = 64
    var explicitType: String {
        return size == 32 ? "Float": size == 64 ? "Double": "Float\(size)"
    }
    
    init(val: Double, size: UInt32 = 64) {
        self.val = val
    }
    
    var type: StructType? = nil
}

final class IntegerLiteral: Typed, ChainableExpr {
    let val: Int
    var size: UInt32
    var explicitType: String {
        return size == 32 ? "Int": "Int\(size)"
    }
    
    init(val: Int, size: UInt32 = 64) {
        self.val = val
        self.size = size
    }
    
    var type: StructType? = nil
}

final class BooleanLiteral: Typed, ChainableExpr {
    let val: Bool
    
    init(val: Bool) {
        self.val = val
    }
    
    var type: StructType? = nil
}

final class StringLiteral: TypedExpr {
    let str: String
    var count: Int { return str.characters.count }
    
    init(str: String) {
        self.str = str
    }
    
//    var arr: ArrayExpr? = nil
    
    var type: StructType? = nil
}
//final class CharacterExpr: Expr {
//    let val: Character
//    
//    init(c: Character) {
//        val =  c
//    }
//    
//    var type: Type? = nil
//}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Variables
//-------------------------------------------------------------------------------------------------------------------------


/// A variable lookup Expr
///
/// Generic over the variable type, use AnyExpr if this is not known
final class VariableExpr: ChainableExpr {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    var _type: Type? = nil
}

protocol ChainableExpr: Expr {
}
protocol LookupExpr: ChainableExpr {
    var object: ChainableExpr { get }
}


final class MutationExpr: Expr {
    let object: ChainableExpr
    let value: Expr
    
    init(object: ChainableExpr, value: Expr) {
        self.object = object
        self.value = value
    }
    
    var _type: Type? = nil
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Operators
//-------------------------------------------------------------------------------------------------------------------------

protocol FunctionCall: class, Expr, _Typed {
    var name: String { get }
    var argArr: [Expr] { get }
    var _type: Type? { get set }

    var mangledName: String { get set }
    var fnType: FunctionType? { get set }
}

final class BinaryExpr: FunctionCall {
    let op: String
    let lhs: Expr, rhs: Expr
    
    init(op: String, lhs: Expr, rhs: Expr) {
        self.op = op
        self.lhs = lhs
        self.rhs = rhs
    }
    
    var mangledName: String = ""
    
    var name: String { return op }
    var argArr: [Expr] { return [lhs, rhs] }
    
    var fnType: FunctionType? = nil
    var _type: Type? = nil
}

final class PrefixExpr: Expr {
    let op: String
    let expr: Expr
    
    init(op: String, expr: Expr) {
        self.op = op
        self.expr = expr
    }
    
    var _type: Type? = nil
}

final class PostfixExpr: Expr {
    let op: String
    let expr: Expr
    
    init(op: String, expr: Expr) {
        self.op = op
        self.expr = expr
    }
    
    var _type: Type? = nil
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Functions
//-------------------------------------------------------------------------------------------------------------------------

final class FunctionCallExpr: Expr, FunctionCall {
    let name: String
    let args: TupleExpr
    
    init(name: String, args: TupleExpr) {
        self.name = name
        self.args = args
        self.mangledName = name
    }
    
    var mangledName: String
    var argArr: [Expr] { return args.elements }
    
    var fnType: FunctionType? = nil
    var _type: Type? = nil
}


final class FunctionImplementationExpr: Expr {
    var params: [String]
    let body: BlockExpr
    
    init(params: [String], body: BlockExpr) {
        self.params = params
        self.body = body
    }
    
    var _type: Type? = nil
}

final class TupleMemberLookupExpr: LookupExpr {
    let index: Int
    let object: ChainableExpr
    
    init(index: Int, object: ChainableExpr) {
        self.index = index
        self.object = object
    }
    
    var _type: Type? = nil
}








//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Array
//-------------------------------------------------------------------------------------------------------------------------


final class ArrayExpr: ChainableExpr, Typed {
    
    let arr: [Expr]
    
    init(arr: [Expr]) {
        self.arr = arr
    }
    
    var elType: Type?
    var type: BuiltinType? = nil
}

final class ArraySubscriptExpr: ChainableExpr {
    let arr: Expr
    let index: Expr
    
    init(arr: Expr, index: Expr) {
        self.arr = arr
        self.index = index
    }
    
    var _type: Type? = nil
}




//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Struct
//-------------------------------------------------------------------------------------------------------------------------


protocol StructMemberExpr {
}
protocol TypeExpr: Expr {
    var name: String { get }
}



// TODO: These really shouldn't be Exprs

typealias ConstrainedType = (name: String, constraints: [String], parentName: String)

final class StructExpr: Typed, ScopeNode, TypeExpr, LibraryTopLevel {
    let name: String
    let properties: [VariableDecl]
    let methods: [FuncDecl]
    var initialisers: [InitialiserDecl]
    let attrs: [AttributeExpr]
    let byRef: Bool
    
    let genericParameters: [ConstrainedType]
    
    init(name: String,
         properties: [VariableDecl],
         methods: [FuncDecl],
         initialisers: [InitialiserDecl],
         attrs: [AttributeExpr],
         genericParameters: [ConstrainedType],
         byRef: Bool) {
        self.name = name
        self.properties = properties
        self.methods = methods
        self.initialisers = initialisers
        self.attrs = attrs
        self.genericParameters = genericParameters
        self.byRef = byRef
    }
    
    var type: StructType? = nil
    
    var childNodes: [ASTNode] {
        return properties.mapAs(ASTNode) + methods.mapAs(ASTNode) + initialisers.mapAs(ASTNode)
    }
}

final class ConceptExpr: TypedExpr, ScopeNode, TypeExpr, LibraryTopLevel {
    let name: String
    let requiredProperties: [VariableDecl]
    let requiredMethods: [FuncDecl]
    
    init(name: String, requiredProperties: [VariableDecl], requiredMethods: [FuncDecl]) {
        self.name = name
        self.requiredProperties = requiredProperties
        self.requiredMethods = requiredMethods
    }
    
    var type: ConceptType? = nil
    
    var childNodes: [ASTNode] {
        return requiredProperties.mapAs(ASTNode) + requiredMethods.mapAs(ASTNode)
    }
    
}



final class MethodCallExpr: ChainableExpr, FunctionCall {
    let name: String
    let object: ChainableExpr
    let args: TupleExpr
    
    init(name: String, args: TupleExpr, object: ChainableExpr) {
        self.name = name
        self.args = args
        self.object = object
    }
    
    var mangledName: String = ""
    
    var argArr: [Expr] { return args.elements }
    
    var structType: NominalType? = nil
    var fnType: FunctionType? = nil
    var _type: Type? = nil
}

final class PropertyLookupExpr: LookupExpr {
    let propertyName: String
    let object: ChainableExpr
    
    init(propertyName: String, object: ChainableExpr) {
        self.propertyName = propertyName
        self.object = object
    }
    
    var _type: Type? = nil
}





//-------------------------------------------------------------------------------------------------------------------------
//  MARK:                                               Other
//-------------------------------------------------------------------------------------------------------------------------


struct NullExpr: Expr {
    var _type: Type? = BuiltinType.null
}


final class TupleExpr: ChainableExpr {
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
    
    var _type: Type? = nil
}

struct CommentExpr: Expr {
    let str: String
    init(str: String) {
        self.str = str
    }
    
    var _type: Type? = nil
}

final class Void: TypedExpr {
    var type: BuiltinType? = .void
}

