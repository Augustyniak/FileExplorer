//
//  AppDelegate.swift
//  FileExplorerExampleApp
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

import UIKit
import FileExplorer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let directoryURL = URL.documentDirectory
        let audioURL = Bundle.main.url(forResource: "audio", withExtension: "mp3")!
        let videoURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        let pdfURL = Bundle.main.url(forResource: "pdf", withExtension: "pdf")!
        let image = UIImage(named: "image.jpg")!
        let imageData = image.pngData()!


        let firstDirectoryURL = directoryURL.appendingPathComponent("Directory")
        try? FileManager.default.createDirectory(at: firstDirectoryURL, withIntermediateDirectories: true, attributes: convertToOptionalFileAttributeKeyDictionary([String: Any]()))

        let items = [
            (audioURL, "audio.mp3"),
            (videoURL, "video.mp4"),
            (pdfURL, "pdf.pdf")
        ]
        for (url, filename) in items {
            let destinationURL = firstDirectoryURL.appendingPathComponent(filename)
            try? FileManager.default.copyItem(at: url, to: destinationURL)
        }

        let imageURL = firstDirectoryURL.appendingPathComponent("image.png")
        try? imageData.write(to: imageURL)

        let subdirectoryURL = firstDirectoryURL.appendingPathComponent("Empty Directory")
        try? FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: convertToOptionalFileAttributeKeyDictionary([String: Any]()))

        let secondDirectoryURL = directoryURL.appendingPathComponent("Empty Directory")
        try? FileManager.default.createDirectory(at: secondDirectoryURL, withIntermediateDirectories: true, attributes: convertToOptionalFileAttributeKeyDictionary([String: Any]()))

        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalFileAttributeKeyDictionary(_ input: [String: Any]?) -> [FileAttributeKey: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (FileAttributeKey(rawValue: key), value)})
}
