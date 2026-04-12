//
//  WeeklyCalendarViewController.swift
//  Presentation
//

import Combine
import Data
import DesignSystem
import Domain
import SnapKit
import UIKit

private enum Constants {
    static let horizontalInset: CGFloat = 20
}

public final class WeeklyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    AuthRepo: PhotoAuthorizationRepository,
    PushObserver: PushNotificationObserving
>: UIViewController {

    // MARK: - Dependencies

    private let viewModel: WeeklyCalendarViewModel<RecordRepo, AssetRepo, AuthRepo, PushObserver>

    // MARK: - Flow

    private let flowSubject = PassthroughSubject<CalendarFlow, Never>()
    public var flowPublisher: AnyPublisher<CalendarFlow, Never> {
        flowSubject.eraseToAnyPublisher()
    }

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private lazy var recordPromptHeaderView = RecordPromptHeaderView()
    private let headerView = WeeklyCalendarHeaderView()
    private let weekGridView = WeekGridView()
    private let bottomContentView = BottomContentView()

    private lazy var containerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [weekGridView, bottomContentView])
        sv.axis = .vertical
        sv.spacing = 24
        return sv
    }()

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        viewModel: WeeklyCalendarViewModel<RecordRepo, AssetRepo, AuthRepo, PushObserver>
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()

        viewModel.input.send(.loadInitialData)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.input.send(.viewDidAppear)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(recordPromptHeaderView)
        view.addSubview(headerView)
        view.addSubview(containerStackView)
    }

    private func setupConstraints() {
        recordPromptHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(28)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        headerView.snp.makeConstraints {
            $0.top.equalTo(recordPromptHeaderView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        containerStackView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-34)
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        headerView.previousTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToPreviousWeek)
            }
            .store(in: &cancellables)

        headerView.nextTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToNextWeek)
            }
            .store(in: &cancellables)

        weekGridView.dateTapPublisher
            .sink { [weak self] date in
                self?.viewModel.input.send(.selectDate(date))
            }
            .store(in: &cancellables)

        // 하단 + 버튼 탭 → 권한 체크 후 이미지 피커 표시
        bottomContentView.addButtonTapPublisher
            .sink { [weak self] in
                self?.handleAddButtonTap()
            }
            .store(in: &cancellables)

        // Foreground 복귀 시 데이터 갱신
        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.viewModel.input.send(.refreshData())
            }
            .store(in: &cancellables)

        // Output: ViewModel → View (State 기반)
        viewModel.statePublisher
            .map(\.nickname)
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nickname in
                self?.recordPromptHeaderView.configure(nickname: nickname)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.monthText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.headerView.setMonthText(text)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.canGoToNextWeek)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canGoNext in
                self?.headerView.setNextButtonEnabled(canGoNext)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map { (weekDays: $0.weekDays, selectedDate: $0.selectedDate) }
            .removeDuplicates(by: ==)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] days, selectedDate in
                self?.weekGridView.configure(with: days, selectedDate: selectedDate)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .compactMap(\.dateContent)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                guard let self else { return }
                let state: BottomContentView.State =
                    if !content.records.isEmpty {
                        .recorded(content.records)
                    } else if !content.processingRecords.isEmpty {
                        .processing(content.processingRecords)
                    } else {
                        .empty(hasPhotos: content.hasFoodPhotos)
                    }

                bottomContentView.configure(state: state)
            }
            .store(in: &cancellables)

        // 카드 스택 탭 → 상세 화면으로 이동
        bottomContentView.cardStackTapPublisher
            .sink { [weak self] record in
                self?.navigateToDetail(for: record.date)
            }
            .store(in: &cancellables)

        // 프로세싱 카드 탭 → 상세 화면으로 이동
        bottomContentView.processingTapPublisher
            .sink { [weak self] date in
                self?.navigateToDetail(for: date)
            }
            .store(in: &cancellables)

        // 코치마크 표시
        viewModel.statePublisher
            .map(\.shouldShowCoachmark)
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.showCoachmarkOverlay() }
            .store(in: &cancellables)

        // Event: 권한 거부 시 설정 이동 안내 Alert 표시 및 저장 결과 처리
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .photoAuthorizationDenied:
                    self?.showPhotoAuthorizationDeniedAlert()
                case .uploadCompleted(let date, let mealType):
                    self?.navigateToDetail(for: date, scrollTo: mealType, shouldPopToRoot: true)
                case .saveFailed(let error):
                    self?.showSaveErrorAlert(error)
                case .loadFailed(let error):
                    self?.showLoadErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Coachmark

    private func showCoachmarkOverlay() {
        let overlay = CoachmarkOverlayView()
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        overlay.alpha = 0
        UIView.animate(withDuration: 0.3) { overlay.alpha = 1 }

        overlay.didDismissPublisher
            .receive(on: DispatchQueue.main)
            .first()
            .sink { [weak self, weak overlay] _ in
                UIView.animate(
                    withDuration: 0.3,
                    animations: { overlay?.alpha = 0 },
                    completion: { _ in
                        overlay?.removeFromSuperview()
                        self?.viewModel.input.send(.dismissCoachmark)
                    }
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func handleAddButtonTap() {
        let date = viewModel.state.selectedDate
        flowSubject.send(.pushImagePicker(
            ImagePickerSceneInput(date: date) { [weak self] assets in
                let typed = assets.compactMap { $0 as? AssetRepo.Asset }
                self?.viewModel.input.send(.saveSelectedPhotos(typed))
            }
        ))
    }

    private func showPhotoAuthorizationDeniedAlert() {
        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "음식 사진을 기록하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })

        present(alert, animated: true)
    }

    // MARK: - Navigation

    private func navigateToDetail(
        for date: Date,
        scrollTo mealType: MealType? = nil,
        shouldPopToRoot: Bool = false
    ) {
        let records = viewModel.state.weekDays.records(for: date)
        let input = DetailSceneInput(
            date: date,
            records: records,
            scrollToMealType: mealType,
            shouldPopToRoot: shouldPopToRoot,
            onDismissWithDate: { [weak self] date in
                self?.viewModel.input.send(.refreshData(date))
            }
        )
        flowSubject.send(.pushDetail(input))
    }

    private func showLoadErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "불러오기 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showSaveErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "저장 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CalendarFlowEmitting

extension WeeklyCalendarViewController: CalendarFlowEmitting {}
