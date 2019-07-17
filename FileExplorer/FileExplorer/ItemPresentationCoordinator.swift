//
//  ItemPresentationCoordinator.swift
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

protocol ItemPresentationCoordinatorDelegate: class {
    func itemPresentationCoordinatorDidFinish(_ coordinator: ItemPresentationCoordinator)
    func itemPresentationCoordinator(_ coordinator: ItemPresentationCoordinator, didChooseItems items: [Item<Any>])
    func itemPresentationCoordinator(_ coordinator: ItemPresentationCoordinator, shouldRemoveItems items: [Item<Any>], removeItemsHandler: @escaping (([Item<Any>]) -> Void))
}

final class ItemPresentationCoordinator {
    weak var delegate: ItemPresentationCoordinatorDelegate?

    fileprivate weak var navigationController: UINavigationController?
    fileprivate var childCoordinators = [Any]()
    fileprivate var fileSpecifications = FileSpecifications(providers: [FileSpecificationProvider.Type]())
    fileprivate var configuration = Configuration()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start(item: Item<Any>, fileSpecifications: FileSpecifications, configuration: Configuration, animated: Bool) {
        guard let navigationController = self.navigationController else { return }
        self.configuration = configuration
        self.fileSpecifications = fileSpecifications

        switch item.type {
        case .file:
            let coordinator = FileItemPresentationCoordinator(configuration: configuration, navigationController: navigationController, item: item, fileSpecifications: fileSpecifications)
            coordinator.start(animated)
            childCoordinators.append(coordinator)
        case .directory:
            let coordinator = DirectoryItemPresentationCoordinator(navigationController: navigationController, fileSpecifications: fileSpecifications, configuration: configuration)
            coordinator.delegate = self
            coordinator.start(directoryURL: item.url, animated: animated)
            childCoordinators.append(coordinator)
        }
    }
    
    func stop(_ animated: Bool) {
        childCoordinators.removeAll()
        self.navigationController?.setViewControllers([UIViewController](), animated: animated)
    }
}

extension ItemPresentationCoordinator: DirectoryItemPresentationCoordinatorDelegate {

    func directoryItemPresentationCoordinator(_ coordinator: DirectoryItemPresentationCoordinator, didSelectItem item: Item<Any>) {
        start(item: item, fileSpecifications: fileSpecifications, configuration: configuration, animated: true)
    }

    func directoryItemPresentationCoordinator(_ coordinator: DirectoryItemPresentationCoordinator, didSelectItemDetails item: Item<Any>) {
        guard let navigationController = navigationController else { fatalError() }
        let coordinator = FileItemPresentationCoordinator(configuration: configuration, navigationController: navigationController, item: item, fileSpecifications: fileSpecifications)
        childCoordinators.append(coordinator)
        coordinator.startDetailsPreview(true)
    }
    
    func directoryItemPresentationCoordinator(_ coordinator: DirectoryItemPresentationCoordinator, didChooseItems items: [Item<Any>]) {
        delegate?.itemPresentationCoordinator(self, didChooseItems: items)
    }
    
    func directoryItemPresentationCoordinatorDidFinish(_ coordinator: DirectoryItemPresentationCoordinator) {
        delegate?.itemPresentationCoordinatorDidFinish(self)
    }
    internal func directoryItemPresentationCoordinator(_ coordinator: DirectoryItemPresentationCoordinator, shouldRemoveItems items: [Item<Any>], removeItemsHandler: @escaping (([Item<Any>]) -> Void)) {
        delegate?.itemPresentationCoordinator(self, shouldRemoveItems: items, removeItemsHandler: {(itemsToRemove) -> Void in
            removeItemsHandler(itemsToRemove)
        })
    }
}
