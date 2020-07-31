//
//  FileService.swift
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

protocol FileService: class {
    func load(item: Item<Any>, completionBlock: @escaping (Result<LoadedItem<Any>>) -> ())
    func delete(items: [Item<Any>], completionBlock: @escaping (_ result: Result<Void>, _ removedItems: [Item<Any>], _ itemsNotRemovedDueToFailure: [Item<Any>]) -> Void)
    
    var isDeletionInProgress: Bool { get }
}

enum FileServiceError: Error {
    case removalFailure(removedItems: [Item<Any>], itemsNotRemovedDueToFailure: [Item<Any>])
    case loadingFailure
}

extension Notification.Name {
    static let ItemsDeleted = Notification.Name("ItemsDeleted")
}


final class LocalStorageFileService: FileService {
    private let fileManager: FileManager
    var isDeletionInProgress: Bool = false

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    func load(item: Item<Any>, completionBlock: @escaping (Result<LoadedItem<Any>>) -> ()) {
        DispatchQueue.global(qos: .default).async {
            let result = Result<LoadedItem<Any>>() { [weak self] in
                guard let strongSelf = self else { throw FileServiceError.loadingFailure }
                
                let attributes = try strongSelf.fileManager.attributesOfItem(atPath: item.url.path)
                let result: Any
                
                if item.type == ItemType.directory {
                    let urls = try FileManager.default.contentsOfDirectory(at: item.url, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                    result = item.parse(attributes, nil, urls)!
                } else {
                    let data = try Data.init(contentsOf: item.url)
                    result = item.parse(attributes, data, nil)!
                }
                return LoadedItem(item: item, attributes: attributes, resource: result)
            }
            DispatchQueue.main.async {
                completionBlock(result)
            }
        }
    }

    func delete(items: [Item<Any>], completionBlock: @escaping (_ result: Result<Void>, _ deletedItems: [Item<Any>], _ itemsNotDeletedDueToFailure: [Item<Any>]) -> Void) {
        guard !isDeletionInProgress else { return }
        
        isDeletionInProgress = true
        
        var deletedItems = [Item<Any>]()
        var itemsNotRemovedDueToFailure = [Item<Any>]()

        DispatchQueue.global(qos: .default).async() { [weak self] in
            guard let strongSelf = self else { return }
            for item in items {
                do {
                    try strongSelf.fileManager.removeItem(at: item.url)
                    deletedItems.append(item)
                } catch {
                    itemsNotRemovedDueToFailure.append(item)
                }
            }

            DispatchQueue.main.async {
                if deletedItems.count > 0 {
                    NotificationCenter.default.post(name: Notification.Name.ItemsDeleted, object: deletedItems)
                }
                strongSelf.isDeletionInProgress = false
                if itemsNotRemovedDueToFailure.count > 0 {
                    completionBlock(.error(FileServiceError.removalFailure(removedItems: deletedItems, itemsNotRemovedDueToFailure: itemsNotRemovedDueToFailure)),
                                    deletedItems,
                                    itemsNotRemovedDueToFailure)
                } else {
                    completionBlock(.success(()), deletedItems, itemsNotRemovedDueToFailure)
                }

            }
        }
    }
}
