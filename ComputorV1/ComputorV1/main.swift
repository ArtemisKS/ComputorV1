//
//  main.swift
//  ComputorV1
//
//  Created by Artem Kuprijanets on 11/25/19.
//  Copyright © 2019 Artem Kuprijanets. All rights reserved.
//

import Foundation

class ComputorV1 {
 
  private var argsArr: [String]!
  private var currentArgInd = 0
  private var currentArg = ""
  private let digitsStr = "0123456789"
  private let vars = "xX"
  private lazy var allowedChars = "+-=*^\(digitsStr)\(vars). "
  private var badChars = ""
  private var polynom: Polynom!
  private var discr: Double!
  
  enum Coefs: Int, CaseIterable {
    case a = 2, b = 1, c = 0
  }

  enum ValueType: CaseIterable {
    case digit
  }

  enum ProcessingError: Error {
    case emptyInput, noX, noEqualitySign, manyEqualitySigns,
    floatingPoint, badSymbols, wrongSyntax, noRoots, unknownError
  }

  enum OutputMode: CaseIterable {
    case normal, error, other
  }

  private var errorDict: [ProcessingError : String] {
    [.emptyInput : "Empty input? Really?",
    .noX : "Have you forgotten x?? For that matter, x is R, I guess",
    .noEqualitySign: "Have you forgotten equality sign(=)?? For that matter, x is R, I guess",
    .manyEqualitySigns: "Waat?) What's up with =)??",
    .floatingPoint : "Sorry! Dot can be only used for floating point numbers. Yeah, I know, it sucks(",
    .badSymbols : "Hey! '\(badChars)' can't really be used here",
    .wrongSyntax : "Hey! Wrong syntax ain't really tolerated, ya know",
    .noRoots: "No money no honey",
    .unknownError: "Come on!"]
  }

  func parseArgs() {
    
    let args = CommandLine.arguments
    if args.count < 2 {
      print("You son of a witch!")
      return
    } else {
      argsArr = Array(CommandLine.arguments.dropFirst())
    }
    
    for (ind, arg) in argsArr.enumerated() {
      do {
        currentArgInd = ind
        currentArg = arg
        try doLilValidation(arg)
        guard let pArg = parseArg(arg) else { continue }
        solveGeneralPolynom(pArg)
      } catch ProcessingError.badSymbols {
        printErrorAnswer(errorDict[.badSymbols]!)
      } catch ProcessingError.emptyInput {
        printErrorAnswer(errorDict[.emptyInput]!)
      } catch ProcessingError.floatingPoint {
        printErrorAnswer(errorDict[.floatingPoint]!)
      } catch ProcessingError.noRoots {
        printErrorAnswer(errorDict[.noRoots]!)
      } catch ProcessingError.noX {
        printErrorAnswer(errorDict[.noX]!)
      } catch ProcessingError.noEqualitySign {
        printErrorAnswer(errorDict[.noEqualitySign]!)
      } catch ProcessingError.manyEqualitySigns {
        printErrorAnswer(errorDict[.manyEqualitySigns]!)
      } catch ProcessingError.wrongSyntax {
        printErrorAnswer(errorDict[.wrongSyntax]!)
      } catch {
        printErrorAnswer(errorDict[.unknownError]!)
      }
    }
    
  }
  
  private func charIsSurrounded(
    _ str: String,
    by value: ValueType,
    for index: String.Index) -> Bool {
    
    guard let nc = str.nextChar(to: index), let pc = str.prevChar(to: index) else { return false }
    
    switch value {
    case .digit:
      return digitsStr.contains(nc) && digitsStr.contains(pc)
    }
    
  }

  private func checkForDouble(_ input: String) -> Bool {
    
    var str = input
    while let dotIndex = str.firstIndex (where: { $0 == "." }) {
  //    print("dotIndex: \(dotIndex.distance(in: str)), str: '\(str)'")
      if !charIsSurrounded(str, by: .digit, for: dotIndex) { return false }
      str.remove(at: dotIndex)
    }
    return true
  }

  private func doLilValidation(_ input: String) throws {
    
    if input.isEmpty { throw ProcessingError.emptyInput }
    
    if input.contains(".") && !checkForDouble(input) { throw ProcessingError.floatingPoint }
    
    badChars = input.filter { !allowedChars.contains($0) }
    if !badChars.isEmpty { throw ProcessingError.badSymbols }
    
    let notNumChars = input.filter { !" ".contains($0) }
  //  let numChars = input.filter { "\(digitsStr) ".contains($0) }
    
  //  print("notNumChars: \(notNumChars); numChars: \(numChars)")
    for (ind, ch) in notNumChars.enumerated() {
      
      guard ch != notNumChars.first && ch != notNumChars.last else { continue }
      
      let (prevCh, nextCh) = (notNumChars[ind - 1], notNumChars[ind + 1])
  //    print("prevCh: \(prevCh), nextCh: \(nextCh)")
      if ch == prevCh || ch == nextCh { throw ProcessingError.wrongSyntax }
    }
    
  //  let noX = !input.contains("x")
    let noEqualitySign = !input.contains("=")
    if noEqualitySign { throw ProcessingError.noEqualitySign }
    else if input.filter({ $0 == "=" }).count > 1 { throw ProcessingError.manyEqualitySigns }
  //  if noX && numChars.count == notNumChars.count + 1 { throw ProcessingError.noX }
  //  else if noX { throw ProcessingError.unknownError }
  }

  private func fillParser(
    _ polynomPart: String,
    isRightPart: Bool,
    parserArr: inout [Parser]) {
    
    guard polynomPart != "0" && polynomPart != "-0" else { return }
    
    let tokens = polynomPart.split
    { $0 == "+" || $0 == "-" }.map(String.init)
    var signTokens = polynomPart.split
    { $0 != "+" && $0 != "-" }.map(String.init)
    
  //  print("isRightPart: \(isRightPart)")
    if signTokens.count == tokens.count - 1 {
      signTokens.insert("+", at: 0)
    }
  //  print("tokens: \(tokens), \(tokens.count); signTokens: \(signTokens), \(signTokens.count)")
    for (ind, token) in tokens.enumerated() {
      var parser = Parser()
      var positive = signTokens[ind] == "+"
      if isRightPart { positive = !positive }
      parser.polynomPiece = token
      parser.positive = positive
      parserArr.append(parser)
    }
  }

  private func getCoef(from tokens: [String]) -> Double {
    let res = tokens.reduce(1) { (res, str) -> Double in
      return res * (Double(str) ?? 1)
    }
    return res
  }

  private func getPolynomValues(_ parseArr: [Parser]) -> [PolynomValue]? {
    
    var resPolynomValues = [PolynomValue?]()
    
    resPolynomValues = parseArr.map { parsedToken -> PolynomValue? in
      
      let piece = parsedToken.polynomPiece!
      var tokens = piece.split { !digitsStr.contains($0) && $0 != "." }.map(String.init)
      
  //    print("parsedToken: \(parsedToken)")
  //    print("tokens1: \(tokens)")
      if tokens.isEmpty {
        if vars.contains(parsedToken.polynomPiece) {
          return PolynomValue(coef: parsedToken.positive ? 1 : -1, power: 1)
        } else { printErrorAnswer("Come on!"); return nil }
      }
      
      
      
      var prePowSubToken: String!
      if let ind = piece.firstIndex(of: "^") { prePowSubToken = String(piece[piece.startIndex..<ind]) }
      else if let ind = piece.firstIndex(where: { self.vars.contains($0) }),
        ind != piece.index(before: piece.endIndex),
        digitsStr.contains(piece[piece.index(after: ind)]) { prePowSubToken = String(piece[piece.startIndex..<ind]) }
      
  //    print("piece: \(piece); prePowSubToken: \(prePowSubToken ?? "!!")")
      var pow: String
      if let prePowToken = prePowSubToken {
        let powInd = prePowToken.split { !digitsStr.contains($0) && $0 != "." }.map(String.init).count
  //      print("powInd: \(powInd), tokens: \(tokens), tokens[\(powInd)]: \(tokens[powInd])")
        pow = tokens.remove(at: powInd)
      } else {
        pow = piece.contains("x") || piece.contains("X") ? "1" : "0"
      }
      
      if let intPow = Int(pow), intPow > 2 { printErrorAnswer("Sorry, power can't be more than 2"); return nil }
      if tokens.isEmpty { tokens = ["1"] }
      
      if tokens.joined() == "0" && parsedToken.polynomPiece.contains("*0") { return PolynomValue() }
      
      let coef = getCoef(from: tokens)
      let coefVal = parsedToken.positive ? coef : -coef
      
  //    print("tokens: \(tokens), pow: \(pow), coef: \(coefInt)")
      return PolynomValue(coef: coefVal, power: Int(pow))
    }
    
  //  print("resPolynomValues: \(resPolynomValues)")
    let compactPolynomValues = resPolynomValues.compactMap { $0 }
    if compactPolynomValues.count != resPolynomValues.count { return nil }
    
    return compactPolynomValues
  }

  private func getPolValues(
    for power: Int,
    from polynomValues: [PolynomValue]) -> PolynomValue {
    
    return polynomValues.filter { $0.power == power }.reduce(PolynomValue(coef: 0, power: power)) { (res, polValue) -> PolynomValue in
      return PolynomValue(coef: res.coef + polValue.coef, power: res.power)
    }
  }

  private func reducePolynom(_ polynomValues: [PolynomValue]) -> [PolynomValue] {
    
    var polValsArrs = [PolynomValue]()
    for ind in 0...2 {
      polValsArrs.append(getPolValues(for: ind, from: polynomValues))
    }
    return polValsArrs
  }

  private func solveGeneralPolynom(_ polynom: Polynom) {
    if polynom.onlyNilValues { printErrorAnswer("Seems like x is R") }
    else if polynom.a == 0 && polynom.b == 0 { printExceptionalAnswer("No money no honey") }
    else if polynom.a == 0 { solveBasicPolynom(polynom) }
    else { solvePolynom(polynom) }
  }

  private func solveBasicPolynom(_ polynom: Polynom) {
    
    let res = Double(-polynom.c) / Double(polynom.b)
    printExceptionalAnswer("""
      As it's not the square root polynom, answer is simple: x = \(res.toString)
      """)
  }

  private func parseArg(_ arg: String) -> Polynom? {
    
    polynom = Polynom()
    var parserArr = [Parser]()
    let tokens = arg.split(separator: " ").map(String.init)
    let newStrArr = tokens.joined().split(separator: "=").map(String.init)
    for (ind, polynomPart) in newStrArr.enumerated() {
      fillParser(
        polynomPart,
        isRightPart: ind == newStrArr.count - 1 && ind != 0,
        parserArr: &parserArr)
    }
  //  print("parseArr: \(parserArr)")
    guard var polynomValues = getPolynomValues(parserArr) else { return nil }
  //  print("polynomValues1: \(polynomValues)")
    
    polynomValues = reducePolynom(polynomValues)
    
  //  print("polynomValuesReduced: \(polynomValues)")
    for polVal in polynomValues {
      
      let coef = polVal.coef
      switch polVal.power {
      case 2:
        polynom.a = coef
      case 1:
        polynom.b = coef
      default:
        polynom.c = coef
      }
    }
    
    return polynom
  }

  private func solveByViet(a: Double, b: Double, c: Double) {
    
    if b == 0 { solveGettingSquareRoot(a: a, c: -c); return }
    guard let (x1, x2) = solveByDiscr(a: a, b: b, c: c) else { return }
    
    printExceptionalAnswer(
      """
      Lookie what we've got here: a Viet-solvable lil polynom!\n
      So, x1 + x2 = \(-b) & x1 * x2 = \(c);
      Thus, \(x1 == x2 ?
      "x1 = x2 = \(x1.toString)"
      : "x1 = \(x1.toString); x2 = \(x2.toString)");
      """)
  }

  private func solveGettingSquareRoot(a: Double, c: Double) {
    
    if c < 0 { printExceptionalAnswer("No money no honey"); return }
    let (x1, x2) = (sqrt(Double(c)), -sqrt(Double(c)))
    
    printExceptionalAnswer(
    """
    Well, we only have to get the square root from \(a == 1 ? "" : a.toString)x^2 = \(c.toString),
    \tThus, \(x1 == x2 ? "x1 = x2 = \(x1.toString)" : "x1 = \(x1.toString); x2 = \(x2.toString)");
    """)
  }

  private func solveByDiscr(a: Double, b: Double, c: Double) -> (x1: Double, x2: Double)? {
    
    discr = pow(b, 2) - 4 * a * c
    
    if discr < 0 { printExceptionalAnswer("No money no honey"); return nil }
    let discrSqrt = sqrt(discr)
  //  print("a: \(a), b: \(b), c: \(c), discr: \(discr), discrSqrt: \(discrSqrt)")
    let x1 = (-b + discrSqrt) / (2 * a)
    let x2 = (-b - discrSqrt) / (2 * a)
  //  print("x1: \(x1), x2: \(x2)")
    return (x1, x2)
  }

  private func solvePolynom(_ polynom: Polynom) {
  //  print(polynom)
    let (a, b, c) = (polynom.a!, polynom.b!, polynom.c!)
    if a == 1 {
      solveByViet(a: a, b: b, c: c)
    } else {
      guard let (x1, x2) = solveByDiscr(a: a, b: b, c: c) else { return }
      printAnswer(x1 == x2 ?
        "One root found: \(x1.toString)"
        : "Two roots are: \(x1.toString) and \(x2.toString)")
    }
  }

  private func printDelimeter() {
    
    let len = 40
    for ind in 0...len { print("\(ind == len ? ">\n\n" : "=")", terminator: "") }
  }

  private func printExceptionalAnswer(_ answer: String) {
    
    printAnswer(answer, exception: .other)
  }

  private func printErrorAnswer(_ answer: String) {
    
    printAnswer(answer, exception: .error)
  }

  private func getSign(
    from val: Double,
    with space: Bool) -> String {
    
    return space ?
      (val > 0 ? " + " : " - ") : (val > 0 ? "" : "-")
  }

  private func getCoefSing(
    _ val: Double,
    coef: Coefs) -> String {
    
    switch coef {
    case .a:
      return getSign(from: val, with: false)
    case .b:
      return getSign(from: val, with: polynom.a != 0)
    default:
      return getSign(from: val, with: polynom.a != 0 || polynom.b != 0)
    }
  }

  private func getCoefOutput(
    value: Double,
    coef: Coefs) -> String {
    
    let val = abs(value)
    let sign = getCoefSing(value, coef: coef)
    switch coef {
    case .a:
      return val == 0 ? "" : "\(sign)\(val == 1 ? "" : val.toString)x^2"
    case .b:
      return val == 0 ? "" : "\(sign)\(val == 1 ? "" : val.toString)x"
    default:
      return val == 0 ? "" : "\(sign)\(val.toString)"
    }
  }

  private func getStandardPolView() -> String {
    
    let coefs: [Coefs : Double] = [.a : polynom.a, .b : polynom.b, .c : polynom.c]
    var res = ""
    
    let coefs1 = coefs.sorted { $0.0.rawValue > $1.0.rawValue }
    
    coefs1.forEach { coef, val in
      res.append(getCoefOutput(value: val, coef: coef))
    }
    
    res.append(" = 0")
    
    return res
  }

  private func printAnswer(_ answer: String, exception: OutputMode? = .normal) {
    
    let toPrintDelim = argsArr.count != 1
    let toPrintStandardView = exception == .normal || exception == .other
    let toPrintSolution = exception == .normal
    
    if toPrintDelim { printDelimeter() }
    
    print("""
      Polynom #\(currentArgInd + 1): '\(currentArg)'
      \(toPrintStandardView ? "Standard view: \(getStandardPolView())\n" : "")\
      \(!toPrintSolution ? "\n\t" : "Solution:\n\tDiscriminant = \(discr!.toString), =>\n\t")\(answer)
      """)
    
    if toPrintDelim && currentArgInd == argsArr.count - 1 { printDelimeter() }
    
  }

}

func main() {
  ComputorV1().parseArgs()
}

main()
