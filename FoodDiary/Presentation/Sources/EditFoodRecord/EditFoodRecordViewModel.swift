//
//  EditFoodRecordViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation
import UIKit

public final class EditFoodRecordViewModel<RecordRepo: FoodRecordRepository> {

    // MARK: - Output

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    public var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Input

    public let input = PassthroughSubject<Input, Never>()

    // MARK: - Private

    private let stateSubject: CurrentValueSubject<State, Never>
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let updateFoodRecordUseCase: UpdateFoodRecordUseCase<RecordRepo>
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>

    // MARK: - Init

    public init(
        record: FoodRecord,
        updateFoodRecordUseCase: UpdateFoodRecordUseCase<RecordRepo>,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>
    ) {
        self.updateFoodRecordUseCase = updateFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase

        self.stateSubject = CurrentValueSubject(
            State(
                originalRecord: record,
                photos: record.photos,
                newAssets: [],
                newPreviewImages: [],
                selectedGenre: record.genre,
                address: record.address,
                detailAddress: record.restaurantName ?? "",
                restaurantURL: nil,
                hashtags: record.hashtags,
                isSaving: false
            )
        )

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                Task(priority: .userInitiated) {
                    await self.handleInput(action)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleInput(_ action: Input) async {
        switch action {
        case .removeExistingImage(let index):
            guard index < state.photos.count else { return }
            state.photos.remove(at: index)

        case .removeNewImage(let index):
            guard index < state.newAssets.count else { return }
            state.newAssets.remove(at: index)
            state.newPreviewImages.remove(at: index)

        case .addImages(let assets, let previewImages):
            state.newAssets.append(contentsOf: assets)
            state.newPreviewImages.append(contentsOf: previewImages)

        case .selectGenre(let genre):
            state.selectedGenre = genre

        case .selectAddress(let result):
            state.address = result.roadAddress
            state.detailAddress = result.placeName
            state.restaurantURL = result.url

        case .updateDetailAddress(let text):
            state.detailAddress = text

        case .addHashtag(let tag):
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !state.hashtags.contains(trimmed) else { return }
            state.hashtags.append(trimmed)

        case .removeHashtag(let index):
            guard index < state.hashtags.count else { return }
            state.hashtags.remove(at: index)

        case .save:
            await performSave()

        case .delete:
            await performDelete()
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func performSave() async {
        state.isSaving = true
        defer { state.isSaving = false }

        let request = UpdateFoodRecordRequest(
            id: state.originalRecord.id,
            genre: state.selectedGenre,
            existingPhotoIds: state.photos.map(\.id),
            newAssets: state.newAssets,
            address: state.address,
            restaurantName: state.detailAddress.isEmpty ? nil : state.detailAddress,
            restaurantURL: state.restaurantURL,
            hashtags: state.hashtags
        )

        do {
            let updatedRecord = try await updateFoodRecordUseCase.execute(request)
            eventSubject.send(.saveCompleted(updatedRecord))
        } catch {
            eventSubject.send(.error(error))
        }
    }

    @MainActor
    private func performDelete() async {
        do {
            try await deleteFoodRecordUseCase.execute(id: state.originalRecord.id)
            eventSubject.send(.deleteCompleted)
        } catch {
            eventSubject.send(.error(error))
        }
    }
}

// MARK: - State, Input, Event

extension EditFoodRecordViewModel {
    public struct State: Equatable {
        public var originalRecord: FoodRecord
        public var photos: [PhotoInfo]
        public var newAssets: [any ImageAssetable]
        public var newPreviewImages: [UIImage]
        public var selectedGenre: FoodGenre
        public var address: String?
        public var detailAddress: String
        public var restaurantURL: String?
        public var hashtags: [String]
        public var isSaving: Bool

        /// 하위 호환용 computed property
        public var imageURLs: [URL] {
            photos.map(\.imageURL)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.originalRecord == rhs.originalRecord
                && lhs.photos == rhs.photos
                && lhs.newAssets.count == rhs.newAssets.count
                && lhs.selectedGenre == rhs.selectedGenre
                && lhs.address == rhs.address
                && lhs.detailAddress == rhs.detailAddress
                && lhs.restaurantURL == rhs.restaurantURL
                && lhs.hashtags == rhs.hashtags
                && lhs.isSaving == rhs.isSaving
        }
    }

    public enum Input {
        case removeExistingImage(at: Int)
        case removeNewImage(at: Int)
        case addImages(assets: [any ImageAssetable], previewImages: [UIImage])
        case selectGenre(FoodGenre)
        case selectAddress(AddressSearchResult)
        case updateDetailAddress(String)
        case addHashtag(String)
        case removeHashtag(at: Int)
        case save
        case delete
    }

    public enum Event {
        case saveCompleted(FoodRecord)
        case deleteCompleted
        case error(Error)
    }
}
