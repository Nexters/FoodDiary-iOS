//
//  MultipartFormData.swift
//  Data
//
//  Created by 강대훈 on 2/16/26.
//

import Foundation

public struct MultipartFormData {
    private let boundary: String
    public let contentType: String
    public let body: Data

    public init(
        date: String,
        photos: [File]
    ) {
        self.boundary = "Boundary-\(UUID().uuidString)"
        self.contentType = "multipart/form-data; boundary=\(boundary)"

        var data = Data()

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"date\"\r\n\r\n")
        data.appendString("\(date)\r\n")

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

public struct File {
    let fileName: String
    let mimeType: String
    let data: Data
    
    public init(fileName: String, mimeType: String, data: Data) {
        self.fileName = fileName
        self.mimeType = mimeType
        self.data = data
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
