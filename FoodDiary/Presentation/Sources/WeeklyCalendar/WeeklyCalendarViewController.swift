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
    AnalysisRepo: AnalysisResultRepository
>: UIViewController where ImageProvider.Asset == AssetRepo.Asset {

    // MARK: - Dependencies

    private let viewModel:
        WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, ImageProvider, PendingRepo, AnalysisRepo
        >
    private let imageProvider: ImageProvider

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.setText("이번주 음식을 기록해 보세요", style: .p12)
        label.textColor = .white
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.setText("길동님의 음식 기록,\n지금 바로 쓸 수 있어요", style: .hd20)
        label.textColor = .white
        return label
    }()

    private let headerView = WeeklyCalendarHeaderView()
    private let weekGridView = WeekGridView()
    private let bottomContentView = BottomContentView()

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        viewModel: WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, ImageProvider, PendingRepo, AnalysisRepo
        >,
        imageProvider: ImageProvider
    ) {
        self.viewModel = viewModel
        self.imageProvider = imageProvider
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

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(headerView)
        contentView.addSubview(weekGridView)
        view.addSubview(bottomContentView)

        // 사용자 이름 설정 (추후 실제 데이터로 교체)
        titleLabel.setText("길동님의 음식 기록,\n지금 바로 쓸 수 있어요", style: .hd20)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.width.equalToSuperview().offset(-32)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
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
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
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
                self?.bottomContentView.configure(
                    records: content.records,
                    pendingRecords: content.pendingRecords,
                    photoCount: content.foodPhotoCount
                )
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
                case .loadFailed:
                    break
                case .analysisCompleted:
                    break
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
                configuration: .default
            )

            picker.resultPublisher
                .sink { [weak self] result in
                    self?.handleImagePickerResult(result)
                }
                .store(in: &cancellables)

            navigationController?.pushViewController(picker, animated: true)
        } catch {
            // 에러 처리
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
}
