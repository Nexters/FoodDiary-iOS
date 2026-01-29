//
//  WeeklyCalendarViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

public final class WeeklyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    ImageProvider: RenderableImageRepository
>: UIViewController where ImageProvider.Asset == AssetRepo.Asset {

    // MARK: - Dependencies

    private let viewModel: WeeklyCalendarViewModel<RecordRepo, AssetRepo>
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
        label.text = "이번주 음식을 기록해 보세요"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 24, weight: .bold)
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
        viewModel: WeeklyCalendarViewModel<RecordRepo, AssetRepo>,
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

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.background.color
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(headerView)
        contentView.addSubview(weekGridView)
        view.addSubview(bottomContentView)

        // 사용자 이름 설정 (추후 실제 데이터로 교체)
        titleLabel.text = "길동님의 음식 기록,\n지금 바로 쓸 수 있어요"
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        headerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }

        weekGridView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(80)
            $0.bottom.equalToSuperview()
        }

        bottomContentView.snp.makeConstraints {
            $0.top.equalTo(weekGridView.snp.bottom).offset(24)
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
            .map { ($0.weekDays, $0.selectedDate) }
            .removeDuplicates { prev, curr in
                prev.0 == curr.0 && Calendar.current.isDate(prev.1, inSameDayAs: curr.1)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] days, selectedDate in
                self?.weekGridView.configure(with: days, selectedDate: selectedDate)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.selectedDateRecords)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                self?.bottomContentView.configure(hasRecords: !records.isEmpty, records: records)
            }
            .store(in: &cancellables)

        // Event: 권한 거부 시 설정 이동 안내 Alert 표시
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .photoAuthorizationDenied:
                    self?.showPhotoAuthorizationDeniedAlert()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func handleAddButtonTap() {
        if viewModel.checkPhotoAuthorizationForAddingPhoto() {
            presentImagePicker()
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
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Navigation

    private func presentImagePicker() {
        // 선택된 날짜의 사진들을 가져와서 ImagePicker에 전달
        let selectedPhotos = viewModel.state.selectedDatePhotos.map { $0.imageAsset }

        let picker = ImagePickerViewController(
            photos: selectedPhotos,
            imageProvider: imageProvider,
            configuration: .default
        )

        picker.resultPublisher
            .sink { [weak self] result in
                self?.handleImagePickerResult(result)
            }
            .store(in: &cancellables)

        navigationController?.pushViewController(picker, animated: true)
    }

    private func handleImagePickerResult(_ result: ImagePickerResult<AssetRepo.Asset>) {
        switch result {
        case .selected(let assets):
            navigationController?.popViewController(animated: true)
            // TODO: AI 분석 로딩 화면으로 이동
            print("Selected \(assets.count) photos for AI analysis")
        case .cancelled:
            navigationController?.popViewController(animated: true)
        }
    }
}
