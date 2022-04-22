//
//  
//  WebscreenViewController.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 26.01.2022.
//
//

import UIKit
import Combine
import WebKit

final class WebscreenViewController: UIViewController {
    enum Content {
        case privacy
        case terms
    }
    enum State {
        case configure(contentType: WebscreenViewController.Content)
    }
        
    @IBOutlet weak var topBarContainer: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    private let viewModel: WebscreenViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: WebscreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: WebscreenViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        handleActions()
        configureView()
        viewModel.input.send(.requestState)
    }
}

private extension WebscreenViewController {
    
    func handleActions() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .configure(let contentType):
                self.titleLabel.text = contentType != .terms ? "Политика конфиденциальности" : "Условия использования"
                let url = Bundle.main.url(forResource: contentType != .terms ? "privacy" : "terms", withExtension: "html")!
                //let termsURL = Bundle.main.url(forResource: "terms", withExtension: "html")!
                self.webView.loadFileURL(url, allowingReadAccessTo: url)
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        })
        .store(in: &bag)
        
        backButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).store(in: &bag)
    }
    
    func configureView() {
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        webView.navigationDelegate = self
    }
}

extension WebscreenViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}
