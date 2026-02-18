//
//  OnboardPageContentViewController.swift
//  Presentation
//

import UIKit
import SnapKit
import DesignSystem

final class OnboardPageContentViewController: UIViewController {
    let pageIndex: Int

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, textLabel])
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.alignment = .center
        return stackView
    }()

    init(pageIndex: Int, image: UIImage?, text: String) {
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
        textLabel.setText(text, style: .p15)
        textLabel.textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

private extension OnboardPageContentViewController {
    func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(130)
            $0.leading.trailing.equalToSuperview().inset(65)
            $0.centerX.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.height.equalTo(220)
            $0.width.equalTo(imageView.snp.height)
            $0.centerX.equalToSuperview()
        }
    }
}
