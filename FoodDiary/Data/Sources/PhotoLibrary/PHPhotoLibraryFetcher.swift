//
//  PHPhotoLibraryService.swift
//  Data
//
//  Created by Kai Lee on 1/19/26.
//

import Core
import Photos

public final class PHPhotoLibraryFetcher: PhotoLibraryRepresentable {
    public init() {}

    public func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    public func fetchPhotosByDate(
        from startDate: Date,
        to endDate: Date?
    ) async throws -> [PhotoSection] {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.notAuthorized
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = [
            NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue),
            NSPredicate(format: "creationDate >= %@", startDate as NSDate)
        ]
        if let end = endDate {
            predicates.append(NSPredicate(format: "creationDate <= %@", end as NSDate))
        }
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                return []
            }
            
            let fetchResult = PHAsset.fetchAssets(with: options)
            return self.groupByDate(fetchResult)
        }.value
    }
}

private extension PHPhotoLibraryFetcher {
    func groupByDate(_ fetchResult: PHFetchResult<PHAsset>) -> [PhotoSection] {
        let calendar = Calendar.current
        var sections: [Date: [PHAsset]] = [:]

        fetchResult.enumerateObjects { asset, _, _ in
            guard let creationDate = asset.creationDate else {
                return
            }
            
            let dateKey = calendar.startOfDay(for: creationDate)
            sections[dateKey, default: []].append(asset)
        }

        return sections
            .lazy
            .map { PhotoSection(date: $0.key, photos: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

public enum PhotoLibraryError: LocalizedError {
    case notAuthorized

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "사진 라이브러리 접근 권한이 없습니다."
        }
    }
}
