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
    PendingRepo: PendingFoodRecordRepository,
    PushObserver: PushNotificationObserving
>: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static var dateNavigatorHeight: CGFloat { 64 }
        static var dateNavigatorTopPadding: CGFloat { 32 }
        static var dateNavigatorBottomSpacing: CGFloat { 16 }
        static var bottomPadding: CGFloat { 32 }
        static var toastCornerRadius: CGFloat { 16 }
        static var toastHeight: CGFloat { 32 }
        static var toastMinWidth: CGFloat { 150 }
        static var toastBottomOffset: CGFloat { 32 }
    }

    // MARK: - Dependencies

    private let viewModel: DetailViewModel<RecordRepo, PendingRepo, PushObserver>
    private let onDismissWithDate: ((Date) -> Void)?
    private let editViewControllerFactory: ((FoodRecord) -> UIViewController)?
    private let presentImagePickerHandler: ((UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void) -> Void)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false

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

    private let breakfastSection = MealSectionView(mealType: .breakfast)
    private let lunchSection = MealSectionView(mealType: .lunch)
    private let dinnerSection = MealSectionView(mealType: .dinner)
    private let snackSection = MealSectionView(mealType: .snack)

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        viewModel: DetailViewModel<RecordRepo, PendingRepo, PushObserver>,
        onDismissWithDate: ((Date) -> Void)? = nil,
        editViewControllerFactory: ((FoodRecord) -> UIViewController)? = nil,
        presentImagePickerHandler: ((UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismissWithDate = onDismissWithDate
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

        // More button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
    }

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mealSectionsStackView)
        view.addSubview(dateNavigatorView)

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
            .map(\.currentDate)
            .removeDuplicates { Calendar.current.isDate($0, inSameDayAs: $1) }
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.scrollView.setContentOffset(
                    CGPoint(x: 0, y: -self.scrollView.contentInset.top),
                    animated: false
                )
            }
            .store(in: &cancellables)

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
                self?.dateNavigatorView.setPending(isLoading)
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
        let pendingPublisher = viewModel.statePublisher.map(\.pendingRecords)

        Publishers.CombineLatest(recordsPublisher, pendingPublisher)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records, pending in
                self?.updateMealSections(records, pendingRecords: pending)
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
                }
            }
            .store(in: &cancellables)

        // Card events
        setupCardEventBindings()
    }

    private func setupCardEventBindings() {
        breakfastSection.copyTapPublisher
            .merge(with: lunchSection.copyTapPublisher, dinnerSection.copyTapPublisher, snackSection.copyTapPublisher)
            .sink { [weak self] record in
                self?.handleCopy(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.shareTapPublisher
            .merge(with: lunchSection.shareTapPublisher, dinnerSection.shareTapPublisher, snackSection.shareTapPublisher)
            .sink { [weak self] record in
                self?.handleShare(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.editTapPublisher
            .merge(with: lunchSection.editTapPublisher, dinnerSection.editTapPublisher, snackSection.editTapPublisher)
            .sink { [weak self] record in
                self?.handleEdit(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.addButtonTapPublisher
            .merge(with: lunchSection.addButtonTapPublisher, dinnerSection.addButtonTapPublisher, snackSection.addButtonTapPublisher)
            .sink { [weak self] mealType in
                self?.handleAddPhoto(for: mealType)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func updateMealSections(
        _ recordsByMealType: [MealType: FoodRecord],
        pendingRecords: [PendingFoodRecord]
    ) {
        let pendingByMealType = Dictionary(grouping: pendingRecords, by: \.mealType)

        let sections: [(MealType, MealSectionView)] = [
            (.breakfast, breakfastSection),
            (.lunch, lunchSection),
            (.dinner, dinnerSection),
            (.snack, snackSection),
        ]

        for (mealType, section) in sections {
            let state: MealSectionView.State
            if let record = recordsByMealType[mealType] {
                state = .recorded(record)
            } else if let pendings = pendingByMealType[mealType], !pendings.isEmpty {
                state = .pending(pendings)
            } else {
                state = .empty
            }
            section.configure(state: state)
        }
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

        // Show toast
        showToast(message: "클립보드에 복사되었습니다")
    }

    private func handleShare(record: FoodRecord) {
        // TODO: 공유할 콘텐츠 구성
    }

    private func presentShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }

    // TODO: 임시로 걍 대충 떼워놓음
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = Constants.toastCornerRadius
        toastLabel.clipsToBounds = true

        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Constants.toastBottomOffset)
            $0.height.equalTo(Constants.toastHeight)
            $0.width.greaterThanOrEqualTo(Constants.toastMinWidth)
        }

        UIView.animate(
            withDuration: 0.3,
            animations: {
                toastLabel.alpha = 1
            }
        ) { _ in
            UIView.animate(
                withDuration: 0.3, delay: 1.5, options: [],
                animations: {
                    toastLabel.alpha = 0
                }
            ) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }

    // MARK: - Actions

    @objc private func moreButtonTapped() {
        // TODO: Show more options menu
    }

    private func handleEdit(record: FoodRecord) {
        guard let editVC = editViewControllerFactory?(record) else { return }
        editVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(editVC, animated: true)
    }

    private func handleAddPhoto(for mealType: MealType) {
        guard let nav = navigationController else { return }
        let date = viewModel.state.currentDate

        presentImagePickerHandler?(nav, date) { [weak self] assets in
            self?.viewModel.input.send(.saveSelectedPhotos(assets))
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
}
