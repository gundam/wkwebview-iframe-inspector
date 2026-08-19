# iOSApp

An iOS Simulator project for testing native `WKWebView` inspection across direct pages, cross-origin iframes, and nested cross-origin iframes.

## Run

1. Boot an iPhone simulator from Xcode or the Simulator app.
2. Start the local HTTPS server. The script automatically installs the development certificate in every booted simulator:

   ```bash
   cd /path/to/wkwebview-iframe-inspector
   ./server/start.sh
   ```

3. Open `iOSApp.xcodeproj` in Xcode.
4. Select the same simulator and press `Command + R`.

Test origins:

- Samsungweb: `https://samsungweb.localhost:8443`
- Paypalweb: `https://paypalweb.localhost:8443`
- Checkoutweb: `https://checkoutweb.localhost:8443`

The tabs demonstrate six cases:

1. `Direct` renders a Paypalweb balance page directly as the main frame, with no iframe.
2. `Balance` loads a Samsungweb outer page with one Paypalweb balance iframe. Both page owners are labeled in the UI.
3. `Send Money` loads a separate Samsungweb outer page with one Paypalweb Checkout iframe. The checkout demo contains one amount input and updates the native DEBUG result while typing; no real money is moved.
4. `Safari` uses Apple's `SFSafariViewController` to open the Paypalweb balance page. It does not use the app-controlled WKWebView inspector or inject the native DEBUG collector.
5. `Nested` loads this three-origin chain:

   ```text
   Samsungweb (depth 0)
   └── Paypalweb (depth 1)
       └── Checkoutweb (depth 2)
   ```
6. `Sandbox` loads a `paypalweb.localhost` iframe wrapper that uses the official PayPal JavaScript SDK with `client-id=test`. The debug panel reads only the two local test frames and the documented checkout status; it intentionally does not inject into PayPal-owned frames or read account credentials.

## Production security references

This repository uses local `.localhost` fixtures for security research. It is not approval to load a real PayPal sign-in, checkout, credential, or payment page in an app-controlled `WKWebView`.

- [Apple: Password AutoFill](https://developer.apple.com/documentation/security/password-autofill) — under “Support third-party web services,” Apple directs apps that log in to a third-party service to use `ASWebAuthenticationSession`. Apple does not name PayPal on this page; PayPal is the applicable third-party service in this demo.
- [Apple: ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) — Apple’s system-managed authentication session displays the authentication domain and securely returns the callback to the requesting app.
- [PayPal/Braintree: Browser support — PayPal and webviews](https://developer.paypal.com/braintree/docs/reference/client-reference/javascript/v2/browser-support#paypal-and-webviews) — PayPal security guidance discourages PayPal checkout in WebViews and recommends a supported SDK, the system browser, or an approved browser-view mechanism such as `SFSafariViewController` on iOS.

For production PayPal authentication or payment, use PayPal’s supported iOS integration and Apple’s system-managed authentication/browser APIs instead of an inspectable, script-injected `WKWebView`.

Native code captures every frame's depth, URL, origin, title, body text, full HTML, and live form values. The injected collection script runs in every frame, so it does not try to bypass the browser's same-origin policy from the parent page.

Every WKWebView demo screen includes a floating `DEBUG` button. When the panel opens, the WebView resizes above it instead of being covered and automatically reveals the first editable field or iframe, so page inputs remain reachable during a live inspection. The panel defaults to a concise content-and-fields summary; tap `More` for frame metadata and full HTML, or `Less` to return to the summary. The Safari tab intentionally has no native DEBUG collector. Use the `Tabs` menu to independently show or hide Direct, Balance, Send Money, Safari, Nested, and Sandbox for different demo combinations. At least one page always remains visible. Results continue updating when form values, DOM content, or iframe content changes.

> The local server uses an automatically generated self-signed certificate. The app only allows `.localhost` development hosts. This setup is for simulator testing only and must not be used in production.

Minimum deployment target: iOS 17.0.
