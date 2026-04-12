//
//  AddressSearchSceneInput.swift
//  Presentation
//

import Domain

public struct AddressSearchSceneInput {
    public let diaryId: Int
    public let onSelected: (AddressSearchResult) -> Void

    public init(diaryId: Int, onSelected: @escaping (AddressSearchResult) -> Void) {
        self.diaryId = diaryId
        self.onSelected = onSelected
    }
}
