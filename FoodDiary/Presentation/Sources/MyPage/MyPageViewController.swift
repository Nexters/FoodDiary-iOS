//
//  MyPageViewController.swift
//  Presentation
//
//  Created by 강대훈 on 2/19/26.
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

public final class MyPageViewController: UIViewController {

    // MARK: - Types

    private enum Section: Int, CaseIterable {
        case notifications
        case management
        case logout

        var headerIcon: UIImage? {
            switch self {
            case .notifications: return DesignSystemAsset.iconAlert.image
            case .management: return DesignSystemAsset.iconSetting.image
            case .logout: return nil
            }
        }

        var headerTitle: String? {
            switch self {
            case .notifications: return "알림"
            case .management: return "관리"
            case .logout: return " "
            }
        }

        var rows: [Row] {
            switch self {
            case .notifications: return [.notificationSetting]
            case .management: return [.appVersion, .terms, .privacy]
            case .logout: return [.logout]
            }
        }
    }

    private enum Row {
        case notificationSetting
        case appVersion
        case terms
        case privacy
        case logout
    }

    // MARK: - Output

    public var didLogoutPublisher: AnyPublisher<Void, Never> {
        viewModel.eventPublisher
            .compactMap { event -> Void? in
                switch event {
                case .didLogout, .didWithdraw: return ()
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let viewModel: MyPageViewModel

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .sdBase
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var profileHeaderView: ProfileHeaderView = {
        let header = ProfileHeaderView()
        return header
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .sdBase
        tv.showsVerticalScrollIndicator = false
        tv.separatorColor = .clear
        tv.isScrollEnabled = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private var tableViewHeightConstraint: Constraint?

    // MARK: - Init

    public init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupConstraints()
        setupTableFooter()
        setupBindings()
        setupNotifications()
        viewModel.input.send(.viewDidLoad)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableViewHeight()
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "마이페이지"
        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .sd700
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupUI() {
        view.backgroundColor = .sdBase
        view.addSubview(scrollView)
        scrollView.addSubview(profileHeaderView)
        scrollView.addSubview(tableView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        profileHeaderView.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide)
            $0.leading.trailing.equalTo(scrollView.frameLayoutGuide)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(profileHeaderView.snp.bottom).offset(30)
            $0.leading.trailing.equalTo(scrollView.frameLayoutGuide)
            $0.bottom.equalTo(scrollView.contentLayoutGuide)
            tableViewHeightConstraint = $0.height.equalTo(0).constraint
        }
    }

    private func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        let height = tableView.contentSize.height
        tableViewHeightConstraint?.update(offset: height)
    }

    private func setupTableFooter() {
        let footer = WithdrawalFooterView()
        footer.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44)
        footer.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(withdrawalTapped))
        footer.addGestureRecognizer(tapGesture)

        tableView.tableFooterView = footer
    }

    @objc private func withdrawalTapped() {
        showWithdrawalAlert()
    }

    private func showWithdrawalAlert() {
        let alert = UIAlertController(
            title: "회원탈퇴",
            message: "탈퇴를 진행하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { [weak self] _ in
            self?.viewModel.input.send(.withdraw)
        })
        present(alert, animated: true)
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .map(\.isNotificationEnabled)
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }
                let indexPath = IndexPath(row: 0, section: Section.notifications.rawValue)
                if let cell = tableView.cellForRow(at: indexPath),
                   let badge = cell.contentView.viewWithTag(999) as? UILabel {
                    badge.text = isEnabled ? "ON" : "OFF"
                    badge.backgroundColor = isEnabled ? DesignSystemAsset.primary.color : DesignSystemAsset.gray600.color
                } else {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            .store(in: &cancellables)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground() {
        viewModel.input.send(.updateNotificationSetting)
    }

    // MARK: - Cell Configuration

    private func configureCell(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        var backgroundConfig = UIBackgroundConfiguration.listCell()
        backgroundConfig.backgroundColor = .sd700
        cell.backgroundConfiguration = backgroundConfig
        cell.selectionStyle = .none
        cell.contentConfiguration = nil

        switch row {
        case .notificationSetting:
            cell.textLabel?.setText("알림설정", style: .p14, color: .gray050)
            cell.accessoryView = makeChevronAccessory()

            // 기존 배지 제거 (재사용 대비)
            cell.contentView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

            // 텍스트 너비 계산
            let text = "알림설정"
            let font = UIFont.systemFont(ofSize: 14)
            let textWidth = (text as NSString).size(withAttributes: [.font: font]).width

            // 알림 권한 상태에 따라 배지 텍스트/색상 결정
            let isEnabled = viewModel.state.isNotificationEnabled
            let badgeText = isEnabled ? "ON" : "OFF"
            let badgeColor = isEnabled ? DesignSystemAsset.primary.color : DesignSystemAsset.gray600.color

            let badge = makeBadgeLabel(text: badgeText, backgroundColor: badgeColor)
            badge.tag = 999
            badge.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(badge)

            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor, constant: textWidth + 4),
                badge.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                badge.widthAnchor.constraint(equalToConstant: 36),
                badge.heightAnchor.constraint(equalToConstant: 20)
            ])

        case .appVersion:
            cell.textLabel?.setText("앱 버전", style: .p14, color: .gray050)
            cell.detailTextLabel?.setText("1.0", style: .p14, color: .gray400)
            cell.accessoryView = nil

        case .terms:
            cell.textLabel?.setText("서비스 이용약관", style: .p14, color: .gray050)
            cell.accessoryView = makeChevronAccessory()

        case .privacy:
            cell.textLabel?.setText("개인정보 처리방침", style: .p14, color: .gray050)
            cell.accessoryView = makeChevronAccessory()

        case .logout:
            cell.textLabel?.setText("로그아웃", style: .p14, color: .gray050)
            cell.accessoryView = makeLogoutIconAccessory()
        }
    }

    // MARK: - Accessory Factories

    private func makeChevronAccessory() -> UIImageView {
        let iv = UIImageView(image: DesignSystemAsset.iconNext.image)
        return iv
    }

    private func makeLogoutIconAccessory() -> UIImageView {
        let iv = UIImageView(image: DesignSystemAsset.iconLogout.image)
        return iv
    }

    private func makeBadgeLabel(text: String, backgroundColor: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = backgroundColor
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }
}

// MARK: - UITableViewDataSource

extension MyPageViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section)?.rows.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let row = Section(rawValue: indexPath.section)?.rows[indexPath.row] else { return cell }
        configureCell(cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MyPageViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sec = Section(rawValue: section),
              let title = sec.headerTitle else {
            return nil
        }

        let headerView = UIView()
        headerView.backgroundColor = .clear

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center

        if let icon = sec.headerIcon {
            let iconImageView = UIImageView(image: icon)
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.tintColor = .gray400
            iconImageView.snp.makeConstraints {
                $0.size.equalTo(18)
            }
            stackView.addArrangedSubview(iconImageView)
        }

        let label = UILabel()
        label.setText(title, style: .p12, color: .gray050)
        stackView.addArrangedSubview(label)

        headerView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
        }

        return headerView
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section),
              let title = sec.headerTitle, title != " " else { return 32 }
        return 44
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Section(rawValue: indexPath.section)?.rows[indexPath.row] else { return }

        switch row {
        case .notificationSetting:
            openAppSettings()
        case .logout:
            showLogoutAlert()
        default:
            break
        }
    }

    // MARK: - Actions

    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "로그아웃",
            message: "로그아웃을 진행하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            self?.viewModel.input.send(.logout)
        })
        present(alert, animated: true)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}



