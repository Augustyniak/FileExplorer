//
//  FileExplorerViewController.swift
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

/// The FileExplorerViewControllerDelegate protocol defines methods that your delegate object must implement to interact with the file explorer interface. The methods of this protocol notify your delegate when the user chooses files and/or directories, or finishes the file explorer presentation operation.
public protocol FileExplorerViewControllerDelegate: class {

    /// Tells the delegate that the user finished presentation of the file explorer.
    ///
    /// - Parameter controller: The controller object managing the file explorer interface.
    func fileExplorerViewControllerDidFinish(_ controller: FileExplorerViewController)

    /// Tells the delegate that the user chose files and/or directories.
    ///
    /// File explorer hides itself after uses chooses files and/or directories.
    /// - Parameters:
    ///   - controller: The controller object managing the file explorer interface.
    ///   - urls: URLs choosen by users.
    func fileExplorerViewController(_ controller: FileExplorerViewController, didChooseURLs urls: [URL])
}

/// The FileExplorerViewController class manages customizable for displaying, removing and choosing files and directories stored in local storage of the device in your app. A file explorer view controller manages user interactions and delivers the results of those interactions to a delegate object.
public final class FileExplorerViewController: UIViewController {

    /// The URL of directory which is initialy presented by file explorer view controller.
    @objc public var initialDirectoryURL: URL = URL.documentDirectory

    /// A Boolean value indicating whether the user is allowed to remove files.
    @objc public var canRemoveFiles: Bool = true

    /// A Boolean value indicating whether the user is allowed to remove directories.
    @objc public var canRemoveDirectories: Bool = true

    /// A Boolean value indicating whether the user is allowed to choose files.
    @objc public var canChooseFiles: Bool = true

    /// A Boolean value indicating whether the user is allowed to choose directories.
    @objc public var canChooseDirectories: Bool = false

    /// A Boolean value indicating whether multiple files and/or directories can be choosen at a time.
    @objc public var allowsMultipleSelection: Bool = true

    /// Filters that determine which files are displayed by file explorer view controller.
    ///
    /// Results of multiple filters are combined and displayed by file explorer view controller. All files are displayed if `fileFilters` array is empty.
    public var fileFilters = [Filter]()

    /// Filters that determine which files aren't displayed by file explorer view controller.
    ///
    /// Results of multiple filters are combined and all of them aren't displayed by file explorer view controller. All files passing filters from `fileFilters` property are displayed if there are no filters in `ignoredFileFilters` array.
    public var ignoredFileFilters = [Filter]()

    /// The file explorer's delegate object.
    public weak var delegate: FileExplorerViewControllerDelegate?

    /// File specification providers that are used by file explorer view controller to present thumbnails and view controllers of files of specified type.
    ///
    /// FileExplorer combines these providers with the default ones and uses resulting set of providers to present thumbnails and view controllers of files of specified type. Providers provided by the user have higher priority than the default ones.
    public var fileSpecificationProviders: [FileSpecificationProvider.Type]
    private var coordinator: ItemPresentationCoordinator!

    /// Initializes and returns a new file explorer view controller that presents content of directory at specified URL and uses passed file specification providers.
    ///
    /// - Parameters:
    ///   - directoryURL: The URL of directory which is initialy presented by file explorer view controller.
    ///   - providers: Specification providers that allows to extend set of files that are recognized by file explorer view controller. Each instance of file explorer view controller uses default set of providers to recognizer basic set of file formats.
    public init(directoryURL: URL = Foundation.URL.documentDirectory, providers: [FileSpecificationProvider.Type] = [FileSpecificationProvider.Type]()) {
        self.fileSpecificationProviders = providers
        self.initialDirectoryURL = directoryURL
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.fileSpecificationProviders = []
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        let navigationController = UINavigationController()
        addContentChildViewController(navigationController)
        coordinator = ItemPresentationCoordinator(navigationController: navigationController)
        coordinator.delegate = self
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fileSpecifications = FileSpecifications(providers: fileSpecificationProviders)

        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: canRemoveFiles,
                                                        canRemoveDirectories: canRemoveDirectories,
                                                        canChooseFiles: canChooseFiles,
                                                        canChooseDirectories: canChooseDirectories,
                                                        allowsMultipleSelection: allowsMultipleSelection)
        let filteringConfiguration = FilteringConfiguration(fileFilters: fileFilters, ignoredFileFilters: ignoredFileFilters)
        let configuration = Configuration(actionsConfiguration: actionsConfiguration, filteringConfiguration: filteringConfiguration)

        if let item = Item<Any>.at(initialDirectoryURL, isDirectory: true) {
            coordinator.start(item: item, fileSpecifications: fileSpecifications, configuration: configuration, animated: false)
        } else {
            precondition(false, "Passed URL is incorrect.")
        }
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        coordinator.stop(false)
    }
}

extension FileExplorerViewController: ItemPresentationCoordinatorDelegate {
    func itemPresentationCoordinatorDidFinish(_ coordinator: ItemPresentationCoordinator) {
        dismiss(animated: true, completion: nil)
        delegate?.fileExplorerViewControllerDidFinish(self)
    }
    
    func itemPresentationCoordinator(_ coordinator: ItemPresentationCoordinator, didChooseItems items: [Item<Any>]) {
        dismiss(animated: true, completion: nil)
        let urls = items.map { $0.url }
        delegate?.fileExplorerViewController(self, didChooseURLs: urls)
    }
}
