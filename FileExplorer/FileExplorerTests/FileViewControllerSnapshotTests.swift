//
//  FileViewControllerTests.swift
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

import FBSnapshotTestCase
@testable import FileExplorer

final class FileViewControllerSnapshotTests: FBSnapshotTestCase {
    var viewController: FileViewController!
    var viewModel: FileViewModel!
    var directoryURL: URL!

    override func setUp() {
        super.setUp()
        
        directoryURL = FileManager.createCacheDirectory()
    }

    func testWhetherVCLooksCorrectlyForDifferentFileItems() {
        let items: [Item<Any>: FileSpecificationProvider.Type] = [
            Item<Any>.makeTestImage(at: directoryURL.appendingPathComponent("image.png")): ImageSpecificationProvider.self,
            Item<Any>.makeTestAudio(at: directoryURL.appendingPathComponent("audio.mp3")): AudioSpecificationProvider.self,
            Item<Any>.makeTestVideo(at: directoryURL.appendingPathComponent("video.mp4")): VideoSpecificationProvider.self,
            Item<Any>.makeTestPDF(at: directoryURL.appendingPathComponent("pdf.pdf")): PDFSpecificationProvider.self,
            Item<Any>.makeUnknownTestFile(at: directoryURL.appendingPathComponent("unknown.txt")): DefaultFileSpecificationProvider.self
        ]

        for (item, specification) in items {
            let loadedItem = LoadedItem<Any>.makeTestLoadedItem(item: item)
            viewModel = FileViewModel(item: loadedItem, specification: specification)
            viewController = FileViewController(viewModel: viewModel)
            viewController.view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 375, height: 667))
            FBSnapshotVerifyView(viewController.view, identifier: item.name)
        }
    }
}

extension CGRect {
    static let iPhone6Bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: 375, height: 667))
}
