//
//  UISearchBar+Extension.swift
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

extension UISearchBar {
    @nonobjc static var kDimmingView = "dimmingView"

    @objc var dimmingView: UIView? {
        get {
            return objc_getAssociatedObject(self, &UISearchBar.kDimmingView) as? UIView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UISearchBar.kDimmingView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc var isEnabled: Bool {
        get {
            return dimmingView != nil
        }
        set(newValue) {
            if newValue {
                dimmingView?.removeFromSuperview()
                dimmingView = nil
            } else {
                let dimmingView = UIView(frame: bounds)
                dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
                addSubview(dimmingView)
                self.dimmingView = dimmingView
            }
            isUserInteractionEnabled = newValue
        }
    }
}
