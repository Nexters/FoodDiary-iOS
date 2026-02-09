import Combine
import DesignSystem
import SnapKit
import UIKit

final class MonthPickerBottomSheetViewController: UIViewController {

    // MARK: - Publishers

    private let selectedMonthSubject = PassthroughSubject<Date, Never>()
    var selectedMonthPublisher: AnyPublisher<Date, Never> {
        selectedMonthSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties

    private let currentMonth: Date
    private let years: [Int]
    private let months = Array(1...12)
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
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = DesignSystemAsset.primary.color
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(currentMonth: Date) {
        self.currentMonth = currentMonth
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentMonth)
        self.selectedYear = currentYear
        self.selectedMonth = calendar.component(.month, from: currentMonth)
        self.years = Array((currentYear - 10)...(currentYear + 10))
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

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(closeButton)
        view.addSubview(pickerView)
        view.addSubview(selectButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(44)
        }

        selectButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            $0.height.equalTo(47)
        }

        pickerView.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalTo(selectButton.snp.top).offset(-32)
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
        2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? years.count : months.count
    }
}

// MARK: - UIPickerViewDelegate

extension MonthPickerBottomSheetViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedYear = years[row]
        } else {
            selectedMonth = months[row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .white
        label.text = component == 0 ? "\(years[row])년" : "\(months[row])월"
        return label
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        40
    }
}
