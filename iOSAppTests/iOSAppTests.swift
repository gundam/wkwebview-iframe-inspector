import XCTest
@testable import iOSApp

final class iOSAppTests: XCTestCase {
    func testDemoUsesHTTPSAndThreeDifferentOrigins() {
        XCTAssertEqual(WebDemoConfiguration.directPageURL.scheme, "https")
        XCTAssertEqual(WebDemoConfiguration.iframeContainerURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.multiLevelPageURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.paypalSandboxPageURL.host, "samsungweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.balanceIframeURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.balanceIframeURL.path, "/balance.html")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyIframeURL.host, "checkoutweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.sendMoneyIframeURL.path, "/send-money.html")
        XCTAssertEqual(WebDemoConfiguration.paypalSandboxIframeURL.host, "paypalweb.localhost")
        XCTAssertEqual(WebDemoConfiguration.deepEmbeddedPageURL.host, "checkoutweb.localhost")

        let hosts = Set([
            WebDemoConfiguration.multiLevelPageURL.host,
            WebDemoConfiguration.balanceIframeURL.host,
            WebDemoConfiguration.sendMoneyIframeURL.host
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
