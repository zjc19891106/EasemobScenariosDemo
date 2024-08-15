//
//  LimitedArray.swift
//  EasemobScenariosDemo
//
//  Created by 朱继超 on 2024/8/8.
//

import Foundation
import EaseChatUIKit

struct LimitedArray<Element> {
    private var elements: [Element] = []
    let maxCount: Int

    init(maxCount: Int) {
        self.maxCount = maxCount
    }

    mutating func append(_ element: Element) {
        if self.elements.count < self.maxCount {
            self.elements.append(element)
        } else {
            self.elements.removeFirst()
        }
    }
    
    mutating func append(contentsOf: [Element]) {
        for element in contentsOf {
            self.append(element)
        }
    }
    
    mutating func remove(at index: Int) {
        if index < 0 || index >= self.elements.count {
            return
        }
        self.elements.remove(at: index)
    }
    
    mutating func removeFirst() {
        self.elements.removeFirst()
    }
    
    mutating func removeLast() {
        self.elements.removeLast()
    }
    
    subscript(safe index: Int) -> Element? {
        return array[safe: index]
    }

    var array: [Element] {
        return elements
    }
    
    func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try self.elements.contains(where: predicate)
    }
    
    func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try self.elements.first(where: predicate)
    }
    
    mutating func bringToFront(predicate: (Element) throws -> Bool) rethrows {
        if let index = try self.elements.firstIndex(where: predicate) {
            let element = self.elements.remove(at: index)
            self.elements.append(element)
        }
    }
}
