//
//  MonthlyCalendarViewController.swift
//  Presentation
//

import Combine
import Data
import DesignSystem
import Domain
import Kingfisher
import SnapKit
import StoreKit
import UIKit

public final class MonthlyCalendarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private enum Section: Hashable {
        case calendar
    }

    // MARK: - Dependencies

    private let viewModel: MonthlyCalendarViewModel

    // MARK: - Flow

    private let flowSubject = PassthroughSubject<CalendarFlow, Never>()
    public var flowPublisher: AnyPublisher<CalendarFlow, Never> {
        flowSubject.eraseToAnyPublisher()
    }

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let monthYearHeaderView = MonthlyCalendarHeaderView()
    private let weekdayHeaderView = WeekdayHeaderView()
    private let progressView = MonthlyRecordProgressView()
    private let selectedDateLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let mealSummaryView = SelectedDayMealSummaryView()

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
    private var collectionViewHeightConstraint: Constraint?

    // MARK: - Init

    public init(
        viewModel: MonthlyCalendarViewModel
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
        view.layoutIfNeeded()
        updateCollectionViewItemSize()
        updateCollectionViewHeight()
    }


    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(monthYearHeaderView)
        contentView.addSubview(stackView)
        contentView.addSubview(progressView)
        contentView.addSubview(selectedDateLabel)
        contentView.addSubview(detailButton)
        contentView.addSubview(mealSummaryView)

        setupSwipeGestures()
        setupDetailButton()

        let mypageButton = UIBarButtonItem(
            image: DesignSystemAsset.iconMypage.image,
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItem = mypageButton
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        monthYearHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.monthYearHeaderTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(monthYearHeaderView.snp.bottom).offset(Constants.containerTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        collectionView.snp.makeConstraints {
            collectionViewHeightConstraint = $0.height.equalTo(0).constraint
        }

        progressView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom).offset(Constants.progressTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(Constants.progressHeight)
        }

        selectedDateLabel.snp.makeConstraints {
            $0.top.equalTo(progressView.snp.bottom).offset(Constants.selectedDateTopOffset)
            $0.leading.equalToSuperview().inset(Constants.horizontalInset)
        }

        detailButton.snp.makeConstraints {
            $0.centerY.equalTo(selectedDateLabel)
            $0.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        mealSummaryView.snp.makeConstraints {
            $0.top.equalTo(selectedDateLabel.snp.bottom).offset(Constants.summaryTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.height.equalTo(Constants.summaryHeight)
            $0.bottom.equalToSuperview().inset(24)
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

            cell.configure(with: day, selectedDate: self.viewModel.state.selectedDate)
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

        monthYearHeaderView.todayTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.selectMonth(Date()))
            }
            .store(in: &cancellables)

        // Output: ViewModel → View
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
                self?.collectionView.reloadData()
                self?.updateSelectedDate(state.selectedDate)
                self?.progressView.configure(recordCount: state.monthRecordCount, totalCount: state.monthDayCount)
                self?.mealSummaryView.configure(
                    records: state.selectedRecords,
                    processingRecords: state.processingRecords,
                    hasFoodPhotos: state.hasFoodPhotos
                )
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
                case .photoAuthorizationDenied:
                    self?.showPhotoAuthorizationDeniedAlert()
                case .uploadCompleted(let date, let mealType):
                    self?.navigateToDetail(date: date, records: self?.viewModel.state.selectedRecords ?? [], scrollTo: mealType, shouldPopToRoot: true)
                case .saveFailed(let error):
                    self?.showSaveErrorAlert(error)
                case .requestAppReview:
                    self?.requestAppReview()
                }
            }
            .store(in: &cancellables)

        mealSummaryView.tapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.navigateToSelectedDateDetail)
            }
            .store(in: &cancellables)
    }

    private func setupSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    private func setupDetailButton() {
        let attributedTitle = NSMutableAttributedString(
            attributedString: Typography.p12.styled("기록보기", color: .detailPrimaryText)
        )
        attributedTitle.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: attributedTitle.length)
        )
        detailButton.setAttributedTitle(attributedTitle, for: .normal)
        detailButton.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let calendar = Calendar.current
        let offset = gesture.direction == .left ? 1 : -1
        guard let newDate = calendar.date(
            byAdding: .month,
            value: offset,
            to: viewModel.state.currentDisplayDate
        ) else { return }
        viewModel.input.send(.selectMonth(newDate))
    }

    // MARK: - Private Methods

    private func updateCalendar(days: [MonthlyCalendarDay], numberOfWeeks: Int) {
        updateCollectionViewHeight()
        collectionView.collectionViewLayout.invalidateLayout()
        applySnapshot(days: days)
    }

    private func updateCollectionViewHeight() {
        let itemSide = calendarItemSide()
        let totalSpacing = Constants.lineSpacing * CGFloat(max(viewModel.state.numberOfWeeks - 1, 0))
        let totalHeight = itemSide * CGFloat(viewModel.state.numberOfWeeks) + totalSpacing
        collectionViewHeightConstraint?.update(offset: totalHeight)
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Constants.interItemSpacing
        layout.minimumLineSpacing = Constants.lineSpacing
        layout.sectionInset = .zero
        layout.estimatedItemSize = .zero
        return layout
    }

    private func updateCollectionViewItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let side = calendarItemSide()
        let itemSize = CGSize(width: side, height: side)
        guard layout.itemSize != itemSize else { return }
        layout.itemSize = itemSize
        layout.invalidateLayout()
    }

    private func calendarItemSide() -> CGFloat {
        let width = view.bounds.width - (Constants.horizontalInset * 2)
        let totalSpacing = Constants.interItemSpacing * CGFloat(Constants.numberOfDaysInWeek - 1)
        let availableWidth = max(0, width - totalSpacing)
        return floor(availableWidth / Constants.numberOfDaysInWeek)
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

    private func updateSelectedDate(_ date: Date) {
        selectedDateLabel.setText("\(Calendar.current.component(.day, from: date))일", style: .p18, color: .detailSectionText)
    }

    @objc private func detailButtonTapped() {
        viewModel.input.send(.navigateToSelectedDateDetail)
    }

    public func addFoodRecord() {
        flowSubject.send(.pushImagePicker(
            ImagePickerSceneInput(date: viewModel.state.selectedDate) { [weak self] assets in
                self?.viewModel.input.send(.saveSelectedPhotos(assets))
            }
        ))
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let day = dataSource?.itemIdentifier(for: indexPath) else { return }
        viewModel.input.send(.selectDay(day.date))
    }

    // MARK: - Navigation

    private func navigateToDetail(
        date: Date,
        records: [FoodRecord],
        scrollTo mealType: MealType? = nil,
        shouldPopToRoot: Bool = false
    ) {
        let input = DetailSceneInput(
            date: date,
            records: records,
            scrollToMealType: mealType,
            shouldPopToRoot: shouldPopToRoot,
            onDismissWithDate: { [weak self] date in
                self?.viewModel.input.send(.updateMonth(date))
            }
        )
        flowSubject.send(.pushDetail(input))
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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

    private func showSaveErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "저장 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func requestAppReview() {
        guard let windowScene = view.window?.windowScene else { return }
        AppStore.requestReview(in: windowScene)
    }
}


// MARK: - Constants

extension MonthlyCalendarViewController {
    enum Constants {
        static var horizontalInset: CGFloat { 15 }
        static var monthYearHeaderTopOffset: CGFloat { 14 }
        static var containerTopOffset: CGFloat { 14 }
        static var stackSpacing: CGFloat { 12 }
        static var interItemSpacing: CGFloat { 6 }
        static var lineSpacing: CGFloat { 4 }
        static var progressTopOffset: CGFloat { 24 }
        static var progressHeight: CGFloat { 36 }
        static var selectedDateTopOffset: CGFloat { 34 }
        static var summaryTopOffset: CGFloat { 12 }
        static var summaryHeight: CGFloat { 264 }
        static var numberOfDaysInWeek: CGFloat { 7 }
        static var monthPickerDetentRatio: CGFloat { 0.45 }
    }
}

private final class MonthlyRecordProgressView: UIView {
    private let fillView = UIView()
    private let fillGradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private var fillWidthConstraint: Constraint?
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillGradientLayer.frame = fillView.bounds
        fillGradientLayer.cornerRadius = fillView.layer.cornerRadius
        updateFillWidth()
    }

    func configure(recordCount: Int, totalCount: Int) {
        let safeTotal = max(totalCount, 1)
        progress = min(1, CGFloat(recordCount) / CGFloat(safeTotal))
        titleLabel.setText("이번달 기록", style: .p12, color: .white)
        countLabel.attributedText = progressCountText(recordCount: recordCount, totalCount: totalCount)
        updateFillWidth()
    }

    private func setupUI() {
        backgroundColor = UIColor.primary.withAlphaComponent(0.2)
        layer.cornerRadius = 18
        clipsToBounds = true
        fillView.layer.cornerRadius = 18
        fillView.clipsToBounds = true
        fillGradientLayer.colors = [
            UIColor.primaryLight.cgColor,
            UIColor.primary.cgColor
        ]
        fillGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        fillGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        fillView.layer.insertSublayer(fillGradientLayer, at: 0)
        addSubview(fillView)
        addSubview(titleLabel)
        addSubview(countLabel)
    }

    private func setupConstraints() {
        fillView.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            fillWidthConstraint = $0.width.equalTo(0).constraint
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    private func updateFillWidth() {
        fillWidthConstraint?.update(offset: max(36, bounds.width * progress))
    }

    private func progressCountText(recordCount: Int, totalCount: Int) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: "\(recordCount)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.primary
            ]
        )
        attributed.append(
            NSAttributedString(
                string: "/\(totalCount)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.primary.withAlphaComponent(0.75)
                ]
            )
        )
        return attributed
    }
}

private final class SelectedDayMealSummaryView: UIView {
    private struct MealRowConfiguration {
        let mealType: MealType
        let title: String
        let subtitle: String
    }

    private let tapSubject = PassthroughSubject<Void, Never>()
    var tapPublisher: AnyPublisher<Void, Never> {
        tapSubject.eraseToAnyPublisher()
    }

    private let stackView = UIStackView()
    private let mealRowConfigurations: [MealRowConfiguration] = [
        MealRowConfiguration(mealType: .breakfast, title: "아침", subtitle: "오전 5시 ~ 오전 10시"),
        MealRowConfiguration(mealType: .lunch, title: "점심", subtitle: "오전 11시 ~ 오후 3시"),
        MealRowConfiguration(mealType: .dinner, title: "저녁", subtitle: "오후 4시 ~ 오후 8시"),
        MealRowConfiguration(mealType: .snack, title: "야식", subtitle: "오후 9시 ~ 오전 4시")
    ]
    private lazy var rows: [MealRowView] = mealRowConfigurations.map {
        MealRowView(title: $0.title, subtitle: $0.subtitle)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(records: [FoodRecord], processingRecords: [FoodRecord], hasFoodPhotos: Bool) {
        let allRecords = records + processingRecords
        for (configuration, row) in zip(mealRowConfigurations, rows) {
            let imageURLs = imageURLs(in: allRecords, for: configuration.mealType)
            row.configure(
                imageURLs: imageURLs,
                showsPlaceholder: imageURLs.isEmpty || (configuration.mealType == .dinner && !hasFoodPhotos)
            )
        }
    }

    private func setupUI() {
        backgroundColor = .calendarTileBackground
        layer.cornerRadius = 10
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        rows.enumerated().forEach { index, row in
            stackView.addArrangedSubview(row)
            row.showsSeparator = index < rows.count - 1
        }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
    }

    private func imageURLs(in records: [FoodRecord], for mealType: MealType) -> [URL] {
        records
            .filter { $0.mealType == mealType }
            .flatMap(\.imageURLs)
    }

    @objc private func didTap() {
        tapSubject.send()
    }
}

private final class MealRowView: UIView {
    var showsSeparator: Bool = true {
        didSet { separatorView.isHidden = !showsSeparator }
    }

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let imageStackView = MealImageStackView()
    private let separatorView = UIView()
    private let title: String
    private let subtitle: String

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imageURLs: [URL], showsPlaceholder: Bool) {
        imageStackView.configure(imageURLs: imageURLs, showsPlaceholder: showsPlaceholder)
    }

    private func setupUI() {
        titleLabel.setText(title, style: .p12, color: UIColor(red: 0.157, green: 0.157, blue: 0.157, alpha: 1))
        subtitleLabel.setText(subtitle, style: .p10, color: UIColor(red: 0.235, green: 0.235, blue: 0.235, alpha: 1))
        separatorView.backgroundColor = .gray200
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(imageStackView)
        addSubview(separatorView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-12)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        imageStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(60)
            $0.height.equalTo(42)
        }
        separatorView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}

private final class MealImageStackView: UIView {
    private let placeholderView = UIImageView()
    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlaceholder()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(imageURLs: [URL], showsPlaceholder: Bool) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        placeholderView.isHidden = !imageURLs.isEmpty || !showsPlaceholder

        for (index, url) in imageURLs.prefix(3).enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
            imageView.layer.borderWidth = 1.5
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.kf.setImage(with: url)
            insertSubview(imageView, belowSubview: placeholderView)
            imageView.snp.makeConstraints {
                $0.width.height.equalTo(42)
                $0.centerY.equalToSuperview()
                $0.trailing.equalToSuperview().offset(CGFloat(index) * -17)
            }
            imageViews.append(imageView)
        }
    }

    private func setupPlaceholder() {
        placeholderView.image = DesignSystemAsset.calendarEmptyMeal.image
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.layer.cornerRadius = 10
        placeholderView.isHidden = true
        addSubview(placeholderView)
        placeholderView.snp.makeConstraints {
            $0.width.height.equalTo(42)
            $0.trailing.centerY.equalToSuperview()
        }
    }
}
