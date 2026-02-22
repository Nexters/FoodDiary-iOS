//
//  HTTPBody.swift
//  Data
//
//  Created by 강대훈 on 2/16/26.
//

import Foundation

public enum HTTPBody {
    case json(Encodable)
    case multipart(MultipartFormData)
    case photosMultipart(PhotosMultipartFormData)
    case none
}
