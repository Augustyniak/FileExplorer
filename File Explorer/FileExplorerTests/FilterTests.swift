//
//  FilterTests.swift
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

@testable import FileExplorer
import XCTest

final class FilterTests: XCTestCase {
    func testNameFilter() {
        let filter = Filter.lastPathComponent("test")

        XCTAssertFalse(filter.matchesItem(withLastPathComponent: "test.txt", type: .file, modificationDate: Date()))
        XCTAssertTrue(filter.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date()))
    }

    func testExtensionFilter() {
        let filter = Filter.`extension`("txt")
        XCTAssertFalse(filter.matchesItem(withLastPathComponent: "txt", type: .file, modificationDate: Date()))
        XCTAssertTrue(filter.matchesItem(withLastPathComponent: "test.txt", type: .file, modificationDate: Date()))
    }

    func testModificationDateFilter() {
        let referenceDate = Date.init(timeIntervalSince1970: 10)

        let filterPastDate = Filter.modificationDatePast(referenceDate)
        XCTAssertFalse(filterPastDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: -1, since: referenceDate)))
        XCTAssertFalse(filterPastDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 0, since: referenceDate)))
        XCTAssertTrue(filterPastDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 1, since: referenceDate)))

        let filterPastOrEqualToDate = Filter.modificationDatePastOrEqualTo(referenceDate)
        XCTAssertFalse(filterPastOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: -1, since: referenceDate)))
        XCTAssertTrue(filterPastOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 0, since: referenceDate)))
        XCTAssertTrue(filterPastOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 1, since: referenceDate)))

        let filterPriorToDate = Filter.modificationDatePriorTo(referenceDate)
        XCTAssertTrue(filterPriorToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: -1, since: referenceDate)))
        XCTAssertFalse(filterPriorToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 0, since: referenceDate)))
        XCTAssertFalse(filterPriorToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 1, since: referenceDate)))

        let filterPriorOrEqualToDate = Filter.modificationDatePriorOrEqualTo(referenceDate)
        XCTAssertTrue(filterPriorOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: -1, since: referenceDate)))
        XCTAssertTrue(filterPriorOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 0, since: referenceDate)))
        XCTAssertFalse(filterPriorOrEqualToDate.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date(timeInterval: 1, since: referenceDate)))
    }

    func testTypeFilter() {
        let directoryFilter = Filter.type(.directory)

        XCTAssertTrue(directoryFilter.matchesItem(withLastPathComponent: "test", type: .directory, modificationDate: Date()))
        XCTAssertFalse(directoryFilter.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date()))

        let fileFilter = Filter.type(.file)
        XCTAssertTrue(fileFilter.matchesItem(withLastPathComponent: "test", type: .file, modificationDate: Date()))
        XCTAssertFalse(fileFilter.matchesItem(withLastPathComponent: "test", type: .directory, modificationDate: Date()))
    }
}
