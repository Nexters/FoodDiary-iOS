//
//  FoodPhotoSection.swift
//  Data
//
//  Created by Kai Lee on 1/20/26.
//

import Photos
import UIKit

public struct FoodPhotoSection {
    public let date: Date
    public let photos: [FoodPhoto]

    public init(date: Date, photos: [FoodPhoto]) {
        self.date = date
        self.photos = photos
    }
}
