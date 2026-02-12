//
//  PendingFoodRecord.swift
//  Domain
//

import UIKit

/// 분석 대기 중인 음식 기록 (서버 업로드 완료, AI 분석 대기 중)
public struct PendingFoodRecord: Identifiable, Equatable, Codable {
    public let id: String
    /// 서버에서 받은 업로드 ID (Remote Push로 결과 매칭 시 사용)
    public let uploadId: String
    public let date: Date
    public let representativeImage: UIImage
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        uploadId: String,
        date: Date,
        representativeImage: UIImage,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.uploadId = uploadId
        self.date = date
        self.representativeImage = representativeImage
        self.createdAt = createdAt
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, uploadId, date, imageData, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        uploadId = try container.decode(String.self, forKey: .uploadId)
        date = try container.decode(Date.self, forKey: .date)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        let imageData = try container.decode(Data.self, forKey: .imageData)
        guard let image = UIImage(data: imageData) else {
            throw DecodingError.dataCorruptedError(
                forKey: .imageData,
                in: container,
                debugDescription: "이미지 데이터를 UIImage로 변환할 수 없습니다"
            )
        }
        representativeImage = image
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uploadId, forKey: .uploadId)
        try container.encode(date, forKey: .date)
        try container.encode(createdAt, forKey: .createdAt)

        guard let imageData = representativeImage.jpegData(compressionQuality: 0.8) else {
            throw EncodingError.invalidValue(
                representativeImage,
                EncodingError.Context(
                    codingPath: [CodingKeys.imageData],
                    debugDescription: "UIImage를 JPEG 데이터로 변환할 수 없습니다"
                )
            )
        }
        try container.encode(imageData, forKey: .imageData)
    }
}
