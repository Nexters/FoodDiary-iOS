//
//  CalendarPhotoDTO.swift
//  Data
//
//  Created by 강대훈 on 2/19/26.
//

import Foundation

public typealias CalendarPhotoResponseDTO = [String: CalendarPhotoDTO]

public struct CalendarPhotoDTO: Decodable {
    public let photos: [String]
}
