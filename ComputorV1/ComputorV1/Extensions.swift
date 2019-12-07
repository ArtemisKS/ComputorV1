//
//  Extensions.swift
//  ComputorV1
//
//  Created by Artem Kuprijanets on 12/7/19.
//  Copyright © 2019 Artem Kuprijanets. All rights reserved.
//

import Foundation

extension Double {
  
  var getIntValue: Int? {
    
    return isRound ? Int(self) : nil
  }
  
  var isRound: Bool {
    return rounded() == self
  }
  
  var toString: String {
    return isRound ? "\(Int(self))" : "\(Double((1000*self).rounded())/1000)"
  }
}

extension String {
  
  func nextChar(to ind: String.Index) -> Character? {
    let lIndex = index(after: ind)
    return lIndex < endIndex ? self[lIndex] : nil
  }
  
  func prevChar(to ind: String.Index) -> Character? {
    guard ind > startIndex else { return nil }
    return self[index(before: ind)]
  }
  
  func trim() -> String {
    return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
  subscript (i: Int) -> Character
  {
    get {
      let index = self.index(startIndex, offsetBy: i)
      return self[index]
    }
  }
  
}

extension String.Index {
  
  func distance<S: StringProtocol>(in string: S) -> Int { string.distance(from: string.startIndex, to: self) }
}
