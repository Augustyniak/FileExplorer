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
    @nonobjc static let kActivityIndicatorKey = "fer_activityIndicatorView"
    var activityIndicatorView: UIActivityIndicatorView? {
        get {
            return objc_getAssociatedObject(self, UIViewController.kActivityIndicatorKey) as? UIActivityIndicatorView
        }
        set(newValue) {
            objc_setAssociatedObject(self, UIViewController.kActivityIndicatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func showLoadingIndicator() {
        guard self.activityIndicatorView == nil else {
            return
        }
        
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.alpha = 0.0
        activityIndicatorView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        UIView.animate(withDuration: 0.2) { 
            activityIndicatorView.alpha = 1.0
        }
    }
    
    func hideLoadingIndicator() {
        UIView.animate(withDuration: 0.2, animations: {
            self.activityIndicatorView?.alpha = 0.0
        }) { finished in
            self.activityIndicatorView?.removeFromSuperview()
            self.activityIndicatorView = nil
        }
    }
}

extension UIViewController {
    func setRightBarButtonItemRecursively(_ barButtonItem: UIBarButtonItem?) {
        var viewController: UIViewController? = self
        while viewController != nil {
            viewController?.navigationItem.rightBarButtonItem = barButtonItem
            if viewController?.navigationItem === navigationController?.navigationItem {
                break
            }
            viewController = viewController?.parent
        }
    }
    
    func setNavigationItemTitleRecursively(_ title: String) {
        var viewController: UIViewController? = self
        while viewController != nil {
            viewController?.navigationItem.title = title
            if viewController?.navigationItem === navigationController?.navigationItem {
                break
            }
            viewController = viewController?.parent
        }
    }
}

extension UIViewController {
    func addContentChildViewController(_ content: UIViewController, insets: UIEdgeInsets = UIEdgeInsets.zero) {
        addChildViewController(content)
        view.addSubview(content.view)
        content.view.frame = UIEdgeInsetsInsetRect(view.bounds, insets)
        content.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        content.didMove(toParentViewController: self)
    }
}
