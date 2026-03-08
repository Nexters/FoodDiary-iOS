//
//  InsightViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

@MainActor
public final class InsightViewModel<Repo: InsightRepository> {

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

    private let fetchInsightUseCase: FetchInsightUseCase<Repo>

    // MARK: - Init

    public init(fetchInsightUseCase: FetchInsightUseCase<Repo>) {
        self.fetchInsightUseCase = fetchInsightUseCase
        self.stateSubject = CurrentValueSubject(State())
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

    private func handleInput(_ action: Input) async {
        switch action {
        case .loadInsight:
            state.isLoading = true
            do {
                let insight = try await fetchInsightUseCase.execute()
                state.insight = insight
                state.isLoading = false
            } catch InsightError.insufficientData {
                state.hasInsufficientData = true
                state.isLoading = false
            } catch {
                state.isLoading = false
                eventSubject.send(.loadFailed(error))
            }
        }
    }
}

// MARK: - State / Input / Event

public extension InsightViewModel {

    struct State: Equatable {
        public var isLoading: Bool = false
        public var insight: Insight?
        public var hasInsufficientData: Bool = false
    }

    enum Input {
        case loadInsight
    }

    enum Event {
        case loadFailed(Error)
    }
}
