//
//  Configuration.swift
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

struct Configuration {
    var actionsConfiguration = ActionsConfiguration()
    var filteringConfiguration = FilteringConfiguration()
}

struct ActionsConfiguration {
    var canShareFiles: Bool = false
    var canRemoveFiles: Bool = false
    var canRemoveDirectories: Bool = false
    var canChooseFiles: Bool = false
    var canChooseDirectories: Bool = false
    var allowsMultipleSelection: Bool = false
    var directSelection: Bool = false
}

struct FilteringConfiguration {
    var fileFilters: [Filter]
    var ignoredFileFilters: [Filter]
}

extension FilteringConfiguration {
    init() {
        self.init(fileFilters: [Filter](), ignoredFileFilters: [Filter]())
    }
}

public enum Filter {
    case `extension`(String)
    case type(ItemType)
    case lastPathComponent(String)
    case modificationDatePriorTo(Date)
    case modificationDatePriorOrEqualTo(Date)
    case modificationDatePast(Date)
    case modificationDatePastOrEqualTo(Date)

    func matchesItem(_ item: Item<Any>) -> Bool {
        return matchesItem(withLastPathComponent: item.url.lastPathComponent, type: item.type, modificationDate: item.modificationDate)
    }

    func matchesItem(withLastPathComponent lastPathComponent: String, type: ItemType, modificationDate: Date) -> Bool {
        switch self {
        case .`extension`(let `extension`):
            return `extension`.lowercased() == (lastPathComponent as NSString).pathExtension.lowercased()
        case .type(let t):
            return t == type
        case .lastPathComponent(let lastPathComp):
            return lastPathComponent == lastPathComp
        case .modificationDatePriorTo(let date):
            return modificationDate.timeIntervalSince(date) < 0
        case .modificationDatePriorOrEqualTo(let date):
            return modificationDate.timeIntervalSince(date) <= 0
        case .modificationDatePast(let date):
            return modificationDate.timeIntervalSince(date) > 0
        case .modificationDatePastOrEqualTo(let date):
            return modificationDate.timeIntervalSince(date) >= 0
        }
    }
}
