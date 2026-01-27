//
//  PHAsset+ImageAssetable.swift
//  Data
//
//  Created by Kai Lee on 1/23/26.
//

import CoreLocation
import Domain
import Photos

extension PHAsset: @retroactive ImageAssetable {
    public var id: String { localIdentifier }
}
