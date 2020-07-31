//
//  FileViewModel.swift
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

final class FileViewModel {
    typealias FileAttributes = [FileAttributeKey: Any]

    var title: String
    
    private let item: LoadedItem<Any>
    private let specification: FileSpecificationProvider.Type
    private let items: [FileAttributeViewModel]
    fileprivate static var sizeFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        return byteCountFormatter
    }()
    
    init(item: LoadedItem<Any>, specification: FileSpecificationProvider.Type) {
        self.item = item
        self.title = item.name
        self.specification = specification
        
        self.items = [
            FileViewModel.makeFileSizeItem(fromAttributes: self.item.attributes),
            FileViewModel.makeCreationDateItem(fromAttributes: self.item.attributes),
            FileViewModel.makeModificationDateItem(fromAttributes: self.item.attributes)
            ].compactMap { $0 }
    }

    func thumbnailImage(with size: CGSize) -> UIImage {
        switch item.type {
        case .file:
            return specification.thumbnail(forItemAt: item.url, with: size) ?? ImageAssets.genericDocumentIcon
        default:
            return ImageAssets.genericDirectoryIcon
        }
    }

    var numberOfAttributes: Int {
        get {
            return self.items.count
        }
    }
    
    func attribute(for item: Int) -> FileAttributeViewModel {
        return self.items[item]
    }
}

extension FileViewModel {
    fileprivate static func makeFileSizeItem(fromAttributes attributes: FileAttributes) -> FileAttributeViewModel? {
        let byteCount = Int64((attributes as NSDictionary).fileSize())
        guard let keyLabel = FileViewModel.string(for: .size) else {
            return nil
        }
        
        return FileAttributeViewModel(attributeName: keyLabel,
                                      attributeValue: FileViewModel.sizeFormatter.string(fromByteCount: byteCount))
    }
    
    fileprivate static func makeCreationDateItem(fromAttributes attributes: FileAttributes) -> FileAttributeViewModel? {
        guard let creationDate = (attributes as NSDictionary).fileCreationDate(),
            let keyLabel = FileViewModel.string(for: .creationDate) else {
                return nil
        }
        
        return FileAttributeViewModel(attributeName: keyLabel,
                                      attributeValue: DateFormatter.localizedString(from: creationDate, dateStyle: .medium, timeStyle: .medium))
    }
    
    fileprivate static func makeModificationDateItem(fromAttributes attributes: FileAttributes) -> FileAttributeViewModel? {
        guard let modificationDate = (attributes as NSDictionary).fileModificationDate(),
            let keyLabel = FileViewModel.string(for: .modificationDate) else {
                return nil
        }
        
        return FileAttributeViewModel(attributeName: keyLabel,
                                      attributeValue: DateFormatter.localizedString(from: modificationDate, dateStyle: .medium, timeStyle: .medium))
    }
    
    fileprivate static func makeFileTypeItem(fromAttributes attributes: FileAttributes) -> FileAttributeViewModel? {
        guard let fileType = (attributes as NSDictionary).fileType(),
            let keyLabel = FileViewModel.string(for: .type) else {
                return nil
        }
        
        return FileAttributeViewModel(attributeName: keyLabel,
                                      attributeValue: fileType)
    }
    
    fileprivate static func string(for fileAttributeKey: FileAttributeKey) -> String? {
        switch fileAttributeKey {
        case FileAttributeKey.size:
            return NSLocalizedString("Size", comment: "")
        case FileAttributeKey.creationDate:
            return NSLocalizedString("Created", comment: "")
        case FileAttributeKey.modificationDate:
            return NSLocalizedString("Modified", comment: "")
        case FileAttributeKey.type:
            return NSLocalizedString("Kind", comment: "")
        default:
            return nil
        }
    }
}

struct FileAttributeViewModel {
    let attributeName: String
    let attributeValue: String
    
    init(attributeName: String, attributeValue: String) {
        self.attributeName = attributeName
        self.attributeValue = attributeValue
    }
}
