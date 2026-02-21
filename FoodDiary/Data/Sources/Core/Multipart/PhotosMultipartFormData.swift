//
//  PhotosMultipartFormData.swift
//  Data
//

import Foundation

/// POST /diaries/{diary_id}/photos 전용 multipart (사진 파일만 전송)
public struct PhotosMultipartFormData {
    private let boundary: String
    public let contentType: String
    public let body: Data

    public init(photos: [File]) {
        self.boundary = "Boundary-\(UUID().uuidString)"
        self.contentType = "multipart/form-data; boundary=\(boundary)"

        var data = Data()

        for file in photos {
            data.appendString("--\(boundary)\r\n")
            data.appendString(
                "Content-Disposition: form-data; name=\"photos\"; filename=\"\(file.fileName)\"\r\n"
            )
            data.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
            data.append(file.data)
            data.appendString("\r\n")
        }

        data.appendString("--\(boundary)--\r\n")

        self.body = data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
