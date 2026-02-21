//
//  OverlappingImageCardsView.swift
//  Presentation
//

import DesignSystem
import Kingfisher
import UIKit

/// 한 장 또는 겹쳐진 폴라로이드 스타일 이미지 카드 뷰
/// - 이미지가 1장이면 단일 카드, 2장 이상이면 겹쳐진 카드 레이아웃을 사용한다.
final class PolaroidImageCardsView: UIView {
    // MARK: - Constants

    private enum Constants {
        // 카드 크기 비율
        static let cardWidthRatio: CGFloat = 0.6
        static let cardHeightRatio: CGFloat = 0.8

        // 단일 카드 레이아웃
        static let singleCardCenterXRatio: CGFloat = 0.5
        static let singleCardCenterYRatio: CGFloat = 0.5
        static let singleCardRotationDegrees: CGFloat = 8

        // 겹쳐진 카드 레이아웃 - 뒷쪽 카드
        static let backCardCenterXRatio: CGFloat = 0.42
        static let backCardCenterYRatio: CGFloat = 0.5
        static let backCardRotationDegrees: CGFloat = -15

        // 겹쳐진 카드 레이아웃 - 앞쪽 카드
        static let frontCardCenterXRatio: CGFloat = 0.58
        static let frontCardCenterYRatio: CGFloat = 0.48
        static let frontCardRotationDegrees: CGFloat = 12
    }

    // MARK: - Properties

    private let backCardView = PolaroidCardView()
    private let frontCardView = PolaroidCardView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(backCardView)
        addSubview(frontCardView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cardSize = CGSize(
            width: bounds.width * Constants.cardWidthRatio,
            height: bounds.height * Constants.cardHeightRatio
        )

        if backCardView.isHidden {
            // 이미지가 1장일 때: 중앙에 단일 카드 배치 (회전 없이 똑바로)
            frontCardView.bounds = CGRect(origin: .zero, size: cardSize)
            frontCardView.center = CGPoint(
                x: bounds.width * Constants.singleCardCenterXRatio,
                y: bounds.height * Constants.singleCardCenterYRatio
            )
            frontCardView.transform = .identity
        } else {
            // 이미지가 2장 이상일 때: 겹쳐진 카드 배치
            // 뒷쪽 카드 위치 (왼쪽으로 치우침)
            backCardView.bounds = CGRect(origin: .zero, size: cardSize)
            backCardView.center = CGPoint(
                x: bounds.width * Constants.backCardCenterXRatio,
                y: bounds.height * Constants.backCardCenterYRatio
            )
            backCardView.transform = CGAffineTransform(
                rotationAngle: Constants.backCardRotationDegrees * .pi / 180
            )

            // 앞쪽 카드 위치 (오른쪽으로 치우침, 약간 위로)
            frontCardView.bounds = CGRect(origin: .zero, size: cardSize)
            frontCardView.center = CGPoint(
                x: bounds.width * Constants.frontCardCenterXRatio,
                y: bounds.height * Constants.frontCardCenterYRatio
            )
            frontCardView.transform = CGAffineTransform(
                rotationAngle: Constants.frontCardRotationDegrees * .pi / 180
            )
        }
    }

    // MARK: - Public Methods

    /// 단일 카드 이미지 설정
    /// - Parameter image: 표시할 이미지
    func configure(image: UIImage) {
        frontCardView.setImage(image)
        backCardView.isHidden = true
        setNeedsLayout()
    }

    /// 겹쳐진 카드 이미지 설정
    /// - Parameters:
    ///   - backImage: 뒷쪽 카드 이미지
    ///   - frontImage: 앞쪽 카드 이미지
    func configure(backImage: UIImage, frontImage: UIImage) {
        backCardView.setImage(backImage)
        frontCardView.setImage(frontImage)
        backCardView.isHidden = false
        setNeedsLayout()
    }

    /// URL로 단일 카드 이미지 설정 (Kingfisher)
    func configure(imageURL: URL) {
        frontCardView.setImage(with: imageURL)
        backCardView.isHidden = true
        setNeedsLayout()
    }

    /// URL로 겹쳐진 카드 이미지 설정 (Kingfisher)
    func configure(backImageURL: URL, frontImageURL: URL) {
        backCardView.setImage(with: backImageURL)
        frontCardView.setImage(with: frontImageURL)
        backCardView.isHidden = false
        setNeedsLayout()
    }
}

// MARK: - PolaroidCardView

/// 폴라로이드 스타일 카드 뷰 (흰색 테두리 + 이미지)
private final class PolaroidCardView: UIView {
    // MARK: - Constants

    private enum Constants {
        static let borderWidth: CGFloat = 1.5
        static let bottomBorderHeight: CGFloat = 1.5
        static let cornerRadius: CGFloat = 4
        static let imageCornerRadius: CGFloat = 2
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowRadius: CGFloat = 4
    }

    // MARK: - Properties

    private let imageView = UIImageView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // 흰색 카드 배경
        backgroundColor = .white
        layer.cornerRadius = Constants.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constants.shadowOpacity
        layer.shadowOffset = Constants.shadowOffset
        layer.shadowRadius = Constants.shadowRadius

        // 이미지뷰 설정
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.imageCornerRadius
        imageView.backgroundColor = DesignSystemAsset.gray200.color // 이미지 로딩 전 배경색
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 이미지는 상단과 좌우에 borderWidth만큼 여백, 하단에는 bottomBorderHeight만큼 여백
        let imageFrame = CGRect(
            x: Constants.borderWidth,
            y: Constants.borderWidth,
            width: bounds.width - (Constants.borderWidth * 2),
            height: bounds.height - Constants.borderWidth - Constants.bottomBorderHeight
        )

        imageView.frame = imageFrame
    }

    // MARK: - Public Methods

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    func setImage(with url: URL) {
        imageView.kf.setImage(
            with: url,
            placeholder: DesignSystemAsset.foodPlaceholder.image
        )
    }
}
