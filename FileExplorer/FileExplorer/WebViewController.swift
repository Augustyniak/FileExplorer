//
//  WebViewController.swift
//  FileExplorer
//
//  Created by Rafal Augustyniak on 27/11/2016.
//  Copyright (c) 2016 Rafal Augustyniak
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import WebKit
import GoogleMobileAds

class WebViewController: UIViewController, WKNavigationDelegate {
    let url: URL
    var interstitial: GADInterstitial!
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.edges(equalTo: view)
        webView.loadFileURL(url, allowingReadAccessTo: url)
        webView.navigationDelegate = self
        //interstitial = createAndLoadInterstitial()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //callAds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    
    }
    
    
    func callAds(){
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
          print("Ad wasn't ready")
        }
    }
}

extension WebViewController: GADInterstitialDelegate{
    public func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        //self.interstitial.present(fromRootViewController: self)
    }
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: )
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }

    public func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
        //navigationController?.popViewController(animated: true)
    }
}
