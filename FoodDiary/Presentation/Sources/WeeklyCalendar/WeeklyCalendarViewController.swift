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

        viewModel.loadInitialData.send()
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
        contentView.addSubview(bottomContentView)

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
        }

        bottomContentView.snp.makeConstraints {
            $0.top.equalTo(weekGridView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        headerView.previousTapPublisher
            .subscribe(viewModel.goToPreviousWeek)
            .store(in: &cancellables)

        headerView.nextTapPublisher
            .subscribe(viewModel.goToNextWeek)
            .store(in: &cancellables)

        weekGridView.dateTapPublisher
            .subscribe(viewModel.selectDate)
            .store(in: &cancellables)

        // Output: ViewModel → View
        viewModel.monthTextPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.headerView.setMonthText(text)
            }
            .store(in: &cancellables)

        viewModel.weekDaysPublisher
            .combineLatest(viewModel.selectedDatePublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] days, selectedDate in
                self?.weekGridView.configure(with: days, selectedDate: selectedDate)
            }
            .store(in: &cancellables)

        viewModel.selectedDateRecordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                self?.bottomContentView.configure(hasRecords: !records.isEmpty, records: records)
            }
            .store(in: &cancellables)

        // 하단 + 버튼 탭 → 이미지 피커 표시
        bottomContentView.addButtonTapPublisher
            .sink { [weak self] in
                self?.presentImagePicker()
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation

    private func presentImagePicker() {
        // 선택된 날짜의 사진들을 가져와서 ImagePicker에 전달
        var selectedPhotos: [AssetRepo.Asset] = []

        viewModel.selectedDatePhotosPublisher
            .first()
            .sink { photos in
                selectedPhotos = photos.map { $0.imageAsset }
            }
            .store(in: &cancellables)

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
