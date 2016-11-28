//
//  ItemTests.swift
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

final class ItemTests: XCTestCase {
    var cacheDirectoryURL: URL!

    var directoryURL: URL!
    var imageFileURL: URL!
    var audioFileURL: URL!
    var videoFileURL: URL!
    var pdfFileURL: URL!

    override func setUp() {
        super.setUp()

        cacheDirectoryURL = URL.cacheDirectory
        try? FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes: [String: Any]())

        directoryURL = cacheDirectoryURL.appendingPathComponent("directory")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: [String: Any]())

        let image = UIImage.makeImage(withColor: UIColor.red)
        let imageData = UIImagePNGRepresentation(image)!
        imageFileURL = cacheDirectoryURL.appendingPathComponent("image.png")
        try? imageData.write(to: imageFileURL)

        let bundle = Bundle(for: type(of: self))

        audioFileURL = cacheDirectoryURL.appendingPathComponent("audio.mp3")
        let audioFileBundleResourcesURL = bundle.url(forResource: "audio", withExtension: "mp3")!
        try? FileManager.default.copyItem(at: audioFileBundleResourcesURL, to: audioFileURL)

        let videoFileBundleResourcesURL = bundle.url(forResource: "video", withExtension: "mp4")!
        videoFileURL = cacheDirectoryURL.appendingPathComponent("video.mp4")
        try? FileManager.default.copyItem(at: videoFileBundleResourcesURL, to: videoFileURL)

        let pdfFileBundleResourcesURL = bundle.url(forResource: "pdf", withExtension: "pdf")!
        pdfFileURL = cacheDirectoryURL.appendingPathComponent("pdf.pdf")
        try? FileManager.default.copyItem(at: pdfFileBundleResourcesURL, to: pdfFileURL)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: cacheDirectoryURL)
    }

    func testWhetherDirectoryItemIsCorrectlyInitialised() {
        XCTAssertEqual(Item<Any>.at(directoryURL, isDirectory: true)!.type, ItemType.directory)
    }

    func testWhetherNamePropertyReturnsProperValue() {
        let item = Item<Any>.at(pdfFileURL)!
        XCTAssertEqual(item.name, "pdf.pdf")
    }
}

