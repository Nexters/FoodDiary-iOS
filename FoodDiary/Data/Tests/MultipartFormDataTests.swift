//
//  MultipartFormDataTests.swift
//  DataTests
//
//  Created by 강대훈 on 2/17/26.
//

import Foundation
import Testing
@testable import Data

struct MultipartFormDataTests {
    @Test("contentType이 multipart형식으로 생성된다")
    func contentType_hasCorrectFormat() {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])

        #expect(sut.contentType.hasPrefix("multipart/form-data; boundary=Boundary-"))
    }

    @Test("body에 date 필드가 올바르게 포함된다")
    func body_containsDateField() throws {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])
        let bodyString = try #require(String(data: sut.body, encoding: .utf8))

        #expect(bodyString.contains("Content-Disposition: form-data; name=\"date\""))
        #expect(bodyString.contains(date))
    }

    @Test("body에 photo 파일 2개의 fileName, mimeType, data가 모두 포함된다")
    func body_containsBothPhotoFields() throws {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])
        let bodyString = try #require(String(data: sut.body, encoding: .utf8))

        #expect(bodyString.contains("filename=\"photo1.jpg\""))
        #expect(bodyString.contains("filename=\"photo2.jpg\""))
        #expect(bodyString.contains("Content-Type: image/jpeg"))
        #expect(bodyString.contains("dummy-image-data-1"))
        #expect(bodyString.contains("dummy-image-data-2"))
    }

    @Test("body가 올바른 boundary로 시작하고 종료된다")
    func body_hasCorrectBoundaryStartAndEnd() throws {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])
        let boundary = try #require(sut.contentType.components(separatedBy: "boundary=").last)
        let bodyString = try #require(String(data: sut.body, encoding: .utf8))

        #expect(bodyString.hasPrefix("--\(boundary)\r\n"))
        #expect(bodyString.hasSuffix("--\(boundary)--\r\n"))
    }

    @Test("body에 device_id 필드가 올바르게 포함된다")
    func body_containsDeviceIdField() throws {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])
        let bodyString = try #require(String(data: sut.body, encoding: .utf8))

        #expect(bodyString.contains("Content-Disposition: form-data; name=\"device_id\""))
        #expect(bodyString.contains(deviceId))
    }

    @Test("body에 photo 섹션이 파일 개수만큼 존재한다")
    func body_hasPhotoSectionsEqualToPhotoCount() throws {
        let sut = MultipartFormData(date: date, deviceId: deviceId, photos: [photo1, photo2])
        let bodyString = try #require(String(data: sut.body, encoding: .utf8))

        let photoSectionCount = bodyString.components(separatedBy: "name=\"photos\"").count - 1

        #expect(photoSectionCount == 2)
    }
}

extension MultipartFormDataTests {
    var date: String { "2026-02-17" }
    var deviceId: String { "test-device-id-1234" }
    var photo1: File {
        File(
            fileName: "photo1.jpg",
            mimeType: "image/jpeg",
            data: "dummy-image-data-1".data(using: .utf8)!
        )
    }
    
    var photo2: File {
        File(
            fileName: "photo2.jpg",
            mimeType: "image/jpeg",
            data: "dummy-image-data-2".data(using: .utf8)!
        )
    }
}
