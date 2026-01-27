//
//  ImageAssetable.swift
//  Domain
//
//  Created by Kai Lee on 1/23/26.
//

import CoreLocation

/// 이미지 Asset의 메타데이터를 나타내는 프로토콜
public protocol ImageAssetable: Sendable {
    var id: String { get }
    var creationDate: Date? { get }
    var location: CLLocation? { get }
    var pixelWidth: Int { get }
    var pixelHeight: Int { get }
}
