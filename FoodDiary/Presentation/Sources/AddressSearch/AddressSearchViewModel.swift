//
//  AddressSearchViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class AddressSearchViewModel<AddressRepo: AddressSearchRepository> {

    // MARK: - Output

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
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
    private let searchAddressUseCase: SearchAddressUseCase<AddressRepo>
    private let diaryId: Int

    // MARK: - Init

    public init(
        searchAddressUseCase: SearchAddressUseCase<AddressRepo>,
        diaryId: Int
    ) {
        self.searchAddressUseCase = searchAddressUseCase
        self.diaryId = diaryId
        self.stateSubject = CurrentValueSubject(State(
            suggestions: [],
            searchResults: [],
            isSearching: false,
            searchKeyword: "",
            mode: .suggestions
        ))
        setupBindings()
        loadSuggestions()
    }

    // MARK: - Private Methods

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
        case .updateSearchKeyword(let keyword):
            state.searchKeyword = keyword
            if keyword.isEmpty {
                state.searchResults = []
                state.mode = .suggestions
            }

        case .search:
            let keyword = state.searchKeyword
            guard !keyword.isEmpty else { return }
            state.isSearching = true
            state.mode = .searchResults
            do {
                let results = try await searchAddressUseCase.searchAddress(keyword: keyword)
                state.searchResults = results
            } catch {
                state.searchResults = []
            }
            state.isSearching = false

        case .selectAddress(let result):
            eventSubject.send(.addressSelected(result))

        case .dismiss:
            eventSubject.send(.dismissed)
        }
    }

    private func loadSuggestions() {
        Task(priority: .userInitiated) {
            do {
                let suggestions = try await searchAddressUseCase.fetchSuggestions(
                    diaryId: diaryId
                )
                await MainActor.run {
                    state.suggestions = suggestions
                }
            } catch {
                // 후보군 로드 실패 시 무시
            }
        }
    }

    private var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }
}

// MARK: - State, Input, Event

extension AddressSearchViewModel {
    public enum DisplayMode: Equatable {
        case suggestions
        case searchResults
    }

    public struct State: Equatable {
        public var suggestions: [AddressSearchResult]
        public var searchResults: [AddressSearchResult]
        public var isSearching: Bool
        public var searchKeyword: String
        public var mode: DisplayMode
    }

    public enum Input {
        case updateSearchKeyword(String)
        case search
        case selectAddress(AddressSearchResult)
        case dismiss
    }

    public enum Event {
        case addressSelected(AddressSearchResult)
        case dismissed
    }
}
