import Combine
import DesignSystem
import SnapKit
import UIKit

final class MonthPickerBottomSheetViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let closeButtonTopInset: CGFloat = 20
        static let closeButtonTrailingInset: CGFloat = 20
        static let closeButtonSize: CGFloat = 44

        static let pickerTopOffset: CGFloat = 10
        static let pickerHorizontalInset: CGFloat = 18
        static let pickerBottomOffset: CGFloat = 32

        static let selectButtonHorizontalInset: CGFloat = 18
        static let selectButtonBottomInset: CGFloat = 40
        static let selectButtonHeight: CGFloat = 47
        static let selectButtonCornerRadius: CGFloat = 28

        static let pickerLabelFontSize: CGFloat = 18
        static let pickerRowHeight: CGFloat = 40
        static let yearRange: Int = 10
    }

    // MARK: - Publishers

    private let selectedMonthSubject = PassthroughSubject<Date, Never>()
    
    var selectedMonthPublisher: AnyPublisher<Date, Never> {
        selectedMonthSubject.eraseToAnyPublisher()
    }
    
    private let dismissSubject = PassthroughSubject<Void, Never>()
    
    var dismissPublisher: AnyPublisher<Void, Never> {
        dismissSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties

    private let currentMonth: Date
    private let years: [Int]
    private let currentYear: Int
    private let currentMonthNumber: Int
    private var selectedYear: Int
    private var selectedMonth: Int

    // MARK: - UI Components

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private let pickerView = UIPickerView()

    private lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: Constants.pickerLabelFontSize, weight: .semibold)
        button.backgroundColor = DesignSystemAsset.primary.color
        button.layer.cornerRadius = Constants.selectButtonCornerRadius
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(currentMonth: Date) {
        let calendar = Calendar.seoul
        let today = Date()

        self.currentMonth = currentMonth
        self.currentYear = calendar.component(.year, from: today)
        self.currentMonthNumber = calendar.component(.month, from: today)

        self.selectedYear = calendar.component(.year, from: currentMonth)
        self.selectedMonth = calendar.component(.month, from: currentMonth)

        self.years = Array((currentYear - Constants.yearRange)...currentYear)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupPickerView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissSubject.send()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(closeButton)
        view.addSubview(pickerView)
        view.addSubview(selectButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.closeButtonTopInset)
            $0.trailing.equalToSuperview().inset(Constants.closeButtonTrailingInset)
            $0.width.height.equalTo(Constants.closeButtonSize)
        }

        selectButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.selectButtonHorizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(Constants.selectButtonBottomInset)
            $0.height.equalTo(Constants.selectButtonHeight)
        }

        pickerView.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(Constants.pickerTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.pickerHorizontalInset)
            $0.bottom.equalTo(selectButton.snp.top).offset(-Constants.pickerBottomOffset)
        }
    }

    private func setupPickerView() {
        pickerView.dataSource = self
        pickerView.delegate = self

        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        }
        pickerView.selectRow(selectedMonth - 1, inComponent: 1, animated: false)
    }

    /// 선택된 연도에 따라 사용 가능한 월 배열 반환
    private func availableMonths(for year: Int) -> [Int] {
        if year == currentYear {
            return Array(1...currentMonthNumber)
        } else {
            return Array(1...12)
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func selectButtonTapped() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1

        if let date = Calendar.current.date(from: components) {
            selectedMonthSubject.send(date)
        }
        dismiss(animated: true)
    }
}

// MARK: - UIPickerViewDataSource

extension MonthPickerBottomSheetViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return years.count
        } else {
            return availableMonths(for: selectedYear).count
        }
    }
}

// MARK: - UIPickerViewDelegate

extension MonthPickerBottomSheetViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedYear = years[row]

            // 현재 연도 선택 시 월 컴포넌트 리로드
            let availableMonths = availableMonths(for: selectedYear)
            pickerView.reloadComponent(1)

            // 선택된 월이 사용 가능한 범위를 벗어나면 마지막 월로 조정
            if selectedMonth > availableMonths.count {
                selectedMonth = availableMonths.count
                pickerView.selectRow(selectedMonth - 1, inComponent: 1, animated: true)
            }
        } else {
            let availableMonths = availableMonths(for: selectedYear)
            selectedMonth = availableMonths[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: Constants.pickerLabelFontSize, weight: .regular)
        label.textColor = .white

        if component == 0 {
            label.text = "\(years[row])년"
        } else {
            let availableMonths = availableMonths(for: selectedYear)
            label.text = "\(availableMonths[row])월"
        }

        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return Constants.pickerRowHeight
    }
}
