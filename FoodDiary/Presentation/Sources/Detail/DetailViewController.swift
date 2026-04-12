//
//  DetailViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import Kingfisher
import SnapKit
import UIKit

public final class DetailViewController<
    RecordRepo: FoodRecordRepository,
    PushObserver: PushNotificationObserving
>: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static var dateNavigatorHeight: CGFloat { 64 }
        static var dateNavigatorTopPadding: CGFloat { 32 }
        static var dateNavigatorBottomSpacing: CGFloat { 0 }
        static var bottomPadding: CGFloat { 32 }
        static var floatingButtonSize: CGFloat { 56 }
        static var floatingButtonBottomInset: CGFloat { 32 }
        static var floatingButtonTrailingInset: CGFloat { 20 }
    }

    // MARK: - Dependencies

    private let viewModel: DetailViewModel<RecordRepo, PushObserver>
    private let onDismissWithDate: ((Date) -> Void)?
    private let editViewControllerFactory: ((FoodRecord) -> UIViewController)?
    private weak var imagePickerDelegate: (any ImagePickerDelegate)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView = UIView()

    private let dateNavigatorView = DetailDateNavigatorView()

    private let mealSectionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private lazy var floatingAddButton: UIButton = {
        let button: UIButton
        if #available(iOS 26, *) {
            var config = UIButton.Configuration.glass()
            config.image = UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
            config.cornerStyle = .capsule
            button = UIButton(configuration: config)
        } else {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
            config.background.visualEffect = UIBlurEffect(style: .systemMaterialDark)
            config.cornerStyle = .capsule
            button = UIButton(configuration: config)
        }
        button.tintColor = .white
        return button
    }()

    private let emptyDayTitleLabel: UILabel = {
        let label = UILabel()
        label.setText("기록된 다이어리가 없어요", style: .p18, color: .gray050)
        return label
    }()

    private let emptyDaySubtitleLabel: UILabel = {
        let label = UILabel()
        label.setText("음식 사진을 추가해보세요", style: .p15, color: .gray100)
        return label
    }()

    private lazy var emptyDayStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [emptyDayTitleLabel, emptyDaySubtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.isHidden = true
        return stack
    }()

    private let loadingIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray400
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let breakfastSection = MealSectionView(mealType: .breakfast)
    private let lunchSection = MealSectionView(mealType: .lunch)
    private let dinnerSection = MealSectionView(mealType: .dinner)
    private let snackSection = MealSectionView(mealType: .snack)

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var pendingScrollTarget: MealType?
    private let scrollToFirstRecord: Bool
    private let shouldPopToRoot: Bool

    // MARK: - Init

    public init(
        viewModel: DetailViewModel<RecordRepo, PushObserver>,
        initialScrollTarget: MealType? = nil,
        scrollToFirstRecord: Bool = true,
        shouldPopToRoot: Bool = false,
        onDismissWithDate: ((Date) -> Void)? = nil,
        editViewControllerFactory: ((FoodRecord) -> UIViewController)? = nil,
        imagePickerDelegate: (any ImagePickerDelegate)? = nil
    ) {
        self.viewModel = viewModel
        self.pendingScrollTarget = initialScrollTarget
        self.scrollToFirstRecord = scrollToFirstRecord
        self.shouldPopToRoot = shouldPopToRoot
        self.onDismissWithDate = onDismissWithDate
        self.editViewControllerFactory = editViewControllerFactory
        self.imagePickerDelegate = imagePickerDelegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupConstraints()
        setupBindings()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.hidesBarsOnSwipe = true
        viewModel.input.send(.loadRecords)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
        if isMovingFromParent {
            onDismissWithDate?(viewModel.state.currentDate)
        }
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "상세보기"

        if shouldPopToRoot {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(backButtonTapped)
            )
        }

        // More button
        let deleteAllAction = UIAction(
            title: "전체삭제",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.showDeleteAllConfirmation()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: UIMenu(children: [deleteAllAction])
        )
    }

    @objc private func backButtonTapped() {
        dismissDetail()
    }

    private func dismissDetail() {
        onDismissWithDate?(viewModel.state.currentDate)
        if shouldPopToRoot {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mealSectionsStackView)
        view.addSubview(emptyDayStackView)
        view.addSubview(dateNavigatorView)
        view.addSubview(floatingAddButton)
        view.addSubview(loadingIndicatorView)

        mealSectionsStackView.addArrangedSubview(breakfastSection)
        mealSectionsStackView.addArrangedSubview(lunchSection)
        mealSectionsStackView.addArrangedSubview(dinnerSection)
        mealSectionsStackView.addArrangedSubview(snackSection)
    }

    private func setupConstraints() {
        dateNavigatorView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.dateNavigatorTopPadding)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.dateNavigatorHeight)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        let topInset =
            Constants.dateNavigatorTopPadding + Constants.dateNavigatorHeight
            + Constants.dateNavigatorBottomSpacing
        scrollView.contentInset.top = topInset
        scrollView.verticalScrollIndicatorInsets.top = topInset

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        mealSectionsStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-Constants.bottomPadding)
        }

        emptyDayStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(scrollView)
        }

        floatingAddButton.snp.makeConstraints {
            $0.size.equalTo(Constants.floatingButtonSize)
            $0.trailing.equalToSuperview().inset(Constants.floatingButtonTrailingInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(Constants.floatingButtonBottomInset)
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        dateNavigatorView.previousTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToPreviousDay)
            }
            .store(in: &cancellables)

        dateNavigatorView.nextTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToNextDay)
            }
            .store(in: &cancellables)

        // Output: ViewModel → View
        viewModel.statePublisher
            .map(\.dateText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dateText in
                self?.dateNavigatorView.setDateText(dateText)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.isLoading)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.loadingIndicatorView.startAnimating()
                    self.emptyDayStackView.isHidden = true
                    self.scrollView.isHidden = true
                } else {
                    self.loadingIndicatorView.stopAnimating()
                    let state = self.viewModel.state
                    self.updateMealSections(
                        state.recordsByMealType,
                        processingRecords: state.processingRecordsByMealType)

                    if let mealType = self.resolveScrollTarget(state) {
                        DispatchQueue.main.async {
                            self.scrollToMealSection(mealType)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.isNextDayAvailable)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                self?.dateNavigatorView.setNextButtonEnabled(isAvailable)
            }
            .store(in: &cancellables)

        let recordsPublisher = viewModel.statePublisher.map(\.recordsByMealType)
        let processingPublisher = viewModel.statePublisher.map(\.processingRecordsByMealType)

        Publishers.CombineLatest(recordsPublisher, processingPublisher)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records, processing in
                self?.updateMealSections(records, processingRecords: processing)
            }
            .store(in: &cancellables)

        // Event: ViewModel → View
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .uploadCompleted:
                    break
                case .saveFailed(let error):
                    self?.showSaveErrorAlert(error)
                case .deleteAllCompleted:
                    self?.dismissDetail()
                case .deleteAllFailed(let error):
                    self?.showDeleteErrorAlert(error)
                }
            }
            .store(in: &cancellables)

        // Card events
        setupCardEventBindings()

        // Floating add button
        floatingAddButton.addTarget(
            self, action: #selector(floatingAddButtonTapped), for: .touchUpInside)
    }

    private func setupCardEventBindings() {
        breakfastSection.copyTapPublisher
            .merge(
                with: lunchSection.copyTapPublisher, dinnerSection.copyTapPublisher,
                snackSection.copyTapPublisher
            )
            .sink { [weak self] record in
                self?.handleCopy(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.shareTapPublisher
            .merge(
                with: lunchSection.shareTapPublisher, dinnerSection.shareTapPublisher,
                snackSection.shareTapPublisher
            )
            .sink { [weak self] record in
                self?.handleShare(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.editTapPublisher
            .merge(
                with: lunchSection.editTapPublisher, dinnerSection.editTapPublisher,
                snackSection.editTapPublisher
            )
            .sink { [weak self] record in
                self?.handleEdit(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.addButtonTapPublisher
            .merge(
                with: lunchSection.addButtonTapPublisher, dinnerSection.addButtonTapPublisher,
                snackSection.addButtonTapPublisher
            )
            .sink { [weak self] mealType in
                self?.handleAddPhoto(for: mealType)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func updateMealSections(
        _ recordsByMealType: [MealType: FoodRecord],
        processingRecords: [MealType: FoodRecord]
    ) {
        let sections: [(MealType, MealSectionView)] = [
            (.breakfast, breakfastSection),
            (.lunch, lunchSection),
            (.dinner, dinnerSection),
            (.snack, snackSection),
        ]

        var hasAnyContent = false

        for (mealType, section) in sections {
            if let record = recordsByMealType[mealType] {
                section.configure(state: .recorded(record))
                section.isHidden = false
                hasAnyContent = true
            } else if let processingRecord = processingRecords[mealType] {
                section.configure(state: .processing(processingRecord))
                section.isHidden = false
                hasAnyContent = true
            } else {
                section.configure(state: .empty)
                section.isHidden = false
                hasAnyContent = true
            }
        }

        emptyDayStackView.isHidden = hasAnyContent
        scrollView.isHidden = !hasAnyContent

        view.bringSubviewToFront(dateNavigatorView)
        view.bringSubviewToFront(floatingAddButton)
    }

    private func formatRecordForCopy(_ record: FoodRecord) -> String {
        let lines: String =
            if let name = record.restaurantName {
                if let address = record.address {
                    "\(name): \(address)"
                } else {
                    name
                }
            } else {
                ""
            }

        return lines
    }

    private func handleCopy(record: FoodRecord) {
        let text = formatRecordForCopy(record)
        UIPasteboard.general.string = text
        ToastView.show(type: .copyComplete)
    }

    private func handleShare(record: FoodRecord) {
        guard let name = record.restaurantName, !name.isEmpty,
            let url = record.restaurantUrl, !url.isEmpty
        else {
            showShareUnavailableAlert()
            return
        }

        let shareText = formatRecordForShare(name, url)
        presentShareSheet(items: [shareText])
    }

    private func formatRecordForShare(_ name: String, _ url: String) -> String {
        return "\(name) 맛을 기억하시나요?\n\n\(url)"
    }

    private func presentShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }

    // MARK: - Actions

    private func showDeleteAllConfirmation() {
        let alert = UIAlertController(
            title: "전체 삭제",
            message: "이 날짜의 모든 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
                self?.viewModel.input.send(.deleteAllRecords)
            }
        )
        present(alert, animated: true)
    }

    private func handleEdit(record: FoodRecord) {
        guard let editVC = editViewControllerFactory?(record) else { return }
        pendingScrollTarget = record.mealType
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc private func floatingAddButtonTapped() {
        handleAddPhoto()
    }

    private func handleAddPhoto() {
        let date = viewModel.state.currentDate
        imagePickerDelegate?.pushImagePicker(
            input: ImagePickerSceneInput(date: date) { [weak self] assets in
                self?.viewModel.input.send(.saveSelectedPhotos(assets))
            }
        )
    }

    private func showShareUnavailableAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "공유할 수 없는 다이어리입니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func handleAddPhoto(for mealType: MealType) {
        handleAddPhoto()
    }

    private func showDeleteErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "삭제 실패",
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

    // MARK: - Scroll to Meal Section

    private func mealSectionView(for mealType: MealType) -> MealSectionView {
        switch mealType {
        case .breakfast: return breakfastSection
        case .lunch: return lunchSection
        case .dinner: return dinnerSection
        case .snack: return snackSection
        }
    }

    private func resolveScrollTarget(
        _ state: DetailViewModel<RecordRepo, PushObserver>.State
    ) -> MealType? {
        if let mealType = pendingScrollTarget {
            pendingScrollTarget = nil
            return mealType
        }
        if scrollToFirstRecord {
            return firstContentMealType(state)
        }
        return nil
    }

    private func firstContentMealType(_ state: DetailViewModel<RecordRepo, PushObserver>.State)
        -> MealType?
    {
        let orderedMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        return orderedMealTypes.first { mealType in
            state.recordsByMealType[mealType] != nil
                || state.processingRecordsByMealType[mealType] != nil
        }
    }

    private func scrollToMealSection(_ mealType: MealType) {
        let targetSection = mealSectionView(for: mealType)
        let sectionFrame = targetSection.convert(targetSection.bounds, to: scrollView)
        let targetOffset = CGPoint(
            x: 0,
            y: sectionFrame.origin.y - scrollView.adjustedContentInset.top
        )
        scrollView.setContentOffset(targetOffset, animated: false)
    }
}
