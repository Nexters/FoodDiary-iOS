//
//  SceneDelegate.swift
//  App
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit
import Data
import DesignSystem
import Presentation
import Photos

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        let demoVC: UIViewController
        do {
            let classifier = try TFLiteFoodClassifier()
            let repository = FoodPhotoFetcher(
                foodClassifier: classifier,
                imageCacheManager: PHImageCache()
            )
            // FoodImagePicker 데모용 ViewController
            demoVC = ImagePickerDemoViewController(
                repository: repository,
                imageCache: PHImageCache()
            )
        } catch {
            demoVC = UIViewController()
            print("❌ Failed to initialize: \(error)")
        }

        window?.rootViewController = demoVC
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {

    }

    func sceneWillEnterForeground(_ scene: UIScene) {

    }

    func sceneDidEnterBackground(_ scene: UIScene) {

    }
}


