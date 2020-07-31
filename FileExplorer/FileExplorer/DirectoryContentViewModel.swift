//
//  DirectoryContentViewModel.swift
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

protocol DirectoryContentViewModelDelegate: class {
    func directoryViewModelDidChangeItemsList(_ viewModel: DirectoryContentViewModel)
    func directoryViewModelDidChange(_ viewModel: DirectoryContentViewModel)
    func directoryViewModel(_ viewModel: DirectoryContentViewModel, didSelectItem item: Item<Any>)
}

enum SortMode {
    case name
    case date
}

typealias Items = [Item<Any>]

final class DirectoryContentViewModel {
    enum ViewModelError: Error {
        case failedItemsRemoval
    }

    weak var delegate: DirectoryContentViewModelDelegate?

    lazy var sortModeChangeAction: (SortMode) -> Void = { [weak self] in
        return { sortMode in self?.sortMode = sortMode }
        }()

    var sortMode: SortMode {
        didSet {
            itemsToDisplay = DirectoryContentViewModel.itemsWithAppliedFilterAndSortCriterias(searchQuery: searchQuery ?? "", sortMode: sortMode, items: allItems)
            delegate?.directoryViewModelDidChangeItemsList(self)
        }
    }
    
    var isUserInteractionEnabled: Bool {
        return !fileService.isDeletionInProgress
    }
    
    var title: String {
        get {
            return url.lastPathComponent
        }
    }

    var isEditing: Bool = false {
        didSet(oldValue) {
            guard oldValue != isEditing else { return }
            selectedItems = [Item<Any>]()
            delegate?.directoryViewModelDidChange(self)
        }
    }

    var isEditActionHidden: Bool {
        let actionsConfiguration = configuration.actionsConfiguration
        return !actionsConfiguration.canChooseDirectories && !actionsConfiguration.canChooseFiles && !actionsConfiguration.canRemoveDirectories && !actionsConfiguration.canRemoveFiles
    }
    
    var isEditActionEnabled: Bool {
        return !isEditActionHidden && !fileService.isDeletionInProgress
    }
    
    var editActionTitle: String {
        return isEditing ? NSLocalizedString("Cancel", comment: "") : NSLocalizedString("Select", comment: "")
    }
    
    var searchQuery: String? = "" {
        willSet(newSearchQuery) {
            itemsToDisplay = DirectoryContentViewModel.itemsWithAppliedFilterAndSortCriterias(searchQuery: newSearchQuery ?? "", sortMode: sortMode, items: allItems)
        }
        didSet {
            delegate?.directoryViewModelDidChangeItemsList(self)
        }
    }

    var indexPathsOfSelectedCells: [IndexPath] {
        var indexPaths = [IndexPath]()
        for item in selectedItems {
            indexPaths.append(index(for: item))
        }
        return indexPaths
    }

    var isSelectionEnabled: Bool {
        return isEditing
    }

    var isDeleteActionHidden: Bool {
        return !configuration.actionsConfiguration.canRemoveDirectories && !configuration.actionsConfiguration.canRemoveFiles
    }
    
    var isDeleteActionEnabled: Bool {
        guard selectedItems.count > 0 && !isDeleteActionHidden else { return false }

        return !fileService.isDeletionInProgress && !fileService.isDeletionInProgress && selectedItems.reduce(true) { enabled, item in
            if item.type == .file && !configuration.actionsConfiguration.canRemoveFiles {
                return false
            } else if item.type == .directory && !configuration.actionsConfiguration.canRemoveDirectories {
                return false
            } else {
                return true && enabled
            }
        }
    }

    var deleteActionTitle: String {
        return NSLocalizedString("Delete", comment: "")
    }

    var isSelectActionHidden: Bool {
        return !configuration.actionsConfiguration.canChooseDirectories && !configuration.actionsConfiguration.canChooseFiles
    }

    var isSelectActionEnabled: Bool {
        guard selectedItems.count > 0 && !isSelectActionHidden else { return false }

        let selectedItemsAreAllowedToBeSelected = selectedItems.reduce(true) { enabled, item in
            if item.type == ItemType.directory && !configuration.actionsConfiguration.canChooseDirectories {
                return false
            } else if item.type == ItemType.file && !configuration.actionsConfiguration.canChooseFiles {
                return false
            } else {
                return true && enabled
            }
        }

        let numberOfSelectedItemsIsAllowed = configuration.actionsConfiguration.allowsMultipleSelection ? selectedItems.count > 0 : selectedItems.count == 1
        return !fileService.isDeletionInProgress && selectedItemsAreAllowedToBeSelected && numberOfSelectedItemsIsAllowed
    }

    var selectActionTitle: String {
        return NSLocalizedString("Choose", comment: "")
    }

    private var selectedItems = Items()
    private var allItems: Items
    private var itemsToDisplay: Items
    private let url: URL
    private let configuration: Configuration
    private let fileSpecifications: FileSpecifications
    private let fileService: FileService

    init(item: LoadedDirectoryItem, fileSpecifications: FileSpecifications, configuration: Configuration, fileService: FileService = LocalStorageFileService()) {
        self.url = item.url
        self.fileSpecifications = fileSpecifications
        self.configuration = configuration
        self.fileService = fileService
        self.sortMode = .name

        let filteringConfiguration = configuration.filteringConfiguration
        self.allItems = item.resource.filter {  filteringConfiguration.fileFilters.count == 0 || filteringConfiguration.fileFilters.matchesItem($0) }
        self.allItems = self.allItems.filter { filteringConfiguration.ignoredFileFilters.count == 0 || !filteringConfiguration.ignoredFileFilters.matchesItem($0) }
        self.itemsToDisplay = DirectoryContentViewModel.itemsWithAppliedFilterAndSortCriterias(searchQuery: "", sortMode: sortMode, items: self.allItems)

        NotificationCenter.default.addObserver(self, selector: #selector(handleItemsDeletedNotification(_:)), name: Notification.Name.ItemsDeleted, object: nil)
    }

    func select(at indexPath: IndexPath) {
        let item = self.item(for: indexPath)
        if isEditing {
            selectedItems.append(item)
        } else {
            delegate?.directoryViewModel(self, didSelectItem: item)
        }
        delegate?.directoryViewModelDidChange(self)
    }
    
    func deselect(at indexPath: IndexPath) {
        let item = self.item(for: indexPath)
        if isEditing {
            if let index = selectedItems.firstIndex(where: { $0 == item }) {
                selectedItems.remove(at: index)
            }
        } else {
            delegate?.directoryViewModel(self, didSelectItem: item)
        }
        delegate?.directoryViewModelDidChange(self)
    }

    func deleteItems(at indexPaths: [IndexPath], completionBlock: @escaping (Result<Void>) -> Void) {
        let items = indexPaths.compactMap { item(for: $0) }
        fileService.delete(items: items) { result, removedItems, itemsNotRemovedDueToFailure in
            completionBlock(result)
            self.delegate?.directoryViewModelDidChange(self)
        }
        self.delegate?.directoryViewModelDidChange(self)
    }
    
    func chooseItems(completionBlock: ([Item<Any>]) -> Void) {
        completionBlock(selectedItems)
    }
    
    // MARK: Helpers

    private static func itemsWithAppliedFilterAndSortCriterias(searchQuery: String, sortMode: SortMode, items: [Item<Any>]) -> [Item<Any>] {
        let searchQuery = searchQuery.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let filteredItems = items.filter { $0.url.lastPathComponent.localizedCaseInsensitiveContains(searchQuery) || searchQuery == "" }
        return filteredItems.sorted { (lhs, rhs) in
            switch sortMode {
            case .name: return lhs.url.compare(rhs.url) == ComparisonResult.orderedAscending
            case .date: return lhs.modificationDate > rhs.modificationDate
            }
        }
    }

    private func remove(item: Item<Any>) {
        itemsToDisplay.remove(item)
        allItems.remove(item)
        selectedItems.remove(item)
    }
    
    private func index(for item: Item<Any>) -> IndexPath {
        for (i, iterItem) in allItems.enumerated() {
            if iterItem == item {
                return IndexPath(item: i, section: 0)
            }
        }
        fatalError()
    }

    // MARK: UICollectionView

    var numberOfSections: Int {
        return 1
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return itemsToDisplay.count
    }
    
    func viewModel(for indexPath: IndexPath) -> ItemViewModel {
        let item = self.item(for: indexPath)
        return ItemViewModel(item: item, specificationProvider: fileSpecifications.itemSpecification(for: item))
    }

    func item(for indexPath: IndexPath) -> Item<Any> {
        return itemsToDisplay[indexPath.item]
    }

    // MARK: Actions 

    @objc
    private func handleItemsDeletedNotification(_ notification: Notification) {
        let items = notification.object as! Items
        for item in items {
            remove(item: item)
        }

        delegate?.directoryViewModelDidChangeItemsList(self)
    }
}

struct ItemViewModel {
    private let item: Item<Any>
    private let specificationProvider: FileSpecificationProvider.Type
    private static let dateFormatter = DateFormatter()

    let title: String
    let subtitle: String
    let accessoryType: ItemCell.AccessoryType

    init(item: Item<Any>, specificationProvider: FileSpecificationProvider.Type) {
        self.item = item
        self.specificationProvider = specificationProvider
        self.title = item.name
        self.subtitle = type(of: self).string(from: item.modificationDate)
        self.accessoryType = item.type == .directory ? .disclosureIndicator : .detailButton
    }

    func thumbnailImage(with size: CGSize) -> UIImage {
        switch item.type {
        case .file:
            return specificationProvider.thumbnail(forItemAt: item.url, with: size) ?? ImageAssets.genericDocumentIcon
        default:
            return ImageAssets.genericDirectoryIcon
        }
    }

    private static func string(from date: Date) -> String {
        if abs(Date().timeIntervalSince(date)) > 1.hour {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else {
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .none
        }
        return dateFormatter.string(from : date)
    }
}
