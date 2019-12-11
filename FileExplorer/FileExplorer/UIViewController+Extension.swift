//
//  UIViewController+Extension.swift
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

extension UIViewController {
    @nonobjc static var kActivityIndicatorKey = "fer_activityIndicatorView"
    @objc var activityIndicatorView: UIActivityIndicatorView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.kActivityIndicatorKey) as? UIActivityIndicatorView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UIViewController.kActivityIndicatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    @objc func showLoadingIndicator() {
        guard self.activityIndicatorView == nil else { return }
        
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .gray
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        activityIndicatorView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        activityIndicatorView.startAnimating()
    }
    
    @objc func hideLoadingIndicator() {
        self.activityIndicatorView?.stopAnimating()
        UIView.animate(withDuration: 0.2, animations: {
            self.activityIndicatorView?.alpha = 0.0
        }) { finished in
            self.activityIndicatorView?.removeFromSuperview()
            self.activityIndicatorView = nil
        }
    }
}

extension UIViewController {
    @objc var activeRightBarButtonItem: UIBarButtonItem? {
        get {
            return activeNavigationItem?.rightBarButtonItem
        }
        
        set(newValue) {
            navigationItem.rightBarButtonItem = newValue
            activeNavigationItem?.rightBarButtonItem = newValue
        }
    }
    
    @objc var activeNavigationItemTitle: String? {
        get {
            return activeNavigationItem?.title
        }
        set(newValue) {
            navigationItem.title = newValue
            activeNavigationItem?.title = newValue
        }
    }
    
    @objc var activeNavigationItem: UINavigationItem? {
        guard let viewController = navigationController?.topViewController else { return nil }
        
        if viewController.navigationItem === navigationItem {
            return navigationItem
        } else {
            return parent?.activeNavigationItem
        }
    }
}

extension UIViewController {
    @objc func addContentChildViewController(_ content: UIViewController, insets: UIEdgeInsets = UIEdgeInsets.zero) {
        view.addSubview(content.view)
        addChild(content)
        content.view.frame = view.bounds.inset(by: insets)
        content.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        content.didMove(toParent: self)
    }
}
