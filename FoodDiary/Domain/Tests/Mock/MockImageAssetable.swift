//
//  MockImageAssetable.swift
//  Domain
//
//  Created by Kai Lee on 1/23/26.
//

import CoreLocation
@testable import Domain

struct MockImageAssetable: ImageAssetable {
    let id: String
    let creationDate: Date?
    let location: CLLocation?
    let pixelWidth: Int
    let pixelHeight: Int

    init(
        id: String,
        creationDate: Date? = nil,
        location: CLLocation? = nil,
        pixelWidth: Int = 100,
        pixelHeight: Int = 100
    ) {
        self.id = id
        self.creationDate = creationDate
        self.location = location
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
