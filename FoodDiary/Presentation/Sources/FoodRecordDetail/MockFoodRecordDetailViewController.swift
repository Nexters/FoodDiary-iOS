import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

public final class MockFoodRecordDetailViewController: UIViewController {

    // MARK: - Properties

    private let records: [FoodRecord]
    private let date: Date

    // MARK: - UI Components

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    public init(records: [FoodRecord], date: Date) {
        self.records = records
        self.date = date
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
        configureContent()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(closeButton)
        view.addSubview(dateLabel)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(44)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }

    private func configureContent() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        let dateText = formatter.string(from: date)

        dateLabel.setText(dateText, style: .hd20, color: .white)

        // TODO: FoodRecord 표시 UI 구현
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
