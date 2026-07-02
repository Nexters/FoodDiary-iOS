//
//  OnboardPageContentViewController.swift
//  Presentation
//

import UIKit
import SnapKit
import DesignSystem

final class OnboardPageContentViewController: UIViewController {
    private enum Constants {
        static let imageSize: CGFloat = 180
        static let imageTopOffset: CGFloat = 104
        static let textTopSpacing: CGFloat = 36
        static let textHorizontalInset: CGFloat = 20
    }

    let pageIndex: Int

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(pageIndex: Int, image: UIImage?, text: String) {
        self.pageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
        textLabel.attributedText = Typography.p15.styled(
            text,
            color: .gray850,
            alignment: .center,
            lineSpacing: 3.75
        )
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
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(textLabel)

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(Constants.imageTopOffset)
            $0.size.equalTo(Constants.imageSize)
        }

        textLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(Constants.textTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.textHorizontalInset)
            $0.centerX.equalToSuperview()
        }
    }
}
