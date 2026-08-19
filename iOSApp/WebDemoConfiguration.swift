import Foundation

enum WebDemoConfiguration {
    static let directPageURL = URL(string: "https://samsungweb.localhost:8443/direct.html")!
    static let iframeContainerURL = URL(string: "https://samsungweb.localhost:8443/iframe.html")!
    static let multiLevelPageURL = URL(string: "https://samsungweb.localhost:8443/multilevel.html")!
    static let paypalSandboxPageURL = URL(string: "https://samsungweb.localhost:8443/paypal-sandbox-container.html")!
    static let embeddedPageURL = URL(string: "https://paypalweb.localhost:8443/embedded.html")!
    static let paypalSandboxIframeURL = URL(string: "https://paypalweb.localhost:8443/paypal-sandbox-checkout.html")!
    static let deepEmbeddedPageURL = URL(string: "https://checkoutweb.localhost:8443/deep.html")!

    static func isAllowedDevelopmentHost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        return normalizedHost.hasSuffix(".localhost")
            || normalizedHost == "localhost"
            || normalizedHost == "127.0.0.1"
    }
}
