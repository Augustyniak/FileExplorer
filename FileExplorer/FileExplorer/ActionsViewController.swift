//
//  ActionsViewController.swift
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

import UIKit

protocol ActionsViewControllerDelegate: class {
    func actionsViewControllerDidRequestRemoval(_ controller: ActionsViewController)
    func actionsViewControllerDidRequestShare(_ controller: ActionsViewController)
}

final class ActionsViewController: UIViewController {
    weak var delegate: ActionsViewControllerDelegate?

    private let toolbar = UIToolbar()
    private let contentViewController: UIViewController

    @objc init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []

        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.sizeToFit()
        toolbar.pinToBottom(of: view)
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(handleShareButtonTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(handleTrashButtonTap))
        ]

        addContentChildViewController(contentViewController, insets: UIEdgeInsets(top: 0, left: 0, bottom: toolbar.bounds.height, right: 0))
        navigationItem.title = contentViewController.navigationItem.title
    }

    // MARK: Actions
    
    @objc
    private func handleShareButtonTap() {
        delegate?.actionsViewControllerDidRequestShare(self)
    }

    @objc
    private func handleTrashButtonTap() {
        delegate?.actionsViewControllerDidRequestRemoval(self)
    }
}
