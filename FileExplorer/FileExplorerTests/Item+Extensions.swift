//
//  Item+Extensions.swift
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

extension Item {
    static func nonDiscDirectory(at url: URL, modificationDate: Date = Date()) -> Item<Any>? {
        return Item<Any>(url: url, attributes: [.modificationDate: modificationDate] as FileAttributes) { (attributes: FileAttributes, urls: [URL]) in
            return urls.map({ url -> Any in
                var isDirectoryValue: AnyObject?
                try? (url as NSURL).getResourceValue(&isDirectoryValue, forKey: .isDirectoryKey)
                let isDirectory = (isDirectoryValue as? Bool) ?? false
                return Item.at(url, isDirectory: isDirectory)!
            }) as Any
        }
    }

    static func nonDiscFile(at url: URL, modificationDate: Date = Date()) -> Item<Any>? {
        return Item<Any>(url: url, attributes: [.modificationDate: modificationDate] as FileAttributes?) { (attributes: FileAttributes, data: Data) in
            return data
        }
    }

    static func nonDiscAt(_ url: URL, modificationDate: Date = Date(), isDirectory: Bool = false) -> Item<Any>? {
        if isDirectory {
            return nonDiscDirectory(at: url, modificationDate: modificationDate)
        } else {
            return nonDiscFile(at: url, modificationDate: modificationDate)
        }
    }
}

extension Item {
    static func makeTestDirectory(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        FileManager.createDirectory(at: url)
        return Item.directory(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func makeTestImage(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        let image = UIImage.makeImage(withColor: UIColor.red)
        let imageData = UIImagePNGRepresentation(image)!
        try? imageData.write(to: url)
        return Item.file(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func makeTestAudio(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        let audioFileBundleResourcesURL = self.url(forResource: "audio", withExtension: "mp3")
        try? FileManager.default.copyItem(at: audioFileBundleResourcesURL, to: url)
        return Item.file(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func makeTestVideo(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        let videoFileBundleResourcesURL = self.url(forResource: "video", withExtension: "mp4")
        try? FileManager.default.copyItem(at: videoFileBundleResourcesURL, to: url)
        return Item.file(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func makeTestPDF(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        let pdfFileBundleResourcesURL = self.url(forResource: "pdf", withExtension: "pdf")
        try? FileManager.default.copyItem(at: pdfFileBundleResourcesURL, to: url)
        return Item.file(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func makeUnknownTestFile(at url: URL, modificationDate: Date = Date.testPastDate) -> Item<Any> {
        let unknownFileResourceURL = self.url(forResource: "pdf", withExtension: "pdf")
        try? FileManager.default.copyItem(at: unknownFileResourceURL, to: url)
        return Item.file(at: url, attributes: [.modificationDate: modificationDate])!
    }

    static func url(forResource resource: String, withExtension ext: String) -> URL {
        return Bundle(for: type(of: ItemTests())).url(forResource: resource, withExtension: ext)!
    }
}
