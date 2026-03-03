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

    @Published private var currentPage: Int = 0

    private var cancellables = Set<AnyCancellable>()

    private let pages: [(image: UIImage?, text: String)] = [
        (DesignSystemAsset.onboard1.image, "여기저기 흩어진 음식 기록을,\n간편히 정리해 드릴게요"),
        (DesignSystemAsset.onboard2.image, "음식 기록은 간편하게 시작하고\n활용은 자유롭게 이어가세요."),
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

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = DesignSystemAsset.primary.color
        pageControl.pageIndicatorTintColor = DesignSystemAsset.sd800.color
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitle("다음", for: .normal)
        button.backgroundColor = DesignSystemAsset.primary.color
        button.setTitleColor(DesignSystemAsset.sdBase.color, for: .normal)
        button.clipsToBounds = true
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
        configureNavigationBar()
        setupActions()
        setupBindings()
        pageControl.numberOfPages = pages.count
        pageViewController.setViewControllers([pageViewControllers[0]], direction: .forward, animated: false)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nextButton.layer.cornerRadius = nextButton.frame.height / 2
    }
}

private extension OnboardingViewController {
    func configureUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        view.addSubview(pageControl)
        view.addSubview(nextButton)

        pageViewController.view.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(pageControl.snp.top).offset(-10)
        }

        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(nextButton.snp.top).offset(-100)
        }

        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(55)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(18)
        }
    }

    func configureNavigationBar() {
        let skipButton = UIBarButtonItem(
            title: "건너뛰기",
            style: .plain,
            target: self,
            action: #selector(skipButtonTapped)
        )

        navigationItem.rightBarButtonItem = skipButton
    }

    func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }

    func setupBindings() {
        $currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] page in
                guard let self = self else { return }
                self.pageControl.currentPage = page
                self.updateNextButton()
            }
            .store(in: &cancellables)
    }

    func updateNextButton() {
        nextButton.setTitle(currentPage == pages.count - 1 ? "시작하기" : "다음", for: .normal)
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
