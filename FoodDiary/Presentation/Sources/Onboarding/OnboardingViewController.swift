//
//  OnboardingViewController.swift
//  Presentation
//
//  Created by 강대훈 on 2/18/26.
//

import UIKit
import Combine
import SnapKit
import DesignSystem

public final class OnboardingViewController: UIViewController {
    private let didCompleteSubject = PassthroughSubject<Void, Never>()

    public var didCompletePublisher: AnyPublisher<Void, Never> {
        didCompleteSubject.eraseToAnyPublisher()
    }

    private var currentPage: Int = 0 {
        didSet {
            updateCurrentPageAppearance()
        }
    }

    private let pages: [(image: UIImage?, text: String)] = [
        (DesignSystemAsset.onboard1.image, "여기저기 흩어진 음식 기록들,\n간편히 정리해 드릴게요"),
        (DesignSystemAsset.onboard2.image, "음식 기록은 간편하게 시작하고,\n활용은 자유롭게 이어가세요."),
        (DesignSystemAsset.onboard3.image, "음식 사진을 올리면 식당, 메뉴,\n방문 정보를 자동으로 정리해줘요."),
        (DesignSystemAsset.onboard4.image, "정리된 기록을 블로그나 SNS에\n바로 활용할 수 있어요."),
        (DesignSystemAsset.onboard5.image, "기록이 쌓일수록 무엇을, 언제,\n얼마나 먹는지 한눈에 보여요.")
    ]

    private lazy var pageViewControllers: [OnboardPageContentViewController] = {
        pages.enumerated().map { index, page in
            OnboardPageContentViewController(pageIndex: index, image: page.image, text: page.text)
        }
    }()

    private lazy var pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    private lazy var pageIndicatorDots: [UIView] = {
        pages.indices.map { index in
            let dot = UIView()
            dot.backgroundColor = index == 0 ? .primary : .sd800
            dot.layer.cornerRadius = 3
            dot.clipsToBounds = true
            dot.snp.makeConstraints {
                $0.size.equalTo(6)
            }
            return dot
        }
    }()

    private lazy var pageIndicatorStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: pageIndicatorDots)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 4
        return stackView
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let headerSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray150
        return view
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            Typography.p15.styled("건너뛰기", color: .black, alignment: .right),
            for: .normal
        )
        button.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(
            Typography.hd15.styled("다음", color: .sdBase, alignment: .center),
            for: .normal
        )
        button.backgroundColor = DesignSystemAsset.primary.color
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        updateCurrentPageAppearance()
        pageViewController.setViewControllers([pageViewControllers[0]], direction: .forward, animated: false)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nextButton.layer.cornerRadius = nextButton.frame.height / 2
    }
}

private extension OnboardingViewController {
    func configureUI() {
        view.backgroundColor = .white

        view.addSubview(headerView)
        headerView.addSubview(skipButton)
        view.addSubview(headerSeparatorView)

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        view.addSubview(pageIndicatorStackView)
        view.addSubview(nextButton)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(60)
        }

        skipButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        headerSeparatorView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        pageIndicatorStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(nextButton.snp.top).offset(-136)
        }

        pageViewController.view.snp.makeConstraints {
            $0.top.equalTo(headerSeparatorView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(pageIndicatorStackView.snp.top)
        }

        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(36)
        }
    }

    func updateCurrentPageAppearance() {
        updateNextButtonTitle()
        pageIndicatorDots.enumerated().forEach { index, dot in
            dot.backgroundColor = index == currentPage ? .primary : .sd800
        }
    }

    func updateNextButtonTitle() {
        let title = currentPage == pages.count - 1 ? "시작하기" : "다음"
        nextButton.setAttributedTitle(
            Typography.hd15.styled(title, color: .sdBase, alignment: .center),
            for: .normal
        )
    }

    @objc func skipButtonTapped() {
        didCompleteSubject.send()
    }

    @objc func nextButtonTapped() {
        if currentPage == pages.count - 1 {
            didCompleteSubject.send()
        } else {
            let nextPage = currentPage + 1
            pageViewController.setViewControllers(
                [pageViewControllers[nextPage]],
                direction: .forward,
                animated: false
            )
            currentPage = nextPage
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? OnboardPageContentViewController else { return nil }
        let index = contentVC.pageIndex - 1
        guard index >= 0 else { return nil }
        return pageViewControllers[index]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let contentVC = viewController as? OnboardPageContentViewController else { return nil }
        let index = contentVC.pageIndex + 1
        guard index < pages.count else { return nil }
        return pageViewControllers[index]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let contentVC = pageViewController.viewControllers?.first as? OnboardPageContentViewController else { return }
        currentPage = contentVC.pageIndex
    }
}
