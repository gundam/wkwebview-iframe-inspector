# AI Operator Guide

This repository is an iOS Simulator-only `WKWebView` inspection demo. Use this file as the primary runbook when starting, changing, or validating the project.

## Goal and safety boundary

- Demonstrate native collection from local direct pages, cross-origin iframes, and nested iframes.
- Demonstrate the official PayPal JavaScript SDK with Sandbox configuration only (`client-id=test`, no real money).
- Never add real PayPal credentials, Client Secrets, passwords, cookies, or live payment data.
- Do not inject the collector into PayPal-owned frames. `WebViewControllers.swift` deliberately exits unless the frame hostname is `.localhost`, `localhost`, or `127.0.0.1`.
- This is a simulator/security research demo, not a production payment integration.

## Project map

- `iOSApp.xcodeproj`: Xcode project; scheme is `iOSApp`.
- `iOSApp/iOSAppApp.swift`: SwiftUI app entry point.
- `iOSApp/ContentView.swift`: hosts the UIKit tab controller.
- `iOSApp/RootTabBarController.swift`: creates the five demo tabs and handles launch arguments.
- `iOSApp/WebViewControllers.swift`: `WKWebView`, injected collector, live frame snapshots, compact DEBUG UI, and `More` details.
- `iOSApp/WebDemoConfiguration.swift`: all demo URLs and local-host allowlist.
- `server/start.sh`: prepares the local certificate, installs it into every booted simulator, and starts the HTTPS server.
- `server/https_server.py`: certificate generation and host-based routing.
- `server/web/a`: Samsungweb outer/container pages.
- `server/web/b`: Paypalweb direct, balance, Checkout, nested, and PayPal Sandbox pages.
- `server/web/c`: Checkoutweb deepest nested-iframe page.
- `iOSAppTests/iOSAppTests.swift`: URL/origin/allowlist tests.

## Requirements

- macOS with Xcode and command-line tools.
- An iOS 17.0 or newer simulator.
- Python 3 and OpenSSL, both available on the current machine.
- Internet access is required only for loading the official PayPal Sandbox SDK assets.

## Fastest reliable startup

Run every command from the repository root:

If necessary, move to the repository root from anywhere inside the checkout:

```bash
cd "$(git rev-parse --show-toplevel)"
```

1. Check for a booted simulator:

   ```bash
   xcrun simctl list devices booted
   ```

   If none is booted, open Simulator and wait for an iPhone to finish booting:

   ```bash
   open -a Simulator
   ```

2. Start the HTTPS server in a long-running terminal/session:

   ```bash
   ./server/start.sh
   ```

   Keep this process running while the app is in use. It automatically generates the self-signed certificate and installs it in all currently booted simulators.

3. Resolve the current simulator UDID without hardcoding it:

   ```bash
   SIM_ID=$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; p=json.load(sys.stdin); print(next(d["udid"] for ds in p["devices"].values() for d in ds if d["state"] == "Booted"))')
   ```

4. Build and run tests:

   ```bash
   xcodebuild \
     -project iOSApp.xcodeproj \
     -scheme iOSApp \
     -sdk iphonesimulator \
     -destination "platform=iOS Simulator,id=$SIM_ID" \
     -derivedDataPath /tmp/iOSAppDerivedData \
     CODE_SIGNING_ALLOWED=NO \
     test
   ```

5. Install and launch the app:

   ```bash
   xcrun simctl install "$SIM_ID" /tmp/iOSAppDerivedData/Build/Products/Debug-iphonesimulator/iOSApp.app
   xcrun simctl launch --terminate-running-process "$SIM_ID" com.example.iOSApp
   open -a Simulator
   ```

## Direct launch modes

Pass these after the bundle identifier in `simctl launch`:

- No arguments: open the directly rendered `Paypalweb` balance page tab.
- `--balance` or legacy `--iframe`: open the balance iframe tab.
- `--send-money`: open the send-money iframe tab.
- `--multilevel`: open the Samsungweb → Paypalweb → Checkoutweb nested iframe tab.
- `--paypal-sandbox`: open the PayPal SDK Sandbox tab.
- `--debug`: automatically open the native DEBUG panel; combine it with any mode.

Example:

```bash
xcrun simctl launch \
  --terminate-running-process \
  "$SIM_ID" \
  com.example.iOSApp \
  --paypal-sandbox \
  --debug
```

Use `--console-pty` before the simulator ID when runtime logs are needed. A healthy multi-level launch reports depths 0, 1, and 2. A healthy PayPal Sandbox launch reports only the two local frames even though PayPal-owned network resources load.

## Local origins

```text
https://samsungweb.localhost:8443   -> server/web/a
https://paypalweb.localhost:8443    -> server/web/b
https://checkoutweb.localhost:8443  -> server/web/c
```

`*.localhost` resolves to loopback; do not edit `/etc/hosts`. The Python server routes content using the HTTP `Host` header.

Important pages:

```text
Paypalweb direct balance: /direct.html
Balance iframe root:     /iframe.html
Send Money iframe root:  /send-money-iframe.html
Paypalweb balance:       /balance.html
Paypalweb send money:    /send-money.html
Nested iframe root:      /multilevel.html
PayPal Sandbox root:     /paypal-sandbox-container.html
Paypalweb nested page:   /nested.html
PayPal SDK wrapper:      /paypal-sandbox-checkout.html
Checkoutweb deep frame:  /deep.html
```

## How frame collection works

1. `WKUserScript` is configured with `forMainFrameOnly: false`.
2. The script immediately refuses non-local hostnames.
3. Each permitted frame gets a stable UUID and computes its depth.
4. Input/change listeners, a `MutationObserver`, and a 700 ms timer publish snapshots.
5. `WKScriptMessage.frameInfo` lets native code associate the snapshot with its frame.
6. The DEBUG panel defaults to a compact highlighted summary. `More` displays URL, origin, frame ID, body text, and full HTML.
7. The DEBUG `Tabs` menu controls which demo pages appear in the native tab bar; it always keeps at least one page visible and includes `Show All`.
8. Opening DEBUG docks the WebView above the panel instead of covering it and scrolls the first editable field or iframe into view, so web inputs remain reachable during live inspection.

PayPal Sandbox pages use explicit `[data-native-summary]` text and strict-origin `postMessage`, so the compact UI shows results such as:

```text
buttons-rendered · sandbox · USD 1.00
```

Do not replace this flow with PayPal DOM, credential, Cookie, or password extraction.

## Quick validation

Before opening Xcode, confirm local routing:

```bash
curl -ksS --resolve samsungweb.localhost:8443:127.0.0.1 \
  https://samsungweb.localhost:8443/multilevel.html

curl -ksS --resolve paypalweb.localhost:8443:127.0.0.1 \
  https://paypalweb.localhost:8443/paypal-sandbox-checkout.html

curl -ksS --resolve checkoutweb.localhost:8443:127.0.0.1 \
  https://checkoutweb.localhost:8443/deep.html
```

Expected automated test result: two tests, zero failures.

Expected visual checks:

- All five tabs are visible.
- Balance and Send Money are separate native tabs, and each renders exactly one cross-origin iframe.
- DEBUG count is `2` in both Balance and Send Money.
- The Send Money iframe contains exactly one amount input and updates the compact DEBUG result while typing.
- The nested tab renders Samsungweb, Paypalweb, and Checkoutweb.
- DEBUG count is `3` for the nested demo.
- PayPal Sandbox renders official PayPal test buttons.
- DEBUG count is `2` for PayPal Sandbox and compact content fits without scrolling.
- Tapping `More` shows full details; `Less` returns to the compact view.
- The DEBUG `Tabs` menu can hide and restore each demo page independently; hiding the active page selects the first remaining page.
- With DEBUG open, the Send Money amount input remains reachable by scrolling and live changes still appear in the native result.

## Common failures

- **Page load error:** ensure `./server/start.sh` is still running.
- **Certificate error:** boot the simulator first, stop the server, then rerun `./server/start.sh` so the certificate is installed.
- **Port 8443 already used:** find the existing demo server and reuse or stop that exact process; do not kill unrelated Python processes.
- **PayPal buttons missing:** verify internet access and that `https://www.paypal.com/sdk/js?client-id=test` returns successfully.
- **Stale app in Simulator:** rebuild, reinstall the `.app`, and launch with `--terminate-running-process`.
- **New local domain fails TLS:** add it to the certificate SAN and routing map, then increment `CERT_VERSION` in `server/https_server.py` to force certificate regeneration.

## Change discipline

- Keep all user-facing UI and demo pages in English unless explicitly requested otherwise.
- Preserve dynamic updates and the compact default DEBUG presentation.
- Keep `More` as the only place for verbose HTML/frame metadata.
- Update `README.md`, `WebDemoConfiguration.swift`, tests, certificate SANs, and this guide when adding or renaming an origin.
- Never commit generated certificates, secrets, real account data, or simulator artifacts.
- After Swift changes, run the full `xcodebuild ... test` command above and visually verify the affected launch mode.
