import UIKit
@preconcurrency import WebKit

final class DirectWebViewController: WebInspectorViewController {
    init() {
        super.init(
            pageTitle: "Direct PayPal",
            url: WebDemoConfiguration.directPageURL
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BalanceIframeViewController: WebInspectorViewController {
    init() {
        super.init(
            pageTitle: "Balance iframe",
            url: WebDemoConfiguration.balanceContainerURL
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SendMoneyIframeViewController: WebInspectorViewController {
    init() {
        super.init(
            pageTitle: "Send Money iframe",
            url: WebDemoConfiguration.sendMoneyContainerURL
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MultiLevelIframeViewController: WebInspectorViewController {
    init() {
        super.init(
            pageTitle: "Multi-Level iframe",
            url: WebDemoConfiguration.multiLevelPageURL
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PayPalSandboxViewController: WebInspectorViewController {
    init() {
        super.init(
            pageTitle: "PayPal Sandbox",
            url: WebDemoConfiguration.paypalSandboxPageURL
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WebInspectorViewController: UIViewController {
    private let pageURL: URL
    private var snapshots: [String: FrameSnapshot] = [:]
    private var frames: [String: WKFrameInfo] = [:]
    private var isDebugPanelPresented = false
    private var isShowingFullDetails = false
    private var debugButtonToSafeAreaConstraint: NSLayoutConstraint!
    private var debugButtonToPanelConstraint: NSLayoutConstraint!
    private var webViewToSafeAreaConstraint: NSLayoutConstraint!
    private var webViewToDebugButtonConstraint: NSLayoutConstraint!

    private lazy var webView: WKWebView = {
        let contentController = WKUserContentController()
        contentController.addUserScript(
            WKUserScript(
                source: Self.frameCollectorJavaScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
        )
        contentController.add(self, name: "frameSnapshot")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.websiteDataStore = .nonPersistent()

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.allowsBackForwardNavigationGestures = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.text = "Waiting for the page to load…"
        return label
    }()

    private let debugPanel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.18
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = CGSize(width: 0, height: -4)
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    private let debugButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "DEBUG (0)"
        configuration.image = UIImage(systemName: "ladybug.fill")
        configuration.imagePadding = 6
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .systemIndigo

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Show web debug information"
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 6
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        return button
    }()

    private let resultView: UITextView = {
        let view = UITextView()
        view.isEditable = false
        view.backgroundColor = .secondarySystemBackground
        view.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        view.text = "Native inspection results will appear here."
        view.layer.cornerRadius = 10
        view.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        return view
    }()

    private let detailsButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "More"
        configuration.buttonSize = .small
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = "Show full web debug details"
        return button
    }()

    private let tabVisibilityButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Tabs"
        configuration.image = UIImage(systemName: "rectangle.stack")
        configuration.imagePadding = 5
        configuration.buttonSize = .small
        let button = UIButton(configuration: configuration)
        button.accessibilityLabel = "Choose visible demo tabs"
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    init(pageTitle: String, url: URL) {
        pageURL = url
        super.init(nibName: nil, bundle: nil)
        title = pageTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Inspect", style: .plain, target: self, action: #selector(readAllFrames)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadPage))
        ]
        debugButton.addTarget(self, action: #selector(toggleDebugPanel), for: .touchUpInside)
        detailsButton.addTarget(self, action: #selector(toggleDetails), for: .touchUpInside)
        setupLayout()
        loadPage()

        if ProcessInfo.processInfo.arguments.contains("--debug") {
            DispatchQueue.main.async { [weak self] in
                self?.toggleDebugPanel()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTabVisibilityMenu()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "frameSnapshot")
    }

    private func setupLayout() {
        let resultHeader = UILabel()
        resultHeader.text = "Captured Content"
        resultHeader.font = .preferredFont(forTextStyle: .headline)

        let liveLabel = UILabel()
        liveLabel.text = "● LIVE"
        liveLabel.textColor = .systemGreen
        liveLabel.font = .preferredFont(forTextStyle: .caption1)

        let headerStack = UIStackView(arrangedSubviews: [resultHeader, UIView(), liveLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8

        let controlsStack = UIStackView(arrangedSubviews: [tabVisibilityButton, detailsButton, UIView()])
        controlsStack.axis = .horizontal
        controlsStack.alignment = .center
        controlsStack.spacing = 8

        let resultStack = UIStackView(arrangedSubviews: [headerStack, controlsStack, stateLabel, resultView])
        resultStack.axis = .vertical
        resultStack.spacing = 8
        resultStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        view.addSubview(debugPanel)
        debugPanel.addSubview(resultStack)
        view.addSubview(debugButton)

        debugButtonToSafeAreaConstraint = debugButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -16
        )
        debugButtonToPanelConstraint = debugButton.bottomAnchor.constraint(
            equalTo: debugPanel.topAnchor,
            constant: -8
        )
        webViewToSafeAreaConstraint = webView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )
        webViewToDebugButtonConstraint = webView.bottomAnchor.constraint(
            equalTo: debugButton.topAnchor,
            constant: -8
        )

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewToSafeAreaConstraint,

            debugPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            debugPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            debugPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            debugPanel.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.36),

            resultStack.topAnchor.constraint(equalTo: debugPanel.topAnchor, constant: 14),
            resultStack.leadingAnchor.constraint(equalTo: debugPanel.leadingAnchor, constant: 12),
            resultStack.trailingAnchor.constraint(equalTo: debugPanel.trailingAnchor, constant: -12),
            resultStack.bottomAnchor.constraint(equalTo: debugPanel.bottomAnchor, constant: -12),

            debugButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            debugButtonToSafeAreaConstraint
        ])
    }

    func refreshTabVisibilityMenu() {
        tabVisibilityButton.menu = (tabBarController as? RootTabBarController)?.makeTabVisibilityMenu()
    }

    @objc private func toggleDebugPanel() {
        isDebugPanelPresented.toggle()
        updateDebugButton()
        view.layoutIfNeeded()

        if isDebugPanelPresented {
            debugPanel.isHidden = false
            webViewToSafeAreaConstraint.isActive = false
            debugButtonToSafeAreaConstraint.isActive = false
            debugButtonToPanelConstraint.isActive = true
            webViewToDebugButtonConstraint.isActive = true
            readAllFrames()

            UIView.animate(withDuration: 0.25, animations: {
                self.debugPanel.alpha = 1
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.revealInteractiveWebContent()
            })
        } else {
            webViewToDebugButtonConstraint.isActive = false
            debugButtonToPanelConstraint.isActive = false
            webViewToSafeAreaConstraint.isActive = true
            debugButtonToSafeAreaConstraint.isActive = true

            UIView.animate(withDuration: 0.25, animations: {
                self.debugPanel.alpha = 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.debugPanel.isHidden = true
            })
        }
    }

    private func revealInteractiveWebContent() {
        let script = #"""
        (() => {
          const field = Array.from(document.querySelectorAll('input, textarea, select'))
            .find((element) => element.type !== 'hidden' && !element.disabled);
          const target = field || document.querySelector('iframe');
          target?.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'nearest' });
        })();
        """#
        webView.evaluateJavaScript(script)
    }

    private func updateDebugButton(hasError: Bool = false) {
        var configuration = debugButton.configuration
        let action = isDebugPanelPresented ? "CLOSE DEBUG" : "DEBUG"
        configuration?.title = "\(action) (\(snapshots.count))"
        configuration?.baseBackgroundColor = hasError ? .systemRed : .systemIndigo
        debugButton.configuration = configuration
    }

    @objc private func toggleDetails() {
        isShowingFullDetails.toggle()
        var configuration = detailsButton.configuration
        configuration?.title = isShowingFullDetails ? "Less" : "More"
        detailsButton.configuration = configuration
        detailsButton.accessibilityLabel = isShowingFullDetails
            ? "Show concise web debug information"
            : "Show full web debug details"
        renderSnapshots()
    }

    private func loadPage() {
        stateLabel.text = "Loading \(pageURL.absoluteString)"
        webView.load(URLRequest(url: pageURL))
    }

    @objc private func reloadPage() {
        snapshots.removeAll()
        frames.removeAll()
        resultView.text = "Reloading the page…"
        updateDebugButton()
        webView.reload()
    }

    @objc private func readAllFrames() {
        guard !frames.isEmpty else {
            stateLabel.text = "No frames found. Make sure the local HTTPS server is running."
            return
        }

        stateLabel.text = "Inspecting the DOM in \(frames.count) frame(s)…"
        for frame in frames.values {
            webView.evaluateJavaScript(
                "window.__nativeCollectFrameSnapshot && window.__nativeCollectFrameSnapshot(true)",
                in: frame,
                in: .page
            ) { [weak self] result in
                if case let .failure(error) = result {
                    self?.stateLabel.text = "Inspection failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func renderSnapshots() {
        let sorted = snapshots.values.sorted {
            if $0.depth != $1.depth { return $0.depth < $1.depth }
            return $0.url < $1.url
        }

        stateLabel.numberOfLines = 1
        stateLabel.text = "\(sorted.count) frame(s) · Live updating"
        if isShowingFullDetails {
            resultView.attributedText = NSAttributedString(
                string: sorted.map(\.detailedText).joined(separator: "\n\n────────────────────\n\n"),
                attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.label
                ]
            )
        } else {
            let rendered = NSMutableAttributedString()
            for (index, snapshot) in sorted.enumerated() {
                if index > 0 {
                    rendered.append(
                        NSAttributedString(
                            string: "\n\n",
                            attributes: [
                                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                                .foregroundColor: UIColor.tertiaryLabel
                            ]
                        )
                    )
                }
                rendered.append(snapshot.summaryAttributedText)
            }
            resultView.attributedText = rendered
            resultView.setContentOffset(.zero, animated: false)
        }
        updateDebugButton()
    }

    private static let frameCollectorJavaScript = #"""
    (() => {
      // Never inspect third-party frames. PayPal communicates supported
      // checkout state through its documented callbacks/postMessage flow.
      const isLocalTestFrame = location.hostname.endsWith('.localhost')
        || location.hostname === 'localhost'
        || location.hostname === '127.0.0.1';
      if (!isLocalTestFrame) return;

      let lastSnapshot = '';
      const frameId = crypto.randomUUID();

      const frameDepth = () => {
        let depth = 0;
        let current = window;
        try {
          while (current !== current.top && depth < 32) {
            depth += 1;
            current = current.parent;
          }
        } catch (_) {
          // Cross-origin WindowProxy still exposes parent/top in WebKit, but
          // retain the depth reached if a future policy restricts traversal.
        }
        return depth;
      };

      const collect = (force = false) => {
        const fields = Array.from(document.querySelectorAll('input, textarea, select')).map((element) => ({
          tag: element.tagName.toLowerCase(),
          id: element.id || '',
          name: element.name || '',
          type: element.type || '',
          value: element.value ?? '',
          placeholder: element.placeholder || ''
        }));

        const bodyText = document.body ? document.body.innerText : '';
        const explicitSummary = Array.from(document.querySelectorAll('[data-native-summary]'))
          .map((element) => (element.value ?? element.textContent ?? '').trim())
          .filter(Boolean)
          .join(' · ');

        const snapshot = {
          frameId,
          depth: frameDepth(),
          url: location.href,
          origin: location.origin,
          title: document.title,
          bodyText,
          summaryText: explicitSummary || bodyText,
          html: document.documentElement ? document.documentElement.outerHTML : '',
          fields
        };

        const serialized = JSON.stringify(snapshot);
        if (!force && serialized === lastSnapshot) return;
        lastSnapshot = serialized;
        window.webkit.messageHandlers.frameSnapshot.postMessage(snapshot);
      };

      window.__nativeCollectFrameSnapshot = collect;
      document.addEventListener('input', collect, true);
      document.addEventListener('change', collect, true);
      window.addEventListener('load', () => setTimeout(collect, 50));
      new MutationObserver(() => collect()).observe(document.documentElement, {
        subtree: true,
        childList: true,
        characterData: true,
        attributes: true
      });
      setInterval(collect, 700);
      collect();
    })();
    """#
}

extension WebInspectorViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "frameSnapshot",
              let snapshot = FrameSnapshot(message: message) else { return }

        snapshots[snapshot.key] = snapshot
        frames[snapshot.key] = message.frameInfo
        NSLog(
            "Native collected depth %d %@: %@",
            snapshot.depth,
            snapshot.isMainFrame ? "main frame" : "iframe",
            snapshot.url
        )
        renderSnapshots()
    }
}

extension WebInspectorViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        stateLabel.text = "WebView is loading…"
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if snapshots.isEmpty {
            stateLabel.text = "Page loaded. Waiting for each frame to report its DOM."
        } else {
            renderSnapshots()
        }
        if isDebugPanelPresented {
            DispatchQueue.main.async { [weak self] in
                self?.revealInteractiveWebContent()
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showNavigationError(error)
    }

    private func showNavigationError(_ error: Error) {
        stateLabel.text = "Load failed: \(error.localizedDescription)"
        resultView.text = "Start the local server from the repository root:\n\n./server/start.sh"
        updateDebugButton(hasError: true)
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host.lowercased()
        let isAllowedDevelopmentHost = WebDemoConfiguration.isAllowedDevelopmentHost(host)
        NSLog(
            "WKWebView authentication challenge: method=%@ host=%@",
            challenge.protectionSpace.authenticationMethod,
            host
        )

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           isAllowedDevelopmentHost,
           let trust = challenge.protectionSpace.serverTrust {
            // Local simulator demo only. Never bypass certificate validation in production.
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

private struct FrameSnapshot {
    let key: String
    let isMainFrame: Bool
    let frameId: String
    let depth: Int
    let url: String
    let origin: String
    let title: String
    let bodyText: String
    let summaryText: String
    let html: String
    let fields: [[String: Any]]
    let updatedAt: Date

    init?(message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let url = body["url"] as? String else { return nil }

        isMainFrame = message.frameInfo.isMainFrame
        frameId = body["frameId"] as? String ?? "\(url)|\(isMainFrame)"
        depth = (body["depth"] as? NSNumber)?.intValue ?? (isMainFrame ? 0 : 1)
        self.url = url
        origin = body["origin"] as? String ?? ""
        title = body["title"] as? String ?? ""
        bodyText = body["bodyText"] as? String ?? ""
        summaryText = body["summaryText"] as? String ?? bodyText
        html = body["html"] as? String ?? ""
        fields = body["fields"] as? [[String: Any]] ?? []
        updatedAt = Date()
        key = frameId
    }

    var summaryAttributedText: NSAttributedString {
        let kind = isMainFrame ? "MAIN" : "IFRAME"
        let baseFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let boldFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let result = NSMutableAttributedString()

        result.append(
            NSAttributedString(
                string: "\(kind) · DEPTH \(depth)\n\(title)",
                attributes: [
                    .font: boldFont,
                    .foregroundColor: UIColor.systemIndigo
                ]
            )
        )

        if !fields.isEmpty {
            result.append(NSAttributedString(string: "\nValues: ", attributes: [.font: boldFont]))
            for (index, field) in fields.enumerated() {
                let tag = field["tag"] as? String ?? "?"
                let label = (field["name"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    ?? (field["id"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    ?? tag
                let value = field["value"] as? String ?? ""
                result.append(
                    NSAttributedString(
                        string: "\(label)=",
                        attributes: [.font: baseFont, .foregroundColor: UIColor.secondaryLabel]
                    )
                )
                result.append(
                    NSAttributedString(
                        string: value.isEmpty ? "(empty)" : value,
                        attributes: [
                            .font: boldFont,
                            .foregroundColor: UIColor.label,
                            .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.32)
                        ]
                    )
                )
                if index < fields.count - 1 {
                    result.append(NSAttributedString(string: " · "))
                }
            }
        }

        let normalizedContent = summaryText
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        let previewLimit = 90
        let contentPreview: String
        if normalizedContent.count > previewLimit {
            contentPreview = String(normalizedContent.prefix(previewLimit)) + "…"
        } else {
            contentPreview = normalizedContent.isEmpty ? "(empty)" : normalizedContent
        }

        result.append(NSAttributedString(string: "\n"))
        result.append(
            NSAttributedString(
                string: "Content: ",
                attributes: [
                    .font: boldFont,
                    .foregroundColor: UIColor.systemGreen
                ]
            )
        )
        result.append(
            NSAttributedString(
                string: contentPreview,
                attributes: [
                    .font: baseFont,
                    .foregroundColor: UIColor.label,
                    .backgroundColor: UIColor.systemGreen.withAlphaComponent(0.16)
                ]
            )
        )
        return result
    }

    var detailedText: String {
        let kind = isMainFrame ? "MAIN FRAME" : "IFRAME"
        let fieldText = fields.enumerated().map { index, field in
            let tag = field["tag"] as? String ?? "?"
            let id = field["id"] as? String ?? ""
            let name = field["name"] as? String ?? ""
            let value = field["value"] as? String ?? ""
            return "  \(index + 1). <\(tag)> id=\(id) name=\(name) value=\(value)"
        }.joined(separator: "\n")

        return """
        [\(kind) · DEPTH \(depth)]
        Frame ID: \(frameId)
        URL: \(url)
        Origin: \(origin)
        Title: \(title)
        Updated: \(updatedAt.formatted(date: .omitted, time: .standard))

        Form fields (\(fields.count)):
        \(fieldText.isEmpty ? "  None" : fieldText)

        Body text:
        \(bodyText)

        Full HTML:
        \(html)
        """
    }
}
