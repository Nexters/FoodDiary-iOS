//
//  PermissionViewController.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 권한 요청 화면
public final class PermissionViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .left
        label.setText("앱 사용을 위해\n접근 권한을 허용해주세요", style: .hd18, lineSpacing: 6)
        label.textColor = DesignSystemAsset.gray850.color
        return label
    }()

    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.setText("필수적 접근 권한", style: .p14)
        label.textColor = DesignSystemAsset.gray600.color
        return label
    }()

    private let permissionCardView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystemAsset.gray040.color
        view.layer.cornerRadius = 16
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        return view
    }()

    private let permissionIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = DesignSystemAsset.iconPermissionPhoto.image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let permissionNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = DesignSystemAsset.gray850.color
        label.setText("사진", style: .p15)
        return label
    }()

    private let permissionDescriptionLabel: UILabel = {
        let label = UILabel()
        label.setText("기록 시 사진 사용", style: .p15)
        label.textColor = DesignSystemAsset.gray600.color
        return label
    }()

    private let warningLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.setText("권한 허용이 되지 않는다면 앱을 사용할 수 없습니다.", style: .p12)
        label.textColor = DesignSystemAsset.gray600.color
        return label
    }()

    private let settingsButton: MumukPrimaryButton = {
        let button = MumukPrimaryButton()
        button.configure(title: "동의하고 시작하기")
        return button
    }()

    // MARK: - Init

    public init() {
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
        setupAction()
    }
}

// MARK: - Setup

private extension PermissionViewController {
    func setupUI() {
        view.backgroundColor = DesignSystemAsset.white.color

        view.addSubview(titleLabel)
        view.addSubview(sectionLabel)
        view.addSubview(permissionCardView)
        view.addSubview(warningLabel)
        view.addSubview(settingsButton)

        permissionCardView.addSubview(iconContainerView)
        iconContainerView.addSubview(permissionIconImageView)
        permissionCardView.addSubview(permissionNameLabel)
        permissionCardView.addSubview(permissionDescriptionLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        sectionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.leading.equalToSuperview().inset(24)
        }

        permissionCardView.snp.makeConstraints {
            $0.top.equalTo(sectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(72)
        }

        iconContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        permissionIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }

        permissionNameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainerView.snp.trailing).offset(2)
            $0.centerY.equalToSuperview()
        }

        permissionDescriptionLabel.snp.makeConstraints {
            $0.leading.equalTo(permissionNameLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        warningLabel.snp.makeConstraints {
            $0.top.equalTo(permissionCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        settingsButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(56)
        }
    }

    func setupAction() {
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
    }

    @objc func didTapSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
