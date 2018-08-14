//
//  InstagramLoginViewController.swift
//  SwiftInstagram
//
//  Created by Ander Goig on 8/9/17.
//  Copyright © 2017 Ander Goig. All rights reserved.
//

import UIKit
import WebKit

class InstagramLoginViewController: UIViewController {

    // MARK: - Types

    typealias SuccessHandler = (_ accesToken: String) -> Void
    typealias FailureHandler = (_ error: InstagramError) -> Void

    // MARK: - Properties

    var leftButton: UIBarButtonItem?
    var rightButton: UIBarButtonItem?
    var progressMarginTop: CGFloat = 0
    
    private var authURL: URL
    private var success: SuccessHandler?
    private var failure: FailureHandler?

    private var progressView: UIProgressView!
    private var webViewObservation: NSKeyValueObservation!

    // MARK: - Initializers

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(authURL: URL, success: SuccessHandler?, failure: FailureHandler?) {
        self.authURL = authURL
        self.success = success
        self.failure = failure

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        // Initializes web view
        let webView = setupWebView()
        
        // Initializes progress view
        setupProgressView()
        setupNavigationItem()

        // Starts authorization
        webView.load(URLRequest(url: authURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    }

    deinit {
        progressView.removeFromSuperview()
        webViewObservation.invalidate()
    }

    // MARK: -

    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progress = 0.0
        progressView.tintColor = UIColor(red: 0.88, green: 0.19, blue: 0.42, alpha: 1.0)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(progressView)

        let bottomConstraint = view.topAnchor.constraint(equalTo: progressView.topAnchor, constant: progressMarginTop)
        let leftConstraint = view.leadingAnchor.constraint(equalTo: progressView.leadingAnchor)
        let rightConstraint = view.trailingAnchor.constraint(equalTo: progressView.trailingAnchor)

        NSLayoutConstraint.activate([bottomConstraint, leftConstraint, rightConstraint])
    }
    
    private func setupNavigationItem() {
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
    }

    private func setupWebView() -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent()

        let frame = CGRect(x: 0, y: -progressMarginTop, width: view.bounds.size.width, height: view.bounds.size.height + progressMarginTop)
        let webView = WKWebView(frame: frame, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self

        webViewObservation = webView.observe(\.estimatedProgress, changeHandler: progressViewChangeHandler)

        view.addSubview(webView)

        return webView
    }

    private func progressViewChangeHandler<Value>(webView: WKWebView, change: NSKeyValueObservedChange<Value>) {
        progressView.alpha = 1.0
        progressView.setProgress(Float(webView.estimatedProgress), animated: true)

        if webView.estimatedProgress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
                self.progressView.alpha = 0.0
            }, completion: { (_ finished) in
                self.progressView.progress = 0
            })
        }
    }

}

// MARK: - WKNavigationDelegate

extension InstagramLoginViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationItem.title = webView.title
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let urlString = navigationAction.request.url!.absoluteString

        guard let range = urlString.range(of: "#access_token=") else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)

        DispatchQueue.main.async {
            self.success?(String(urlString[range.upperBound...]))
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        guard let httpResponse = navigationResponse.response as? HTTPURLResponse else {
            decisionHandler(.allow)
            return
        }

        switch httpResponse.statusCode {
        case 400:
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                self.failure?(InstagramError.badRequest)
            }
        default:
            decisionHandler(.allow)
        }
    }
}
