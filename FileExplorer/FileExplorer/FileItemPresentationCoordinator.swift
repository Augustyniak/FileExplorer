//
//  FileItemPresentationCoordinator.swift
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
import AVKit
import AVFoundation

final class FileItemPresentationCoordinator {
    fileprivate weak var navigationController: UINavigationController?
    fileprivate let fileService: FileService
    fileprivate let fileSpecifications: FileSpecifications
    fileprivate let configuration: Configuration
    fileprivate let item: Item<Any>

    init(configuration: Configuration, navigationController: UINavigationController, item: Item<Any>, fileSpecifications: FileSpecifications, fileService: FileService = LocalStorageFileService()) {
        self.configuration = configuration
        self.navigationController = navigationController
        self.item = item
        self.fileSpecifications = fileSpecifications
        self.fileService = fileService
    }
    
    func start(_ animated: Bool) {
        switch item.type {
        case .file:
            let viewController = makePresentingViewController(item: item) { [weak self] loadedItem in
                guard let strongSelf = self else { fatalError() }
                let castedLoadedItem = loadedItem.cast() as LoadedItem<Data>
                let viewController = strongSelf.fileSpecifications.itemSpecification(for: strongSelf.item).viewControllerForItem(at: loadedItem.url, data: castedLoadedItem.resource, attributes: loadedItem.attributes)
                viewController.navigationItem.title = strongSelf.item.name
                return viewController
            }
            navigationController?.pushViewController(viewController, animated: animated)
        case .directory:
            fatalError()
        }
    }

    func startDetailsPreview(_ animated: Bool) {
        let fileSpecification = fileSpecifications.itemSpecification(for: item)
        let viewController = makePresentingViewController(item: item) { loadedItem in
            let viewModel = FileViewModel(item: loadedItem, specification: fileSpecification)
            return FileViewController(viewModel: viewModel)
        }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    private func makePresentingViewController(item: Item<Any>, builder: @escaping (LoadedItem<Any>) -> UIViewController) -> UIViewController {
        let viewController = LoadingViewController<Any>.make(item: item) { [weak self] loadedItem in
            let contentViewController = builder(loadedItem)
            let actionsViewController = ActionsViewController(configuration: self!.configuration, contentViewController: contentViewController)
            actionsViewController.delegate = self
            return actionsViewController
        }
        return viewController
    }
}

extension FileItemPresentationCoordinator: ActionsViewControllerDelegate {
    func actionsViewControllerDidRequestShare(_ controller: ActionsViewController) {
        let activityItem = UIActivityItemProvider(placeholderItem: item.url)
        let activityViewController = UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = navigationController?.view
        navigationController?.present(activityViewController, animated: true, completion: nil)
    }

    func actionsViewControllerDidRequestRemoval(_ controller: ActionsViewController) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.fileService.delete(items: [strongSelf.item]) { result, removedItems, itemsNotRemovedDueToFailure in
                guard let navigationController = strongSelf.navigationController else { return }
                if case .error(let error) = result {
                    UIAlertController.presentAlert(for: error, in: navigationController)
                }
            }
        }
        _ = navigationController?.popViewController(animated: true)
        CATransaction.commit()
    }
}
