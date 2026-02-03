//
//  MonthPickerBottomSheetViewController.swift
//  Presentation
//

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

    private let months: [Date]
    private let currentMonth: Date

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()

    // MARK: - Init

    init(currentMonth: Date) {
        self.currentMonth = currentMonth
        self.months = Self.generateMonths()
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
        setupTableView()
        scrollToCurrentMonth()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MonthPickerCell.self, forCellReuseIdentifier: MonthPickerCell.reuseIdentifier)
    }

    private func scrollToCurrentMonth() {
        let calendar = Calendar.current
        guard let index = months.firstIndex(where: {
            calendar.isDate($0, equalTo: currentMonth, toGranularity: .month)
        }) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(
                at: IndexPath(row: index, section: 0),
                at: .middle,
                animated: false
            )
        }
    }

    // MARK: - Month Generation

    private static func generateMonths() -> [Date] {
        let calendar = Calendar.current
        let today = Date()

        guard let startOfCurrentMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: today)
        ) else { return [] }

        var months: [Date] = []
        for i in 0..<24 {
            if let date = calendar.date(byAdding: .month, value: -i, to: startOfCurrentMonth) {
                months.append(date)
            }
        }
        return months
    }
}

// MARK: - UITableViewDataSource

extension MonthPickerBottomSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        months.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MonthPickerCell.reuseIdentifier,
            for: indexPath
        ) as! MonthPickerCell

        let month = months[indexPath.row]
        let calendar = Calendar.current
        let isSelected = calendar.isDate(month, equalTo: currentMonth, toGranularity: .month)
        cell.configure(with: month, isSelected: isSelected)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MonthPickerBottomSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let month = months[indexPath.row]
        selectedMonthSubject.send(month)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }
}

// MARK: - MonthPickerCell

private final class MonthPickerCell: UITableViewCell {

    static let reuseIdentifier = "MonthPickerCell"

    private let monthLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(monthLabel)
        monthLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(with date: Date, isSelected: Bool) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        let text = formatter.string(from: date)

        let color: UIColor = isSelected ? DesignSystemAsset.primary.color : .white
        monthLabel.setText(text, style: .hd18, color: color)
    }
}
