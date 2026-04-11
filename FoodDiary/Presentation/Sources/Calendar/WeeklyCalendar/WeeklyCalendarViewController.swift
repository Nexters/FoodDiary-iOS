//
//  WeeklyCalendarViewController.swift
//  Presentation
//

import Combine
import Data
import DesignSystem
import DI
import Domain
import SnapKit
import UIKit

private enum Constants {
    static let horizontalInset: CGFloat = 20
}

public final class WeeklyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    AuthRepo: PhotoAuthorizationRepository,
    ImageProvider: RenderableImageRepository,
    PushObserver: PushNotificationObserving
>: UIViewController where ImageProvider.Asset == AssetRepo.Asset {

    // MARK: - Dependencies

    private let viewModel:
        WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, PushObserver
        >
    private let imageProvider: ImageProvider
    private let container: DIContainer

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private lazy var recordPromptHeaderView = RecordPromptHeaderView()
    private let headerView = WeeklyCalendarHeaderView()
    private let weekGridView = WeekGridView()
    private let bottomContentView = BottomContentView()

    private lazy var containerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [weekGridView, bottomContentView])
        sv.axis = .vertical
        sv.spacing = 24
        return sv
    }()

    private let imagePickerLoadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray400
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var isLoadingImagePicker = false

    // MARK: - Init

    public init(
        viewModel: WeeklyCalendarViewModel<
            RecordRepo, AssetRepo, AuthRepo, PushObserver
        >,
        imageProvider: ImageProvider,
        container: DIContainer
    ) {
        self.viewModel = viewModel
        self.imageProvider = imageProvider
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()

        viewModel.input.send(.loadInitialData)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.input.send(.viewDidAppear)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(recordPromptHeaderView)
        view.addSubview(headerView)
        view.addSubview(containerStackView)
        view.addSubview(imagePickerLoadingView)
    }

    private func setupConstraints() {
        recordPromptHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(28)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        headerView.snp.makeConstraints {
            $0.top.equalTo(recordPromptHeaderView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        containerStackView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-34)
        }

    }

    private func setupBindings() {
        // Input: View → ViewModel
        headerView.previousTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToPreviousWeek)
            }
            .store(in: &cancellables)

        headerView.nextTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToNextWeek)
            }
            .store(in: &cancellables)

        weekGridView.dateTapPublisher
            .sink { [weak self] date in
                self?.viewModel.input.send(.selectDate(date))
            }
            .store(in: &cancellables)

        // 하단 + 버튼 탭 → 권한 체크 후 이미지 피커 표시
        bottomContentView.addButtonTapPublisher
            .sink { [weak self] in
                self?.handleAddButtonTap()
            }
            .store(in: &cancellables)

        // Foreground 복귀 시 데이터 갱신
        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.viewModel.input.send(.refreshData())
            }
            .store(in: &cancellables)

        // Output: ViewModel → View (State 기반)
        viewModel.statePublisher
            .map(\.nickname)
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nickname in
                self?.recordPromptHeaderView.configure(nickname: nickname)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.monthText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.headerView.setMonthText(text)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.canGoToNextWeek)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canGoNext in
                self?.headerView.setNextButtonEnabled(canGoNext)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map { (weekDays: $0.weekDays, selectedDate: $0.selectedDate) }
            .removeDuplicates(by: ==)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] days, selectedDate in
                self?.weekGridView.configure(with: days, selectedDate: selectedDate)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .compactMap(\.dateContent)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                guard let self else { return }
                let state: BottomContentView.State =
                    if !content.records.isEmpty {
                        .recorded(content.records)
                    } else if !content.processingRecords.isEmpty {
                        .processing(content.processingRecords)
                    } else {
                        .empty(hasPhotos: content.hasFoodPhotos)
                    }

                bottomContentView.configure(state: state)
            }
            .store(in: &cancellables)

        // 카드 스택 탭 → 상세 화면으로 이동
        bottomContentView.cardStackTapPublisher
            .sink { [weak self] record in
                self?.navigateToDetail(for: record.date)
            }
            .store(in: &cancellables)

        // 프로세싱 카드 탭 → 상세 화면으로 이동
        bottomContentView.processingTapPublisher
            .sink { [weak self] date in
                self?.navigateToDetail(for: date)
            }
            .store(in: &cancellables)

        // 코치마크 표시
        viewModel.statePublisher
            .map(\.shouldShowCoachmark)
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.showCoachmarkOverlay() }
            .store(in: &cancellables)

        // Event: 권한 거부 시 설정 이동 안내 Alert 표시 및 저장 결과 처리
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .photoAuthorizationDenied:
                    self?.showPhotoAuthorizationDeniedAlert()
                case .uploadCompleted(let date, let mealType):
                    self?.navigateToDetail(for: date, scrollTo: mealType, shouldPopToRoot: true)
                case .saveFailed(let error):
                    self?.showSaveErrorAlert(error)
                case .loadFailed(let error):
                    self?.showLoadErrorAlert(error)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Coachmark

    private func showCoachmarkOverlay() {
        let overlay = CoachmarkOverlayView()
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        overlay.alpha = 0
        UIView.animate(withDuration: 0.3) { overlay.alpha = 1 }

        overlay.didDismissPublisher
            .receive(on: DispatchQueue.main)
            .first()
            .sink { [weak self, weak overlay] _ in
                UIView.animate(
                    withDuration: 0.3,
                    animations: { overlay?.alpha = 0 },
                    completion: { _ in
                        overlay?.removeFromSuperview()
                        self?.viewModel.input.send(.dismissCoachmark)
                    }
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Image Picker Loading

    private func setImagePickerLoading(_ isLoading: Bool) {
        isLoadingImagePicker = isLoading
        bottomContentView.isUserInteractionEnabled = !isLoading
        bottomContentView.alpha = isLoading ? 0.5 : 1.0
    }

    // MARK: - Actions

    private func handleAddButtonTap() {
        guard !isLoadingImagePicker else { return }
        if viewModel.checkPhotoAuthorizationForAddingPhoto() {
            Task {
                await presentImagePicker()
            }
        } else {
            // 권한이 없으면 재요청 (notDetermined면 시스템 다이얼로그, 아니면 denied 이벤트 발생)
            viewModel.input.send(.requestPhotoAuthorization)
        }
    }

    private func showPhotoAuthorizationDeniedAlert() {
        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "음식 사진을 기록하려면 사진 라이브러리 접근 권한이 필요합니다. 설정에서 권한을 허용해 주세요.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })

        present(alert, animated: true)
    }

    // MARK: - Navigation

    @MainActor
    private func presentImagePicker() async {
        setImagePickerLoading(true)
        defer { setImagePickerLoading(false) }

        let selectedDate = viewModel.state.selectedDate

        do {
            let foodImageAssets = try await viewModel.photos(for: selectedDate)
            let selectedPhotos = foodImageAssets.map { $0.imageAsset }

            // 음식 확률 0.6 이상인 사진 ID를 미리 선택
            let preselectedFoodPhotoIds = Set(
                foodImageAssets
                    .filter { $0.foodProbability >= 0.6 }
                    .map { $0.id }
            )

            let picker = ImagePickerViewController(
                photos: selectedPhotos,
                preselectedFoodPhotoIds: preselectedFoodPhotoIds,
                imageProvider: imageProvider,
                configuration: .withMaxSelectionCount(10)
            )

            picker.resultPublisher
                .sink { [weak self] result in
                    self?.handleImagePickerResult(result)
                }
                .store(in: &cancellables)

            navigationController?.pushViewController(picker, animated: true)
        } catch {
            showLoadErrorAlert(error)
        }
    }

    private func handleImagePickerResult(_ result: ImagePickerResult<AssetRepo.Asset>) {
        switch result {
        case .selected(let assets):
            viewModel.input.send(.saveSelectedPhotos(assets))
        case .cancelled:
            navigationController?.popViewController(animated: true)
        }
    }

    private func showLoadErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "불러오기 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showSaveErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "저장 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func navigateToDetail(for date: Date, scrollTo mealType: MealType? = nil, shouldPopToRoot: Bool = false) {
        let records = viewModel.state.weekDays.records(for: date)
        let detailVC = makeDetailViewController(
            date: date,
            records: records,
            scrollToMealType: mealType,
            shouldPopToRoot: shouldPopToRoot,
            onDismissWithDate: { [weak self] date in
                self?.viewModel.input.send(.refreshData(date))
            }
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private typealias DetailVM = DetailViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
        PushNotificationObserver
    >
    private typealias EditVM = EditFoodRecordViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
    >
    private typealias AddressSearchVM = AddressSearchViewModel<AddressSearchRepositoryImpl>
    private typealias AssetFetcher = FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
    private typealias FetchUseCase = FetchFoodImageAssetUseCase<AssetFetcher>
    private typealias AuthUseCase = RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>

    private func makeDetailViewController(
        date: Date,
        records: [FoodRecord],
        scrollToMealType: MealType? = nil,
        shouldPopToRoot: Bool = false,
        onDismissWithDate: ((Date) -> Void)? = nil
    ) -> UIViewController {
        guard let detailVM = try? container.resolve(DetailVM.self, argument: (date, records)) else {
            fatalError("DetailViewModel not registered")
        }
        return DetailViewController(
            viewModel: detailVM,
            initialScrollTarget: scrollToMealType,
            shouldPopToRoot: shouldPopToRoot,
            onDismissWithDate: onDismissWithDate,
            editViewControllerFactory: { [weak self] record in
                self?.makeEditViewController(for: record) ?? UIViewController()
            },
            presentImagePickerHandler: makeDetailImagePickerHandler()
        )
    }

    private func makeEditViewController(for record: FoodRecord) -> UIViewController {
        guard let editVM = try? container.resolve(EditVM.self, argument: record) else {
            fatalError("EditFoodRecordViewModel not registered")
        }
        let addressSearchVCFactory: (Int, @escaping (AddressSearchResult) -> Void) -> UIViewController = {
            [container] diaryId, onSelect in
            guard let addressVM = try? container.resolve(AddressSearchVM.self, argument: diaryId) else {
                fatalError("AddressSearchViewModel not registered")
            }
            return AddressSearchViewController(viewModel: addressVM, onAddressSelected: onSelect)
        }
        return EditFoodRecordViewController(viewModel: editVM, addressSearchViewControllerFactory: addressSearchVCFactory)
    }

    private func makeDetailImagePickerHandler()
        -> (UINavigationController, Date, @escaping ([any ImageAssetable]) -> Void) -> Void
    {
        return { [weak self] nav, date, onSelected in
            guard let self else { return }
            self.presentImagePicker(
                from: nav,
                date: date,
                configuration: .withMaxSelectionCount(10),
                autoPreselectByProbability: true,
                loadPreviewImages: false,
                onSelected: { assets, _ in onSelected(assets) }
            )
        }
    }

    private func presentImagePicker(
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

                let preselectedFoodPhotoIds: Set<String> =
                    autoPreselectByProbability
                    ? Set(foodImageAssets.filter { $0.foodProbability >= 0.5 }.map { $0.id })
                    : []

                let picker = ImagePickerViewController(
                    photos: photos,
                    preselectedFoodPhotoIds: preselectedFoodPhotoIds,
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
                            break
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
        alert.addAction(
            UIAlertAction(title: "설정으로 이동", style: .default) { _ in
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
