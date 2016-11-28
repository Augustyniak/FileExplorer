//
//  LocalStorageFileServiceTests.swift
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

import XCTest
@testable import FileExplorer


final class LocalStorageFileServiceTests: XCTestCase {
    var fileService: LocalStorageFileService!

    var directory: Item<Any>!
    var imageItemThatDoesNotExistOnDisc: Item<Any>!
    var imageItem: Item<Any>!
    var audioItem: Item<Any>!
    var videoItem: Item<Any>!
    var pdfItem: Item<Any>!
    var subdirectory: Item<Any>!


    override func setUp() {
        super.setUp()
        fileService = LocalStorageFileService()

        let directoryURL = FileManager.createCacheDirectory()
        directory = Item<Any>.makeTestDirectory(at: directoryURL)
        imageItem = Item<Any>.makeTestImage(at: directoryURL.appendingPathComponent("image.png"))
        imageItemThatDoesNotExistOnDisc = Item<Any>.nonDiscAt(directoryURL.appendingPathComponent("image2.png"))
        audioItem = Item<Any>.makeTestAudio(at: directoryURL.appendingPathComponent("audio.mp3"))
        videoItem = Item<Any>.makeTestVideo(at: directoryURL.appendingPathComponent("video.mp4"))
        pdfItem = Item<Any>.makeTestPDF(at: directoryURL.appendingPathComponent("pdf.pdf"))
        subdirectory = Item<Any>.makeTestDirectory(at: directoryURL.appendingPathComponent("directory"))
    }

    override func tearDown() {
        super.tearDown()

        try? FileManager.default.removeItem(at: directory.url)
    }

    //MARK: Loading

    func testWhetherDataOfImageFilesIsParsedCorrectly() {
        let expectation = self.expectation(description: "waiting for completion handler")
        fileService.load(item: imageItem) { loadedItem in
            _ = loadedItem.flatMap({ loadedItem -> Result<LoadedItem<Any>> in
                XCTAssertTrue(loadedItem.resource is Data)
                expectation.fulfill()
                return Result.success(loadedItem)
            })
        }

        waitForExpectations(timeout: 1.0)
    }

    func testWhetherDataOfDirectoryIsParsedCorrectly() {
        let expectation = self.expectation(description: "waiting for completion handler")
        fileService.load(item: directory) { loadedItem in
            _ = loadedItem.flatMap({ loadedItem -> Result<LoadedItem<Any>> in
                let items = loadedItem.resource as! [Item<Any>]
                XCTAssertEqual(items.count, 5)
                expectation.fulfill()
                return Result.success(loadedItem)
            })
        }

        waitForExpectations(timeout: 1.0)
    }

    //MARK: Deletions

    func testWhetherProperNotificationIsSendAfterItemsDeletion() {
        let notificationReceivedExpectation = self.expectation(description: "waiting for notification")
        NotificationCenter.default.addObserver(forName: Notification.Name.ItemsDeleted, object: nil, queue: nil) { notification in
            let removedItems = notification.object as! [Item<Any>]
            XCTAssertEqual(removedItems.count, 1)
            XCTAssertEqual(removedItems.first!, self.imageItem)
            notificationReceivedExpectation.fulfill()
        }

        let completionBlockExpectation = self.expectation(description: "waiting for completion handler")
        fileService.delete(items: [imageItem, imageItemThatDoesNotExistOnDisc]) { result, removedItems, itemsNotRemovedDueToFailure in
            XCTAssertEqual(removedItems.count, 1)
            XCTAssertEqual(itemsNotRemovedDueToFailure.count, 1)

            XCTAssertEqual(removedItems.first!, self.imageItem)
            XCTAssertEqual(itemsNotRemovedDueToFailure.first!, self.imageItemThatDoesNotExistOnDisc)

            completionBlockExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}
