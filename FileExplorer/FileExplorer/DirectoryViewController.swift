//
//  DirectoryViewController.swift
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

final class DirectoryViewModel {
    fileprivate let finishButtonHidden: Bool

    private let url: URL
    private let item: LoadedDirectoryItem
    private let fileSpecifications: FileSpecifications
    private let configuration: Configuration

    init(url: URL, item: LoadedDirectoryItem, fileSpecifications: FileSpecifications, configuration: Configuration, finishButtonHidden: Bool) {
        self.url = url
        self.item = item
        self.fileSpecifications = fileSpecifications
        self.configuration = configuration
        self.finishButtonHidden = finishButtonHidden
    }

    var finishButtonTitle: String {
        if configuration.actionsConfiguration.canChooseFiles || configuration.actionsConfiguration.canChooseDirectories {
            return NSLocalizedString("Cancel", comment: "")
        } else {
            return NSLocalizedString("Done", comment: "")
        }
    }

    func makeDirectoryContentViewModel() -> DirectoryContentViewModel {
        return DirectoryContentViewModel(item: item, fileSpecifications: fileSpecifications, configuration: configuration)
    }
}

protocol DirectoryViewControllerDelegate: class {
    func directoryViewController(_ controller: DirectoryViewController, didSelectItem item: Item<Any>)
    func directoryViewController(_ controller: DirectoryViewController, didSelectItemDetails item: Item<Any>)
    func directoryViewController(_ controller: DirectoryViewController, didChooseItems items: [Item<Any>])
    func directoryViewControllerDidFinish(_ controller: DirectoryViewController)
}

final class DirectoryViewController: UIViewController {
    weak var delegate: DirectoryViewControllerDelegate?

    fileprivate let viewModel: DirectoryViewModel

    fileprivate let searchController: UISearchController
    fileprivate let searchResultsController: DirectoryContentViewController
    fileprivate let searchResultsViewModel: DirectoryContentViewModel

    fileprivate let directoryContentViewController: DirectoryContentViewController
    fileprivate let directoryContentViewModel: DirectoryContentViewModel

    init(viewModel: DirectoryViewModel) {
        self.viewModel = viewModel
        
        searchResultsViewModel = viewModel.makeDirectoryContentViewModel()
        searchResultsController = DirectoryContentViewController(viewModel: searchResultsViewModel)
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController

        directoryContentViewModel = viewModel.makeDirectoryContentViewModel()
        directoryContentViewController = DirectoryContentViewController(viewModel: directoryContentViewModel)

        super.init(nibName: nil, bundle: nil)

        searchResultsController.delegate = self
        directoryContentViewController.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []
        
        setUpSearchBarController()
        addContentChildViewController(directoryContentViewController, insets: UIEdgeInsets(top: searchController.searchBar.bounds.height, left: 0.0, bottom: 0.0, right: 0.0))
        navigationItem.rightBarButtonItem = directoryContentViewController.navigationItem.rightBarButtonItem
        navigationItem.title = directoryContentViewController.navigationItem.title
        view.sendSubviewToBack(directoryContentViewController.view)
        setUpLeftBarButtonItem()
    }

    @objc func setUpSearchBarController() {
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.autoresizingMask = [.flexibleWidth]
        searchBar.delegate = self
        view.addSubview(searchBar)
        navigationItem.rightBarButtonItems = directoryContentViewController.navigationItem.rightBarButtonItems
    }

    @objc func setUpLeftBarButtonItem() {
        if !viewModel.finishButtonHidden {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: viewModel.finishButtonTitle, style: .plain, target: self, action: #selector(handleFinishButtonTap))
        }
    }

    @objc var isSearchControllerActive: Bool {
        get {
            return searchController.isActive
        }
        set(newValue) {
            searchController.isActive = newValue
        }
    }
    
    // MARK: Actions

    @objc func handleFinishButtonTap() {
        delegate?.directoryViewControllerDidFinish(self)
    }
}

extension DirectoryViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        directoryContentViewController.setEditing(false, animated: true)
        searchResultsViewModel.sortMode = directoryContentViewModel.sortMode
    }
}

extension DirectoryViewController: DirectoryContentViewControllerDelegate {
    @objc func directoryContentViewController(_ controller: DirectoryContentViewController, didChangeEditingStatus isEditing: Bool) {
        searchController.searchBar.isEnabled = !isEditing
    }

    func directoryContentViewController(_ controller: DirectoryContentViewController, didSelectItem item: Item<Any>) {
        delegate?.directoryViewController(self, didSelectItem: item)
    }

    func directoryContentViewController(_ controller: DirectoryContentViewController, didSelectItemDetails item: Item<Any>) {
        delegate?.directoryViewController(self, didSelectItemDetails: item)
    }
    
    func directoryContentViewController(_ controller: DirectoryContentViewController, didChooseItems items: [Item<Any>]) {
        delegate?.directoryViewController(self, didChooseItems: items)
    }
}
