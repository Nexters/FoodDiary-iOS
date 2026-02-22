//
//  ToastView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

public final class ToastView: UIView {
    public enum ToastType {
        case infoUpdate
        case imageUploadComplete

        var message: String {
            switch self {
            case .infoUpdate:
                return "정보 수정을 완료했습니다."
            case .imageUploadComplete:
                return "AI가 기록을 완료했습니다."
            }
        }
        
        var image: UIImage {
            switch self {
            case .infoUpdate:
                return DesignSystemAsset.iconCom.image
            case .imageUploadComplete:
                return DesignSystemAsset.iconAi.image
            }
        }
    }

    private enum Constants {
        static let width: CGFloat = 330
        static let height: CGFloat = 65
        static let cornerRadius: CGFloat = 16
        static let iconSize: CGFloat = 20
        static let iconLeadingInset: CGFloat = 32
        static let labelLeadingSpacing: CGFloat = 10
    }
    
    // MARK: - UI Components

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Init

    private init(type: ToastType) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        configure(with: type)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientBorder(
            colors: [
                .white.withAlphaComponent(0.11),
                .white.withAlphaComponent(0),
                .white.withAlphaComponent(0.05)
            ],
            locations: [0.0, 0.33, 0.67],
            borderWidth: 1,
            cornerRadius: Constants.cornerRadius
        )
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = Constants.cornerRadius
        let overlay = UIView()
        overlay.backgroundColor = .gray750.withAlphaComponent(0.3)
        
        blurView.layer.cornerRadius = Constants.cornerRadius
        blurView.clipsToBounds = true
        
        blurView.contentView.addSubview(overlay)
        addSubview(blurView)
        addSubview(iconImageView)
        addSubview(messageLabel)
    }

    private func setupConstraints() {
        snp.makeConstraints {
            $0.height.equalTo(Constants.height)
        }

        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.iconLeadingInset)
            $0.size.equalTo(Constants.iconSize)
        }

        messageLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(iconImageView.snp.trailing).offset(Constants.labelLeadingSpacing)
            $0.trailing.equalToSuperview().offset(-Constants.iconLeadingInset)
        }
    }

    // MARK: - Configure

    private func configure(with type: ToastType) {
        iconImageView.image = type.image
        messageLabel.setText(type.message, style: .p15, color: .white)
    }

    // MARK: - Animation

    public static func show(type: ToastType) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let toast = ToastView(type: type)
        window.addSubview(toast)

        toast.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(Constants.height)
        }

        window.layoutIfNeeded()

        let targetOffsetY = -(Constants.height + 20 * 2)

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
            toast.transform = CGAffineTransform(translationX: 0, y: targetOffsetY)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0) {
                toast.alpha = 0
            } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
