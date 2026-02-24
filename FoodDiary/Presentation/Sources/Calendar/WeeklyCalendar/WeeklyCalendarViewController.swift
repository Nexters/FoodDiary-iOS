//
//  WeeklyCalendarViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import Photos
import SnapKit
import UIKit

public final class WeeklyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    AuthRepo: PhotoAuthorizationRepository,
    ImageProvider: RenderableImageRepository,
    PendingRepo: PendingFoodRecordRepository,
    PushObserver: PushNotificationObserving
>: UIViewController where ImageProvider.Asset == AssetRepo.Asset {

    // MARK: - Dependencies

    private let viewModel:
        WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, PendingRepo, PushObserver
        >
    private let imageProvider: ImageProvider
    private let getNicknameUseCase: GetNicknameUseCase
    private let detailViewModelFactory: (Date, [FoodRecord]) -> DetailViewModel<RecordRepo, PendingRepo, PushObserver>
    private let editViewControllerFactory: ((FoodRecord) -> UIViewController)?
    private let presentImagePickerHandler: ((UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void) -> Void)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let recordPromptHeaderView = RecordPromptHeaderView()
    private let headerView = WeeklyCalendarHeaderView()
    private let weekGridView = WeekGridView()
    private let bottomContentView = BottomContentView()

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        viewModel: WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, PendingRepo, PushObserver
        >,
        imageProvider: ImageProvider,
        getNicknameUseCase: GetNicknameUseCase,
        detailViewModelFactory: @escaping (Date, [FoodRecord]) -> DetailViewModel<RecordRepo, PendingRepo, PushObserver>,
        editViewControllerFactory: ((FoodRecord) -> UIViewController)? = nil,
        presentImagePickerHandler: ((UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.imageProvider = imageProvider
        self.getNicknameUseCase = getNicknameUseCase
        self.detailViewModelFactory = detailViewModelFactory
        self.editViewControllerFactory = editViewControllerFactory
        self.presentImagePickerHandler = presentImagePickerHandler
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

        if let nickname = getNicknameUseCase.execute() {
            recordPromptHeaderView.configure(nickname: nickname)
        }

        viewModel.input.send(.loadInitialData)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(recordPromptHeaderView)
        contentView.addSubview(headerView)
        contentView.addSubview(weekGridView)
        view.addSubview(bottomContentView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.width.equalToSuperview().offset(-40)
        }

        recordPromptHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.equalTo(recordPromptHeaderView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview()
        }

        weekGridView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            // $0.height.equalTo(80)
            $0.bottom.equalToSuperview()
        }

        bottomContentView.snp.makeConstraints {
            $0.top.equalTo(weekGridView.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview()
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
                self?.viewModel.input.send(.refreshData)
            }
            .store(in: &cancellables)

        // Output: ViewModel → View (State 기반)
        viewModel.statePublisher
            .map(\.monthText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.headerView.setMonthText(text)
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
                    } else if !content.pendingRecords.isEmpty {
                        .pending(content.pendingRecords)
                    } else {
                        .empty
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

        // Event: 권한 거부 시 설정 이동 안내 Alert 표시 및 저장 결과 처리
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .photoAuthorizationDenied:
                    self?.showPhotoAuthorizationDeniedAlert()
                case .uploadCompleted:
                    break
                case .saveFailed(let error):
                    self?.showSaveErrorAlert(error)
                case .loadFailed(let error):
                    self?.showLoadErrorAlert(error)
                case .analysisFailed(_, let reason):
                    self?.showAnalysisFailedAlert(reason: reason)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func handleAddButtonTap() {
        if viewModel.checkPhotoAuthorizationForAddingPhoto() {
            Task {
                await presentImagePicker()
            }
        } else {
            // 권한이 없으면 재요청 (notDetermined면 시스템 다이얼로그, 아니면 denied 이벤트 발생)
            viewModel.input.send(.requestPhotoAuthorization)
        }
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

    @MainActor
    private func presentImagePicker() async {
        let selectedDate = viewModel.state.selectedDate

        do {
            let foodImageAssets = try await viewModel.photos(for: selectedDate)
            let selectedPhotos = foodImageAssets.map { $0.imageAsset }

            // 음식 확률 0.6 이상인 사진 ID를 미리 선택
            let preselectedIds = Set(
                foodImageAssets
                    .filter { $0.foodProbability >= 0.6 }
                    .map { $0.id }
            )

            let picker = ImagePickerViewController(
                photos: selectedPhotos,
                preselectedIds: preselectedIds,
                imageProvider: imageProvider,
                configuration: .withMaxSelectionCount(10)
            )

            picker.resultPublisher
                .sink { [weak self] result in
                    self?.handleImagePickerResult(result)
                }
                .store(in: &cancellables)

            navigationController?.pushViewController(picker, animated: true)
        } catch {
            showLoadErrorAlert(error)
        }
    }

    private func handleImagePickerResult(_ result: ImagePickerResult<AssetRepo.Asset>) {
        switch result {
        case .selected(let assets):
            navigationController?.popViewController(animated: true)
            viewModel.input.send(.saveSelectedPhotos(assets))
        case .cancelled:
            navigationController?.popViewController(animated: true)
        }
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

    private func showAnalysisFailedAlert(reason: String) {
        let alert = UIAlertController(
            title: "분석 실패",
            message: reason,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func navigateToDetail(for date: Date) {
        let records = viewModel.state.weekDays.records(for: date)

        let detailViewModel = detailViewModelFactory(date, records)
        let detailVC = DetailViewController(
            viewModel: detailViewModel,
            onDismissWithDate: { [weak self] date in
                self?.viewModel.input.send(.selectDate(date))
            },
            editViewControllerFactory: editViewControllerFactory,
            presentImagePickerHandler: presentImagePickerHandler
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
