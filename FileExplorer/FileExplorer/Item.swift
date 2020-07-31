//
//  Item.swift
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


/// Item types that are used as input to filters.
///
/// - directory: Item type matching all items that are directories.
/// - file: Item type matching all items that are files.
public enum ItemType {
    case directory
    case file
}

public typealias FileAttributes = [FileAttributeKey: Any]
typealias DirectoryItem = Item<[Item<Any>]>
typealias LoadedDirectoryItem = LoadedItem<[Item<Any>]>

struct Item<T> {
    let url: URL
    var name: String {
        return url.lastPathComponent
    }
    var `extension`: String {
        return (url.lastPathComponent as NSString).pathExtension
    }
    let modificationDate: Date
    let type: ItemType
    let parse: (_ attributes: FileAttributes, _ data: Data?, _ items: [URL]?) -> T?

    private init?(url: URL, attributes: FileAttributes?, type: ItemType, parse: @escaping (FileAttributes, Data?, [URL]?) -> T?) {
        self.url = url
        self.type = type
        self.parse = parse

        if let attributes = attributes {
            self.modificationDate = attributes[FileAttributeKey.modificationDate] as! Date
        } else {
            var modificationDate: AnyObject?
            do {
                try (url as NSURL).getResourceValue(&modificationDate, forKey: URLResourceKey.contentModificationDateKey)
                self.modificationDate = modificationDate as! Date
            } catch {
                return nil
            }
        }
    }

    init?(url: URL, attributes: FileAttributes?, parse: @escaping (FileAttributes, [URL]) -> T?) {
        self.init(url: url, attributes: attributes, type: ItemType.directory, parse: { attributes, data, urls in
            guard let urls = urls else {
                fatalError("Urls cannot be equal to nil")
            }
            return parse(attributes, urls)
        })
    }

    init?(url: URL, attributes: FileAttributes?, parse: @escaping (FileAttributes, Data) -> T?) {
        self.init(url: url, attributes: attributes, type: ItemType.file, parse: { attributes, data, urls in
            guard let data = data else {
                fatalError("Data cannot be equal to nil")
            }
            return parse(attributes, data)
        })
    }
}

extension Item: Equatable {
    internal static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.url == rhs.url
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url.hashValue)
    }
}

typealias Extension = String

/// Patter matching
///
func ~=<T: Equatable>(pattern: [T], value: T) -> Bool {
    return pattern.contains { $0 == value }
}

extension Item {
    static func directory(at url: URL, attributes: FileAttributes? = nil) -> Item<Any>? {
        return Item<Any>(url: url, attributes: attributes) { (attributes: FileAttributes, urls: [URL]) in
            return urls.map({ url -> Any in
                var isDirectoryValue: AnyObject?
                try? (url as NSURL).getResourceValue(&isDirectoryValue, forKey: .isDirectoryKey)
                let isDirectory = (isDirectoryValue as? Bool) ?? false
                return Item.at(url, isDirectory: isDirectory)!
            }) as Any
        }
    }

    static func file(at url: URL, attributes: FileAttributes? = nil, isDirectory: Bool = false) -> Item<Any>? {
        return Item<Any>(url: url, attributes: attributes) { (attributes: FileAttributes, data: Data) in
            return data
        }
    }

    static func at(_ url: URL, attributes: FileAttributes? = nil, isDirectory: Bool = false) -> Item<Any>? {
        if isDirectory {
            return directory(at: url, attributes: attributes)
        } else {
            return file(at: url, attributes: attributes)
        }
    }
}

struct LoadedItem<T> {
    let url: URL
    let type: ItemType
    let attributes: [FileAttributeKey: Any]
    let resource: T

    func cast<U>() -> LoadedItem<U> {
        return LoadedItem<U>(url: url, type: type, attributes: attributes, resource: resource as! U)
    }

    var name: String {
        return url.lastPathComponent
    }
}

extension LoadedItem {
    init(item: Item<T>, attributes: [FileAttributeKey: Any], resource: T) {
        self.url = item.url
        self.type = item.type
        self.attributes = attributes
        self.resource = resource
    }
}
