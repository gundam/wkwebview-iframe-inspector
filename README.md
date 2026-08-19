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

The tabs demonstrate five cases:

1. `Samsungweb` loads a direct page and inspects its form fields.
2. `Balance` loads a Samsungweb container with one Paypalweb balance iframe.
3. `Send Money` loads a separate Samsungweb container with one Checkoutweb transfer iframe. Submitting the form returns a local demo reference through origin-checked `postMessage`; no real money is moved.
4. `Nested` loads this three-origin chain:

   ```text
   Samsungweb (depth 0)
   └── Paypalweb (depth 1)
       └── Checkoutweb (depth 2)
   ```
5. `Sandbox` loads a `paypalweb.localhost` iframe wrapper that uses the official PayPal JavaScript SDK with `client-id=test`. The debug panel reads only the two local test frames and the documented checkout status; it intentionally does not inject into PayPal-owned frames or read account credentials.

Native code captures every frame's depth, URL, origin, title, body text, full HTML, and live form values. The injected collection script runs in every frame, so it does not try to bypass the browser's same-origin policy from the parent page.

Every screen includes a floating `DEBUG` button. The panel defaults to a concise content-and-fields summary; tap `More` for frame metadata and full HTML, or `Less` to return to the summary. Results continue updating when form values, DOM content, or iframe content changes.

> The local server uses an automatically generated self-signed certificate. The app only allows `.localhost` development hosts. This setup is for simulator testing only and must not be used in production.

Minimum deployment target: iOS 17.0.
