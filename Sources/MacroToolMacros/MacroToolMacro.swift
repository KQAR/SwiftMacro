import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public enum MacroError: Error, CustomStringConvertible {

  case onlyFunction
  case onlyStringName

  var description: String {
    switch self {
    case .onlyFunction:
      return "@Logged can be attached only to functions."
    case .onlyStringName:
      return "@Logger can be named to String."
    }
  }
}

public struct LoggedMacro: BodyMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
    guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw MacroError.onlyFunction
    }
    guard let _ = node.arguments?.as(LabeledExprListSyntax.self) else {
      throw MacroError.onlyStringName
    }

    let signature = functionDecl.signature
    let parameters = signature.parameterClause.parameters
    let remainPara = FunctionParameterListSyntax(parameters.dropLast())
    // returns "arg1: String"
    let functionArgs = remainPara.map { parameter -> String in
      guard let paraType = parameter.type.as(IdentifierTypeSyntax.self)?.name else { return "" }
      return "\(parameter.firstName): \(paraType)"
    }.joined(separator: ", ")
    // returns "arg1: arg1"
    let calledArgs = remainPara.map { "\($0.firstName): \($0.firstName)" }.joined(separator: ", ")

    //
    if let completion = parameters.last,
       let completionType = completion.type.as(FunctionTypeSyntax.self)?.parameters.first {
      //
      return [
      """
      func \(functionDecl.name)(\(raw: functionArgs)) async -> \(completionType) {
         await withCheckedContinuation { continuation in
            self.\(functionDecl.name)(\(raw: calledArgs)) { object in
               continuation.resume(returning: object)
            }
         }
      }
      print("logger ==> \(functionDecl.name) + \(functionDecl.genericParameterClause)")
      \(functionDecl.body?.statements)
      """
      ]
    }
    return []
  }
}

public struct TakeTimeMacro: BodyMacro {
  public static func expansion(of node: AttributeSyntax, providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax, in context: some MacroExpansionContext) throws -> [CodeBlockItemSyntax] {
    guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
      throw MacroError.onlyFunction
    }
    guard let label = node.arguments?.as(LabeledExprListSyntax.self) else {
      throw MacroError.onlyStringName
    }
    var result: [CodeBlockItemSyntax] = ["let _takeTimeStart_ = mach_absolute_time()"]
    if let statements = functionDecl.body?.statements {
      result.append(contentsOf: statements)
    }
    let end: CodeBlockItemSyntax = """
    let _takeTimeEnd_ = mach_absolute_time()
    let _takeTimeElapsed_ = _takeTimeEnd_ - _takeTimeStart_
    var sTimebaseInfo = mach_timebase_info_data_t()
    if sTimebaseInfo.denom == 0 {
      mach_timebase_info(&sTimebaseInfo)
    }
    let PIDTimeInNanosecond = _takeTimeElapsed_ * UInt64(sTimebaseInfo.numer) / UInt64(sTimebaseInfo.denom)
    let _takeTimeInterval_ = Double(PIDTimeInNanosecond)/1_000_000_000
    print(\(label) + "\(functionDecl.name) takeTime(ms): ")
    print(_takeTimeInterval_)
    """
    result.append(end)
    return result
  }
}

@main
public struct MacroToolPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        LoggedMacro.self,
        TakeTimeMacro.self,
    ]
}
