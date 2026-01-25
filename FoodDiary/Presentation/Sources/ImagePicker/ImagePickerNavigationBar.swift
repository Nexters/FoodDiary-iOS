//
//  ImagePickerNavigationBar.swift
//  Presentation
//

import Combine
import SnapKit
import UIKit

/// 이미지 피커 커스텀 네비게이션 바
final class ImagePickerNavigationBar: UIView {
    // MARK: - Publisher

    var closeTapPublisher: AnyPublisher<Void, Never> {
        closeTapSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let closeTapSubject = PassthroughSubject<Void, Never>()

    // MARK: - UI Components

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        closeTapSubject.send()
    }
}
