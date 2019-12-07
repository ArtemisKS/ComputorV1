//
//  Polynom.swift
//  ComputorV1
//
//  Created by Artem Kuprijanets on 11/25/19.
//  Copyright © 2019 Artem Kuprijanets. All rights reserved.
//

import Foundation

struct Polynom {
  
  var a: Double!
  var b: Double!
  var c: Double!
  
  init() {}
  
  var onlyNilValues: Bool {
    return a == 0 && b == 0 && c == 0
  }
  
  var description: String {
    return "a: \(a ?? -1); b: \(b ?? -1); c: \(c ?? -1)"
  }
}

struct Parser {
  
  var polynomPiece: String!
  var positive: Bool!
  
  var description: String {
    return "polynomPiece: \(polynomPiece ?? "shit"); positive: \(String(describing: positive))"
  }
}

struct PolynomValue {
  
  var coef: Double!
  var power: Int!
  
  init(coef: Double? = 0, power: Int? = 0) {
    self.coef = coef
    self.power = power
  }
  
  var description: String {
    return "coef: \(coef ?? -1); power: \(power ?? -1)"
  }
}
