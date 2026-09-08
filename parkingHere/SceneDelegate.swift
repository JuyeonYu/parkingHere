//
//  SceneDelegate.swift
//  parkingHere
//
//  Created by Juyeon on 2020/12/13.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    /// 씬이 활성화되기 전에 들어온 딥링크. 백그라운드 상태에서 화면을 띄우면 무시되므로 활성화 후 처리한다.
    private var pendingDeepLink: DeepLink?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        window.makeKeyAndVisible()
        self.window = window

        if let url = connectionOptions.urlContexts.first?.url {
            pendingDeepLink = DeepLink(url: url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, let link = DeepLink(url: url) else { return }
        pendingDeepLink = link
        if scene.activationState == .foregroundActive {
            flushPendingDeepLink()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        flushPendingDeepLink()
    }

    private func flushPendingDeepLink() {
        guard let link = pendingDeepLink,
              let mainVC = window?.rootViewController as? MainViewController else { return }
        pendingDeepLink = nil
        mainVC.handle(link)
    }
}
