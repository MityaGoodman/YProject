//
//  Entity.swift
//  YProject
//
//  Created by Митя on 23.07.2025.
//

import Foundation

public struct Entity: Equatable {
    public let value: Decimal
    public let label: String
    
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
    
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.value == rhs.value && lhs.label == rhs.label
    }
}

