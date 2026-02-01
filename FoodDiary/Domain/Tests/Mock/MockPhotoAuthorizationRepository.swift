//
//  MockPhotoAuthorizationRepository.swift
//  Domain
//
//  Created by Kai Lee on 2/1/26.
//

@testable import Domain
import Foundation

final class MockPhotoAuthorizationRepository: PhotoAuthorizationRepository, @unchecked Sendable {
    var authorizationStatusToReturn: PhotoAuthorizationStatus = .authorized

    func authorizationStatus() -> PhotoAuthorizationStatus {
        authorizationStatusToReturn
    }

    func requestAuthorization() async -> PhotoAuthorizationStatus {
        authorizationStatusToReturn
    }
}
