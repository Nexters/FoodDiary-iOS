//
//  AppFlowController.swift
//  App
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import DI
import Data
import Domain
import Presentation
import SnapKit
import UIKit

final class AppFlowController: UIViewController {
    private typealias AssetFetcher = FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
    private typealias FetchUseCase = FetchFoodImageAssetUseCase<AssetFetcher>
    private typealias AuthUseCase = RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>

    private var currentChild: UIViewController?
    private var networkCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let container: DIContainer

    public init(container: DIContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkMonitoring()
    }
}

extension AppFlowController {
    fileprivate func setupNetworkMonitoring() {
        guard let networkMonitor = try? container.resolve(NetworkMonitoring.self) else {
            fatalError("NetworkMonitoring not registered")
        }

        networkMonitor.startMonitoring()

        networkCancellable = networkMonitor.networkStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.handleNetworkStatusChange(isConnected: isConnected)
            }
    }

    fileprivate func handleNetworkStatusChange(isConnected: Bool) {
        if isConnected {
            proceedToNextScreen()
        }
    }

    fileprivate func proceedToNextScreen() {
        Task {
            let isLogin = await validateToken()
            await MainActor.run { [weak self] in
                guard let self else { return }
                routeToAppropriateScreen(isLogin: isLogin)
                networkCancellable?.cancel()
                networkCancellable = nil
            }
        }
    }

    fileprivate func routeToAppropriateScreen(isLogin: Bool) {
        let destinationVC = isLogin ? createMainView() : createLoginView()
        transition(to: destinationVC)
    }

    fileprivate func validateToken() async -> Bool {
        guard
            let validateAccessTokenUseCase = try? container.resolve(
                ValidateAccessTokenUseCase<
                    TokenRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
                >.self
            )
        else {
            fatalError("ValidateAccessTokenUseCase Failed Resolve")
        }

        return await validateAccessTokenUseCase.execute()
    }

    fileprivate func createMainView() -> UIViewController {
        let weeklyCalendarVC = makeWeeklyCalendarVC()
        let monthlyCalendarVC = makeMonthlyCalendarVC()

        let tabBarVC = RootTabBarController(
            weeklyVC: weeklyCalendarVC,
            monthlyVC: monthlyCalendarVC,
            insightVC: InsightViewController()
        )

        tabBarVC.didLogoutPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                transition(to: createLoginView())
            }
            .store(in: &cancellables)

        let navController = UINavigationController(rootViewController: tabBarVC)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .sdBase
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(white: 1, alpha: 1)]
        navAppearance.shadowColor = .clear

        navController.navigationBar.standardAppearance = navAppearance
        navController.navigationBar.scrollEdgeAppearance = navAppearance
        navController.navigationBar.tintColor = UIColor(white: 1, alpha: 1)

        return navController
    }

    fileprivate func makeWeeklyCalendarVC() -> UIViewController {
        guard let imageProvider = try? container.resolve(UIImageLoader.self) else {
            fatalError("UIImageLoader not registered")
        }

        typealias WeeklyVM = WeeklyCalendarViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
            PhotoAuthorizationFetcher,
            PendingFoodRecordStorage<FileStorageService>,
            PushNotificationObserver
        >

        guard let weeklyViewModel = try? container.resolve(WeeklyVM.self) else {
            fatalError("WeeklyCalendarViewModel not registered")
        }

        typealias DetailVM = DetailViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PendingFoodRecordStorage<FileStorageService>,
            PushNotificationObserver
        >
        typealias EditVM = EditFoodRecordViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
        >
        typealias AddressSearchVM = AddressSearchViewModel<AddressSearchRepositoryImpl>

        let addressSearchVCFactory:
            (Int, @escaping (AddressSearchResult) -> Void) -> UIViewController = {
                [container] diaryId, onSelect in
                guard
                    let addressVM = try? container.resolve(AddressSearchVM.self, argument: diaryId)
                else {
                    fatalError("AddressSearchViewModel not registered")
                }
                return AddressSearchViewController(
                    viewModel: addressVM, onAddressSelected: onSelect)
            }

        let editVCFactory: (FoodRecord) -> UIViewController = { [weak self, container] record in
            guard let self else { return UIViewController() }
            guard let editVM = try? container.resolve(EditVM.self, argument: record) else {
                fatalError("EditFoodRecordViewModel not registered")
            }

            let presentImagePickerHandler:
                (UINavigationController, Date, @escaping ([any ImageAssetable], [UIImage]) -> Void)
                    -> Void = { [weak self] nav, date, onSelected in
                        guard let self else { return }
                        self.presentImagePicker(
                            from: nav,
                            date: date,
                            configuration: ImagePickerConfiguration.default,
                            autoPreselectByProbability: false,
                            loadPreviewImages: true,
                            onSelected: { assets, previewImages in
                                onSelected(assets, previewImages)
                            }
                        )
                    }

            return EditFoodRecordViewController(
                viewModel: editVM,
                onDismissWithResult: { _ in },
                addressSearchViewControllerFactory: addressSearchVCFactory,
                presentImagePickerHandler: presentImagePickerHandler
            )
        }

        let detailImagePickerHandler:
            (UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void)
                -> Void = { [weak self] nav, date, onSelected in
                    guard let self else { return }
                    self.presentImagePicker(
                        from: nav,
                        date: date,
                        configuration: .withMaxSelectionCount(10),
                        autoPreselectByProbability: true,
                        loadPreviewImages: false,
                        onSelected: { assets, _ in
                            onSelected(assets)
                        }
                    )
                }

        return WeeklyCalendarViewController(
            viewModel: weeklyViewModel,
            imageProvider: imageProvider,
            detailViewModelFactory: { [container] date, records in
                guard let vm = try? container.resolve(DetailVM.self, argument: (date, records))
                else {
                    fatalError("DetailViewModel not registered")
                }
                return vm
            },
            editViewControllerFactory: editVCFactory,
            presentImagePickerHandler: detailImagePickerHandler
        )
    }

    fileprivate func makeMonthlyCalendarVC() -> UIViewController {
        typealias MonthlyVM = MonthlyCalendarViewModel<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            PhotoAuthorizationFetcher
        >

        guard let monthlyViewModel = try? container.resolve(MonthlyVM.self) else {
            fatalError("MonthlyCalendarViewModel not registered")
        }

        return MonthlyCalendarViewController(viewModel: monthlyViewModel)
    }

    fileprivate func createOnboardingView() -> UIViewController {
        let onboardingVC = OnboardingViewController()

        onboardingVC.didCompletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let mainVC = createMainView()
                transition(to: mainVC)
                showCoachmarkOverlay(on: mainVC)
            }
            .store(in: &cancellables)

        return UINavigationController(rootViewController: onboardingVC)
    }

    fileprivate func showCoachmarkOverlay(on viewController: UIViewController) {
        let overlay = CoachmarkOverlayView()
        viewController.view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        overlay.alpha = 0
        UIView.animate(withDuration: 0.3) { overlay.alpha = 1 }

        overlay.didDismissPublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                UIView.animate(
                    withDuration: 0.3,
                    animations: {
                        overlay.alpha = 0
                    },
                    completion: { _ in
                        overlay.removeFromSuperview()
                    })
            }
            .store(in: &cancellables)
    }

    fileprivate func createLoginView() -> UIViewController {
        guard let viewModel = try? container.resolve(LoginViewModel.self) else {
            fatalError("LoginViewModel Failed Resolve")
        }

        let loginVC = LoginViewController(viewModel: viewModel)

        loginVC.didLoginPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loginResult in
                guard let self else { return }
                handleLoginResult(loginResult)
            }
            .store(in: &cancellables)

        return loginVC
    }

    fileprivate func handleLoginResult(_ loginResult: LoginResult) {
        transition(to: loginResult.isFirst ? createOnboardingView() : createMainView())
    }

    fileprivate func transition(to viewController: UIViewController) {
        let previousChild = currentChild

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        viewController.view.alpha = 0

        UIView.animate(
            withDuration: 0.3,
            animations: {
                previousChild?.view.alpha = 0
                viewController.view.alpha = 1
            },
            completion: { _ in
                previousChild?.willMove(toParent: nil)
                previousChild?.view.removeFromSuperview()
                previousChild?.removeFromParent()

                viewController.didMove(toParent: self)
                self.currentChild = viewController
            }
        )
    }
}

// MARK: - Image Picker

extension AppFlowController {
    fileprivate func presentImagePicker(
        from nav: UINavigationController,
        date: Date,
        configuration: ImagePickerConfiguration,
        autoPreselectByProbability: Bool,
        loadPreviewImages: Bool,
        onSelected: @escaping ([any ImageAssetable], [UIImage]) -> Void
    ) {
        guard let fetchUseCase = try? container.resolve(FetchUseCase.self),
              let imageProvider = try? container.resolve(UIImageLoader.self),
              let authUseCase = try? container.resolve(AuthUseCase.self)
        else {
            fatalError("ImagePicker dependencies not registered")
        }

        Task { @MainActor in
            if !authUseCase.isAuthorized() {
                let status = await authUseCase.execute()
                if status == .denied || status == .restricted {
                    Self.presentPhotoAccessDeniedAlert(on: nav)
                    return
                }
            }

            do {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
                let photosByDate = try await fetchUseCase.execute(from: startOfDay, to: endOfDay)
                let foodImageAssets = photosByDate[startOfDay] ?? []
                let photos = foodImageAssets.map { $0.imageAsset }

                let preselectedIds: Set<String> = autoPreselectByProbability
                    ? Set(foodImageAssets.filter { $0.foodProbability >= 0.5 }.map { $0.id })
                    : []

                let picker = ImagePickerViewController(
                    photos: photos,
                    preselectedIds: preselectedIds,
                    imageProvider: imageProvider,
                    configuration: configuration
                )

                var cancellable: AnyCancellable?
                cancellable = picker.resultPublisher
                    .sink { [weak nav] result in
                        defer { cancellable = nil }
                        switch result {
                        case .selected(let assets):
                            nav?.popViewController(animated: true)
                            if loadPreviewImages {
                                Task { @MainActor in
                                    var previewImages: [UIImage] = []
                                    for asset in assets {
                                        if let image = try? await imageProvider.loadImage(
                                            for: asset,
                                            targetSize: CGSize(width: 300, height: 300)
                                        ) {
                                            previewImages.append(image)
                                        }
                                    }
                                    onSelected(assets, previewImages)
                                }
                            } else {
                                onSelected(assets, [])
                            }
                        case .cancelled:
                            nav?.popViewController(animated: true)
                        }
                    }

                nav.pushViewController(picker, animated: true)
            } catch {
                Self.presentPhotoLoadFailedAlert(error: error, on: nav)
            }
        }
    }

    private static func presentPhotoAccessDeniedAlert(on nav: UINavigationController) {
        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "음식 사진을 추가하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        nav.topViewController?.present(alert, animated: true)
    }

    private static func presentPhotoLoadFailedAlert(error: Error, on nav: UINavigationController) {
        let alert = UIAlertController(
            title: "사진 불러오기 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        nav.topViewController?.present(alert, animated: true)
    }
}
