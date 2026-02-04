//
//  OverlappingImageCardsView.swift
//  Presentation
//

import DesignSystem
import UIKit

/// 한 장 또는 겹쳐진 폴라로이드 스타일 이미지 카드 뷰
/// - 이미지가 1장이면 단일 카드, 2장 이상이면 겹쳐진 카드 레이아웃을 사용한다.
final class PolaroidImageCardsView: UIView {
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
            width: bounds.width * 0.6,
            height: bounds.height * 0.8
        )

        if backCardView.isHidden {
            // 이미지가 1장일 때: 중앙에 단일 카드 배치
            frontCardView.bounds = CGRect(origin: .zero, size: cardSize)
            frontCardView.center = CGPoint(
                x: bounds.width * 0.5,
                y: bounds.height * 0.5
            )
            frontCardView.transform = CGAffineTransform(rotationAngle: 8 * .pi / 180)
        } else {
            // 이미지가 2장 이상일 때: 겹쳐진 카드 배치
            // 뒷쪽 카드 위치 (왼쪽으로 치우침)
            backCardView.bounds = CGRect(origin: .zero, size: cardSize)
            backCardView.center = CGPoint(
                x: bounds.width * 0.42,
                y: bounds.height * 0.5
            )
            backCardView.transform = CGAffineTransform(rotationAngle: -15 * .pi / 180)

            // 앞쪽 카드 위치 (오른쪽으로 치우침, 약간 위로)
            frontCardView.bounds = CGRect(origin: .zero, size: cardSize)
            frontCardView.center = CGPoint(
                x: bounds.width * 0.58,
                y: bounds.height * 0.48
            )
            frontCardView.transform = CGAffineTransform(rotationAngle: 12 * .pi / 180)
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
}

// MARK: - PolaroidCardView

/// 폴라로이드 스타일 카드 뷰 (흰색 테두리 + 이미지)
private final class PolaroidCardView: UIView {
    // MARK: - Properties

    private let imageView = UIImageView()
    private let borderWidth: CGFloat = 1.5
    private let bottomBorderHeight: CGFloat = 1.5

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
        layer.cornerRadius = 4
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        // 이미지뷰 설정
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = DesignSystemAsset.gray200.color // 이미지 로딩 전 배경색
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // 이미지는 상단과 좌우에 borderWidth만큼 여백, 하단에는 bottomBorderHeight만큼 여백
        let imageFrame = CGRect(
            x: borderWidth,
            y: borderWidth,
            width: bounds.width - (borderWidth * 2),
            height: bounds.height - borderWidth - bottomBorderHeight
        )

        imageView.frame = imageFrame
    }

    // MARK: - Public Methods

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }
}
