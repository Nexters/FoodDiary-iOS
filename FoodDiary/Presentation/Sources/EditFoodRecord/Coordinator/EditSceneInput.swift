//
//  EditSceneInput.swift
//  Presentation
//

import Domain

public struct EditSceneInput {
    public let record: FoodRecord

    public init(record: FoodRecord) {
        self.record = record
    }
}
