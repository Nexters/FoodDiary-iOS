//
//  SelectableImageCell.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 선택 가능한 이미지 셀
public final class SelectableImageCell: UICollectionViewCell {
    public static let reuseIdentifier = "SelectableImageCell"

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let selectionBorderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 12
        view.isUserInteractionEnabled = false
        return view
    }()

    private let probabilityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    // MARK: - Properties

    private var configuration: ImagePickerConfiguration = .default
    private var isSelectedState: Bool = false
    private var showsProbabilityLabel: Bool = true

    // MARK: - Initialization

    public override init(frame: CGRect) {
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
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(selectionBorderView)
        contentView.addSubview(checkmarkImageView)
        contentView.addSubview(probabilityLabel)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionBorderView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        checkmarkImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
            $0.size.equalTo(20)
        }

        probabilityLabel.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(4)
            $0.width.greaterThanOrEqualTo(40)
            $0.height.equalTo(18)
        }
    }

    // MARK: - Configuration

    /// 셀 설정
    /// - Parameters:
    ///   - isSelected: 선택 상태
    ///   - configuration: 피커 설정
    ///   - showsProbabilityLabel: 확률 라벨 표시 여부 (디버그용)
    public func configure(
        isSelected: Bool,
        configuration: ImagePickerConfiguration = .default,
        showsProbabilityLabel: Bool = true
    ) {
        self.configuration = configuration
        self.isSelectedState = isSelected
        self.showsProbabilityLabel = showsProbabilityLabel

        probabilityLabel.isHidden = !showsProbabilityLabel
        updateSelectionAppearance()
    }

    /// 이미지 설정 (비동기 로딩용)
    public func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    /// 선택 상태 업데이트
    public func setSelected(_ selected: Bool) {
        isSelectedState = selected
        updateSelectionAppearance()
    }

    /// Food probability 표시
    /// - Note: 디버그 목적으로 임시 구현된 기능입니다. 추후 제거될 수 있습니다.
    public func setFoodProbability(_ probability: Float) {
        guard showsProbabilityLabel else { return }

        let percentage = Int(probability * 100)
        probabilityLabel.text = " \(percentage)% "

        // 확률에 따라 배경색 변경
        if probability >= 0.7 {
            probabilityLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
        } else if probability >= 0.4 {
            probabilityLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.85)
        } else {
            probabilityLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        }
    }

    // MARK: - Private Methods

    private func updateSelectionAppearance() {
        if isSelectedState {
            // 선택됨
            selectionBorderView.layer.borderColor = configuration.primaryColor.cgColor
            selectionBorderView.isHidden = false
            checkmarkImageView.image = DesignSystemAsset.checkmarkSelected.image
        } else {
            // 미선택
            selectionBorderView.isHidden = true
            checkmarkImageView.image = DesignSystemAsset.checkmarkUnselected.image
        }
    }

    // MARK: - Reuse

    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isSelectedState = false
        probabilityLabel.text = nil
        probabilityLabel.backgroundColor = .clear
        updateSelectionAppearance()
    }
}
