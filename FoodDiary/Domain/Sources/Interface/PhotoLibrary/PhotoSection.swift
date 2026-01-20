//
//  PhotoSection.swift
//  Core
//
//  Created by Kai Lee on 1/19/26.
//

import Photos

public struct PhotoSection: Sendable {
    public let date: Date
    public let photos: [PHAsset]

    public init(date: Date, photos: [PHAsset]) {
        self.date = date
        self.photos = photos
    }
}
