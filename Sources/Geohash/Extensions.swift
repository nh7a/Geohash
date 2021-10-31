//
//  File.swift
//  
//
//  Created by Jacob Hearst on 10/31/21.
//

import Foundation

extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }
    
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}
