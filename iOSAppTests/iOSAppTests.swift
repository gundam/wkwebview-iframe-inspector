import XCTest
@testable import iOSApp

final class iOSAppTests: XCTestCase {
    func testDemoUsesHTTPSAndThreeDifferentOrigins() {
        XCTAssertEqual(WebDemoConfiguration.directPageURL.scheme, "https")
        XCTAssertEqual(WebDemoConfiguration.directPageURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.directPageURL.path, "/direct.html")
        XCTAssertEqual(WebDemoConfiguration.balanceContainerURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.balanceContainerURL.path, "/iframe.html")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyContainerURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyContainerURL.path, "/send-money-iframe.html")
        XCTAssertEqual(WebDemoConfiguration.multiLevelPageURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.paypalSandboxPageURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.safariBalancePageURL.scheme, "https")
        XCTAssertEqual(WebDemoConfiguration.safariBalancePageURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.safariBalancePageURL.path, "/balance.html")
        XCTAssertEqual(WebDemoConfiguration.balanceIframeURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.balanceIframeURL.path, "/balance.html")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyIframeURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyIframeURL.path, "/send-money.html")
        XCTAssertEqual(WebDemoConfiguration.paypalSandboxIframeURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.deepEmbeddedPageURL.host, "checkoutweb.localhost")

        let hosts = Set([
            WebDemoConfiguration.balanceContainerURL.host,
            WebDemoConfiguration.directPageURL.host,
            WebDemoConfiguration.deepEmbeddedPageURL.host
        ].compactMap { $0 })
        XCTAssertEqual(hosts.count, 3)
    }

    func testOnlyLocalDevelopmentHostsAreAllowed() {
        XCTAssertTrue(WebDemoConfiguration.isAllowedDevelopmentHost("samsungweb.localhost"))
        XCTAssertTrue(WebDemoConfiguration.isAllowedDevelopmentHost("paypalweb.localhost"))
        XCTAssertTrue(WebDemoConfiguration.isAllowedDevelopmentHost("checkoutweb.localhost"))
        XCTAssertFalse(WebDemoConfiguration.isAllowedDevelopmentHost("example.com"))
    }
}
