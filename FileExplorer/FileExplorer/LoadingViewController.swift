//
//  LoadingViewController.swift
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

final class LoadingViewController<T>: UIViewController {
    init(load: @escaping (@escaping (Result<LoadedItem<T>>) -> ()) -> (), builder: @escaping (LoadedItem<T>) -> UIViewController?) {
        super.init(nibName: nil, bundle: nil)
        
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []
        
        showLoadingIndicator()
        load({ [weak self] result in
            guard let strongSelf = self else { return }
            
            strongSelf.hideLoadingIndicator()

            switch result {
            case .success(let item):
                let contentViewController = builder(item)!
                
                strongSelf.addContentChildViewController(contentViewController)
                strongSelf.navigationItem.title = contentViewController.navigationItem.title
                strongSelf.navigationItem.rightBarButtonItems = contentViewController.navigationItem.rightBarButtonItems
                strongSelf.navigationItem.leftBarButtonItems = contentViewController.navigationItem.leftBarButtonItems
                strongSelf.extendedLayoutIncludesOpaqueBars = contentViewController.extendedLayoutIncludesOpaqueBars
                strongSelf.edgesForExtendedLayout = contentViewController.edgesForExtendedLayout
            case .error(let error):
                UIAlertController.presentAlert(for: error, in: strongSelf)
            }
        })
    }
    
    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
    }
}

extension LoadingViewController {
    static func make(item: Item<Any>?, fileService: FileService = LocalStorageFileService(), builder: @escaping (LoadedItem<Any>) -> UIViewController?) -> LoadingViewController<Any> {
        return LoadingViewController<Any>(load: { completionBlock in
            guard let item = item else {
                completionBlock(Result.error(CustomErrors.nilItem))
                return
            }
            fileService.load(item: item, completionBlock: completionBlock)
        }, builder: builder)
    }
}
