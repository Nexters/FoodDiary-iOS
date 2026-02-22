//
//  CoachmarkOverlayView.swift
//  Presentation
//

import UIKit
import Combine
import SnapKit
import DesignSystem

public final class CoachmarkOverlayView: UIView {
    private let didDismissSubject = PassthroughSubject<Void, Never>()

    public var didDismissPublisher: AnyPublisher<Void, Never> {
        didDismissSubject.eraseToAnyPublisher()
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: DesignSystemAsset.coachmarkOverlay.image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    public init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        setupImageView()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CoachmarkOverlayView {
    func setupImageView() {
        addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc func handleTap() {
        didDismissSubject.send()
    }
}
