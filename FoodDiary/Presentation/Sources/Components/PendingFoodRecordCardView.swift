//
//  PendingFoodRecordCardView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 분석 대기 중인 음식 기록 카드 뷰
public final class PendingFoodRecordCardView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 4
        static let pendingIconSize: CGFloat = 140
        static let pendingLabelTopSpacing: CGFloat = 24
    }

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderWidth = Constants.borderWidth
        view.layer.borderColor = UIColor.white.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    private let pendingIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.pending.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let pendingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = Constants.pendingLabelTopSpacing
        return sv
    }()

    // MARK: - Init

    public init(record: PendingFoodRecord) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        pendingLabel.setText(
            "귀찮은 입력은 AI가 대신하고 있어요..",
            style: .p14,
            color: .gray050
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.updateGradientFrame()
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(backgroundImageView)
        containerView.addSubview(dimView)
        containerView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(pendingIconView)
        contentStackView.addArrangedSubview(pendingLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        dimView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().offset(-8)
        }

        pendingIconView.snp.makeConstraints {
            $0.size.equalTo(Constants.pendingIconSize)
        }
    }

    // MARK: - Public Methods

    public func configure(image: UIImage?) {
        guard let image else {
            backgroundImageView.image = nil
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let blurred = Self.applyGaussianBlur(to: image, radius: 30)
            DispatchQueue.main.async { self?.backgroundImageView.image = blurred }
        }
    }

    private static func applyGaussianBlur(to image: UIImage, radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image),
            let filter = CIFilter(name: "CIGaussianBlur")
        else { return image }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return image }
        // 블러 적용 시 이미지 경계가 확장되므로 원본 크기로 크롭
        let cropped = output.cropped(to: ciImage.extent)
        let context = CIContext()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

}
