import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let direct = DirectWebViewController()
        direct.tabBarItem = UITabBarItem(
            title: "Samsungweb",
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            selectedImage: UIImage(systemName: "doc.text.magnifyingglass")
        )

        let iframe = IframeWebViewController()
        iframe.tabBarItem = UITabBarItem(
            title: "Cross-Origin iframe",
            image: UIImage(systemName: "rectangle.inset.filled"),
            selectedImage: UIImage(systemName: "rectangle.inset.filled")
        )

        let multiLevel = MultiLevelIframeViewController()
        multiLevel.tabBarItem = UITabBarItem(
            title: "Multi-Level",
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            selectedImage: UIImage(systemName: "square.stack.3d.up.fill")
        )

        let paypalSandbox = PayPalSandboxViewController()
        paypalSandbox.tabBarItem = UITabBarItem(
            title: "PayPal Sandbox",
            image: UIImage(systemName: "creditcard.fill"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )

        viewControllers = [
            UINavigationController(rootViewController: direct),
            UINavigationController(rootViewController: iframe),
            UINavigationController(rootViewController: multiLevel),
            UINavigationController(rootViewController: paypalSandbox)
        ]

        if ProcessInfo.processInfo.arguments.contains("--paypal-sandbox") {
            selectedIndex = 3
        } else if ProcessInfo.processInfo.arguments.contains("--multilevel") {
            selectedIndex = 2
        } else if ProcessInfo.processInfo.arguments.contains("--iframe") {
            selectedIndex = 1
        }
    }
}
