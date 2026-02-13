//
//  OnboardingViewController.swift
//  Presentation
//
//  Created by Claude Code on 2/11/26.
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

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(OnboardPageCell.self, forCellWithReuseIdentifier: OnboardPageCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
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
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
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
        setupGestures()
        setupBindings()
        pageControl.numberOfPages = pages.count
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nextButton.layer.cornerRadius = nextButton.frame.height / 2
    }
}

private extension OnboardingViewController {
    func configureUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        collectionView.snp.makeConstraints {
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

    func setupGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        collectionView.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        collectionView.addGestureRecognizer(rightSwipe)
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

    func transitionToPage(_ nextPage: Int) {
        guard nextPage != currentPage,
              let currentCell = collectionView.cellForItem(at: IndexPath(item: currentPage, section: 0)) else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            currentCell.alpha = 0
        }) { _ in
            let indexPath = IndexPath(item: nextPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.currentPage = nextPage

            self.collectionView.cellForItem(at: indexPath)?.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.collectionView.cellForItem(at: indexPath)?.alpha = 1
            }
        }
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let nextPage = gesture.direction == .left
            ? min(currentPage + 1, pages.count - 1)
            : max(currentPage - 1, 0)

        transitionToPage(nextPage)
    }

    @objc func skipButtonTapped() {
        didCompleteSubject.send()
    }

    @objc func nextButtonTapped() {
        currentPage == pages.count - 1
            ? didCompleteSubject.send()
            : transitionToPage(currentPage + 1)
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardPageCell.identifier, for: indexPath) as? OnboardPageCell else {
            return UICollectionViewCell()
        }

        let page = pages[indexPath.item]
        cell.configure(image: page.image, text: page.text)
        
        return cell
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}
