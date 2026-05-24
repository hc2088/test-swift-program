//
//  SceneDelegate.swift
//  test-runloop-demo
//
//  Created by Codex on 2026/5/24.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let root = ViewController()
        let navigationController = UINavigationController(rootViewController: root)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1)
        ]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor(red: 0.22, green: 0.46, blue: 0.92, alpha: 1)
        navigationController.view.backgroundColor = .white

        window.rootViewController = navigationController
        window.backgroundColor = .white
        self.window = window
        window.makeKeyAndVisible()
    }
}
