import UIKit
import SafariServices

private enum DemoTab: String, CaseIterable {
    case direct
    case balance
    case sendMoney
    case safari
    case nested
    case sandbox

    var title: String {
        switch self {
        case .direct: "Direct"
        case .balance: "Balance"
        case .sendMoney: "Send Money"
        case .safari: "Safari"
        case .nested: "Nested"
        case .sandbox: "Sandbox"
        }
    }
}

final class RootTabBarController: UITabBarController {
    private var demoControllers: [DemoTab: UIViewController] = [:]
    private var visibleDemoTabs = Set(DemoTab.allCases)

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

        let safariConfiguration = SFSafariViewController.Configuration()
        safariConfiguration.entersReaderIfAvailable = false
        safariConfiguration.barCollapsingEnabled = false
        let safariBalance = SFSafariViewController(
            url: WebDemoConfiguration.safariBalancePageURL,
            configuration: safariConfiguration
        )
        safariBalance.preferredControlTintColor = .systemBlue
        safariBalance.tabBarItem = UITabBarItem(
            title: "Safari",
            image: UIImage(systemName: "safari.fill"),
            selectedImage: UIImage(systemName: "safari.fill")
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

        demoControllers = [
            .direct: UINavigationController(rootViewController: direct),
            .balance: UINavigationController(rootViewController: balance),
            .sendMoney: UINavigationController(rootViewController: sendMoney),
            .safari: safariBalance,
            .nested: UINavigationController(rootViewController: multiLevel),
            .sandbox: UINavigationController(rootViewController: paypalSandbox)
        ]
        applyVisibleDemoTabs(preferredSelection: launchDemoTab)
    }

    func makeTabVisibilityMenu() -> UIMenu {
        let tabActions = DemoTab.allCases.map { demoTab in
            let isVisible = visibleDemoTabs.contains(demoTab)
            var attributes: UIMenuElement.Attributes = []
            if isVisible && visibleDemoTabs.count == 1 {
                attributes.insert(.disabled)
            }

            return UIAction(
                title: demoTab.title,
                attributes: attributes,
                state: isVisible ? .on : .off
            ) { [weak self] _ in
                self?.toggleDemoTab(demoTab)
            }
        }

        let showAll = UIAction(
            title: "Show All",
            image: UIImage(systemName: "rectangle.stack.fill"),
            attributes: visibleDemoTabs.count == DemoTab.allCases.count
                ? [.disabled]
                : []
        ) { [weak self] _ in
            self?.visibleDemoTabs = Set(DemoTab.allCases)
            self?.applyVisibleDemoTabs()
        }

        return UIMenu(
            title: "Visible Demo Pages",
            children: [
                UIMenu(options: .displayInline, children: tabActions),
                UIMenu(options: .displayInline, children: [showAll])
            ]
        )
    }

    private var launchDemoTab: DemoTab {
        if ProcessInfo.processInfo.arguments.contains("--safari") {
            return .safari
        }
        if ProcessInfo.processInfo.arguments.contains("--paypal-sandbox") {
            return .sandbox
        }
        if ProcessInfo.processInfo.arguments.contains("--multilevel") {
            return .nested
        }
        if ProcessInfo.processInfo.arguments.contains("--send-money") {
            return .sendMoney
        }
        if ProcessInfo.processInfo.arguments.contains("--balance")
            || ProcessInfo.processInfo.arguments.contains("--iframe") {
            return .balance
        }
        return .direct
    }

    private func toggleDemoTab(_ demoTab: DemoTab) {
        if visibleDemoTabs.contains(demoTab) {
            guard visibleDemoTabs.count > 1 else { return }
            visibleDemoTabs.remove(demoTab)
        } else {
            visibleDemoTabs.insert(demoTab)
        }
        applyVisibleDemoTabs()
    }

    private func applyVisibleDemoTabs(preferredSelection: DemoTab? = nil) {
        let previouslySelectedController = selectedViewController
        let visibleControllers = DemoTab.allCases.compactMap { demoTab in
            visibleDemoTabs.contains(demoTab) ? demoControllers[demoTab] : nil
        }

        setViewControllers(visibleControllers, animated: false)

        if let preferredSelection,
           let preferredController = demoControllers[preferredSelection],
           visibleControllers.contains(where: { $0 === preferredController }) {
            selectedViewController = preferredController
        } else if let previouslySelectedController,
                  visibleControllers.contains(where: { $0 === previouslySelectedController }) {
            selectedViewController = previouslySelectedController
        } else {
            selectedIndex = 0
        }

        refreshTabVisibilityMenus()
    }

    private func refreshTabVisibilityMenus() {
        for controller in demoControllers.values {
            let navigationController = controller as? UINavigationController
            let inspector = navigationController?.viewControllers.first as? WebInspectorViewController
            inspector?.refreshTabVisibilityMenu()
        }
    }
}
