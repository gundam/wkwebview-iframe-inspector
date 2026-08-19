import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let direct = DirectWebViewController()
        direct.tabBarItem = UITabBarItem(
            title: "Direct",
            image: UIImage(systemName: "doc.text.magnifyingglass"),
            selectedImage: UIImage(systemName: "doc.text.magnifyingglass")
        )

        let balance = BalanceIframeViewController()
        balance.tabBarItem = UITabBarItem(
            title: "Balance",
            image: UIImage(systemName: "dollarsign.circle.fill"),
            selectedImage: UIImage(systemName: "dollarsign.circle.fill")
        )

        let sendMoney = SendMoneyIframeViewController()
        sendMoney.tabBarItem = UITabBarItem(
            title: "Send Money",
            image: UIImage(systemName: "paperplane.fill"),
            selectedImage: UIImage(systemName: "paperplane.fill")
        )

        let multiLevel = MultiLevelIframeViewController()
        multiLevel.tabBarItem = UITabBarItem(
            title: "Nested",
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            selectedImage: UIImage(systemName: "square.stack.3d.up.fill")
        )

        let paypalSandbox = PayPalSandboxViewController()
        paypalSandbox.tabBarItem = UITabBarItem(
            title: "Sandbox",
            image: UIImage(systemName: "creditcard.fill"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )

        viewControllers = [
            UINavigationController(rootViewController: direct),
            UINavigationController(rootViewController: balance),
            UINavigationController(rootViewController: sendMoney),
            UINavigationController(rootViewController: multiLevel),
            UINavigationController(rootViewController: paypalSandbox)
        ]

        if ProcessInfo.processInfo.arguments.contains("--paypal-sandbox") {
            selectedIndex = 4
        } else if ProcessInfo.processInfo.arguments.contains("--multilevel") {
            selectedIndex = 3
        } else if ProcessInfo.processInfo.arguments.contains("--send-money") {
            selectedIndex = 2
        } else if ProcessInfo.processInfo.arguments.contains("--balance")
            || ProcessInfo.processInfo.arguments.contains("--iframe") {
            selectedIndex = 1
        }
    }
}
