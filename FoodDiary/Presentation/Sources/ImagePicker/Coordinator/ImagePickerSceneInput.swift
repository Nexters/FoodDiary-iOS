//
//  ImagePickerSceneInput.swift
//  Presentation
//

import Domain
import Foundation

public struct ImagePickerSceneInput {
    public let date: Date
    public let onSelected: ([any ImageAssetable]) -> Void

    public init(date: Date, onSelected: @escaping ([any ImageAssetable]) -> Void) {
        self.date = date
        self.onSelected = onSelected
    }
}
