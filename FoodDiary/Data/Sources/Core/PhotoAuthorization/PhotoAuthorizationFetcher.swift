//
//  PhotoAuthorizationFetcher.swift
//  Data
//
//  Created by Kai Lee on 2/1/26.
//

import Domain
import Photos

/// 사진 라이브러리 권한을 관리하는 `PhotoAuthorizationRepository` 구현체
public struct PhotoAuthorizationFetcher: PhotoAuthorizationRepository {
    public init() {}

    public func authorizationStatus() -> PhotoAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite).toDomain()
    }

    public func requestAuthorization() async -> PhotoAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite).toDomain()
    }
}

// MARK: - PHAuthorizationStatus Extension

extension PHAuthorizationStatus {
    func toDomain() -> PhotoAuthorizationStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .denied
        }
    }
}
