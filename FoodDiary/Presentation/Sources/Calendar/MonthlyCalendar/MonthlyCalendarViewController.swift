//
//  MonthlyCalendarViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

public final class MonthlyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AuthRepo: PhotoAuthorizationRepository
>: UIViewController, UICollectionViewDelegate {

    private enum Section: Hashable {
        case calendar
    }

    // MARK: - Dependencies

    private let viewModel: MonthlyCalendarViewModel<RecordRepo, AuthRepo>
    private let detailViewControllerFactory: ((Date, [FoodRecord], MealType?, Bool, ((Date) -> Void)?) -> UIViewController)

    // MARK: - UI Components

    private let recordPromptHeaderView = RecordPromptHeaderView()
    private let monthYearHeaderView = MonthlyCalendarHeaderView()
    private let weekdayHeaderView = WeekdayHeaderView()
    
    private lazy var containerView: UIView = {
        let v = UIView()
        v.layer.borderColor = DesignSystemAsset.sd800.color.cgColor
        v.backgroundColor = DesignSystemAsset.sd900.color
        v.layer.borderWidth = Constants.containerBorderWidth
        v.layer.cornerRadius = Constants.containerCornerRadius
        return v
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [weekdayHeaderView, collectionView])
        sv.axis = .vertical
        sv.distribution = .fill
        sv.spacing = Constants.stackSpacing
        return sv
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(
            MonthlyCalendarDayCell.self,
            forCellWithReuseIdentifier: MonthlyCalendarDayCell.reuseIdentifier
        )
        return cv
    }()

    // MARK: - State

    private var dataSource: UICollectionViewDiffableDataSource<Section, MonthlyCalendarDay>?
    private var cancellables = Set<AnyCancellable>()
    private var monthPickerCancellables = Set<AnyCancellable>()
    private var numberOfWeeks: Int = 5
    private var collectionViewHeightConstraint: Constraint?

    // MARK: - Init

    public init(
        viewModel: MonthlyCalendarViewModel<RecordRepo, AuthRepo>,
        detailViewControllerFactory: @escaping (Date, [FoodRecord], MealType?, Bool, ((Date) -> Void)?) -> UIViewController
    ) {
        self.viewModel = viewModel
        self.detailViewControllerFactory = detailViewControllerFactory
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
        setupDataSource()
        setupBindings()

        collectionView.delegate = self

        viewModel.input.send(.loadInitialData)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.send(.refreshCurrentMonth)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeight()
    }


    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(recordPromptHeaderView)
        view.addSubview(monthYearHeaderView)
        view.addSubview(containerView)
        containerView.addSubview(stackView)

        let mypageButton = UIBarButtonItem(
            image: DesignSystemAsset.iconMypage.image,
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.rightBarButtonItem = mypageButton
    }

    private func setupConstraints() {
        recordPromptHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.recordPromptTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        monthYearHeaderView.snp.makeConstraints {
            $0.top.equalTo(recordPromptHeaderView.snp.bottom).offset(Constants.monthYearHeaderTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        containerView.snp.makeConstraints {
            $0.top.equalTo(monthYearHeaderView.snp.bottom).offset(Constants.containerTopOffset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(Constants.containerBottomOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.stackTopInset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.bottom.equalToSuperview().inset(Constants.stackBottomInset)
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, _ in
            guard let self else { return nil }

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / Constants.numberOfDaysInWeek),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: Constants.cellHorizontalSpacing,
                bottom: 0,
                trailing: Constants.cellHorizontalSpacing
            )

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0 / CGFloat(self.numberOfWeeks))
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, MonthlyCalendarDay>(collectionView: collectionView) { collectionView, indexPath, day in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MonthlyCalendarDayCell.reuseIdentifier,
                for: indexPath
            ) as? MonthlyCalendarDayCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: day)
            return cell
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        monthYearHeaderView.monthPickerTapPublisher
            .sink { [weak self] in
                self?.presentMonthPicker()
            }
            .store(in: &cancellables)

        // Output: ViewModel → View
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
            .map(\.monthYearText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.monthYearHeaderView.setMonthYearText(text)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateCalendar(days: state.monthDays, numberOfWeeks: state.numberOfWeeks)
            }
            .store(in: &cancellables)

        // Event: ViewModel → View
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .navigateToDetail(let date, let records):
                    self?.navigateToDetail(date: date, records: records)
                case .showError(let error):
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func updateCalendar(days: [MonthlyCalendarDay], numberOfWeeks: Int) {
        self.numberOfWeeks = numberOfWeeks
        updateCollectionViewHeight()
        collectionView.collectionViewLayout.invalidateLayout()
        applySnapshot(days: days)
    }

    private func updateCollectionViewHeight() {
        let availableWidth = view.bounds.width - Constants.horizontalInset * 4
        let cellWidth = availableWidth / Constants.numberOfDaysInWeek

        let rowHeight = cellWidth + Constants.cellRowHeightPadding
        let totalHeight = rowHeight * CGFloat(numberOfWeeks)
        collectionViewHeightConstraint?.update(offset: totalHeight)
    }

    private func applySnapshot(days: [MonthlyCalendarDay]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MonthlyCalendarDay>()
        snapshot.appendSections([.calendar])
        snapshot.appendItems(days, toSection: .calendar)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func presentMonthPicker() {
        let picker = MonthPickerBottomSheetViewController(
            currentMonth: viewModel.state.currentDisplayDate
        )

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.custom { context in
                context.maximumDetentValue * Constants.monthPickerDetentRatio
            }]
        }
        
        picker.selectedMonthPublisher
            .sink { [weak self] date in
                self?.viewModel.input.send(.selectMonth(date))
            }.store(in: &monthPickerCancellables)
        
        picker.dismissPublisher
            .sink { [weak self] in
                self?.monthYearHeaderView.resetChevron()
                self?.monthPickerCancellables.removeAll()
            }.store(in: &monthPickerCancellables)

        present(picker, animated: true)
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let day = dataSource?.itemIdentifier(for: indexPath) else { return }
        viewModel.input.send(.selectDay(day.date))
    }

    // MARK: - Navigation

    private func navigateToDetail(date: Date, records: [FoodRecord]) {
        let detailVC = detailViewControllerFactory(date, records, nil, false) { [weak self] date in
            self?.viewModel.input.send(.updateMonth(date))
        }
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Constants

extension MonthlyCalendarViewController {
    enum Constants {
        static var horizontalInset: CGFloat { 20 }
        static var containerCornerRadius: CGFloat { 16 }
        static var containerBorderWidth: CGFloat { 1 }
        static var recordPromptTopOffset: CGFloat { 28 }
        static var monthYearHeaderTopOffset: CGFloat { 32 }
        static var containerTopOffset: CGFloat { 18 }
        static var containerBottomOffset: CGFloat { -38 }
        static var stackSpacing: CGFloat { 16 }
        static var stackTopInset: CGFloat { 24 }
        static var stackBottomInset: CGFloat { 18 }
        static var cellHorizontalSpacing: CGFloat { 1.5 }
        static var cellRowHeightPadding: CGFloat { 28 }
        static var numberOfDaysInWeek: CGFloat { 7 }
        static var monthPickerDetentRatio: CGFloat { 0.45 }
    }
}
