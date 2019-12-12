//
//  FileSpecificationProvider.swift
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
import AVFoundation
import AVKit

/// Protocol providing an interface that describes file type.
public protocol FileSpecificationProvider: class {

    /// Extensions that are a part of described file type.
    static var extensions: [String] { get }

    /// Creates and returns a thumbnail image for image that is located at specified URL.
    ///
    /// - Parameters:
    ///   - url: URL of the file for which thumbnail image should be generated.
    ///   - size: Requested size of the thumbnail.
    /// - Returns: Thumbnail of the file that is located at the specified URL. Return nil to if you want FileExplorer to use the default thumbnail for document files.
    static func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage?

    /// Creates and returns a view controller that is used to display content of the file of the specified file type.
    ///
    /// - Parameters:
    ///   - url: URL of the file that should be displayed in created view controller.
    ///   - data: Data of the file that should be displayed in created view controller.
    ///   - attributes: Attributes of the file that should be displayed in created view controller.
    /// - Returns: View Controller that should display content of the file that is localted at the specified URL.
    static func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController
}

private extension FileSpecificationProvider {
    static func describesItem(_ item: Item<Any>) -> Bool {
        return extensions.filter { $0 == item.extension }.count > 0
    }
}

final class FileSpecifications {
    let providers: [FileSpecificationProvider.Type]
    private let fallbackProvider: FileSpecificationProvider.Type

    convenience init() {
        self.init(providers: [])
    }

    init(providers: [FileSpecificationProvider.Type], fallbackProvider: DefaultFileSpecificationProvider.Type = DefaultFileSpecificationProvider.self) {
        let defaultProviders: [FileSpecificationProvider.Type] = [
            ImageSpecificationProvider.self,
            VideoSpecificationProvider.self,
            AudioSpecificationProvider.self,
            PDFSpecificationProvider.self,
            DefaultFileSpecificationProvider.self
        ]
        self.providers = [providers, defaultProviders].flatMap { $0 }
        self.fallbackProvider = fallbackProvider
    }

    func itemSpecification(for item: Item<Any>) -> FileSpecificationProvider.Type {
        return providers.filter { $0.describesItem(item) }.first ?? fallbackProvider
    }
}

final class DefaultFileSpecificationProvider: FileSpecificationProvider {
    public class var extensions: [String] {
        return [String]()
    }

    public class func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage? {
        return nil
    }

    public class func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController {
        return UknownFileTypeViewController(fileName: url.lastPathComponent)
    }
}

/// Class describing video file type. It's capable of generating thumbnails for video files and provides view controller which allows for playback of video files.
public class VideoSpecificationProvider: FileSpecificationProvider {
    public class var extensions: [String] {
        return ["mp4", "avi", "mkv", "mov"]
    }

    public class func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage? {
        return BorderDecorator(thumbnailGenerator: VideoThumbnailGenerator(url: url)).generate(size: size)
    }

    public class func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController {
        let player = AVPlayer(url: url)
        let viewController = AVPlayerViewController()
        viewController.player = player
        return viewController
    }
}

/// Class describing audio file type. It provides generic thumbnail for audio files and a view controller which allows for playback of audio files.
public class AudioSpecificationProvider: FileSpecificationProvider {
    public class var extensions: [String] {
        return ["mp3", "wav"]
    }

    public class func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage? {
        return nil
    }

    public class func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController {
        let player = AVPlayer(url: url)
        let viewController = AVPlayerViewController()
        viewController.player = player
        return viewController
    }
}

/// Class describing image file type. It's capable of generating thumbnails for image files and provides preview view controller for image files.
public class ImageSpecificationProvider: FileSpecificationProvider {
    public class var extensions: [String] {
        return ["png", "jpg", "jpeg"]
    }

    public class func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage? {
        return BorderDecorator(thumbnailGenerator: ImageThumbnailGenerator(url: url)).generate(size: size)
    }

    public class func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController {
        guard let data = data, let image = UIImage(data: data) else { fatalError() }
        let viewController = ImageViewController(image: image)
        return viewController
    }
}

/// Class describing PDF file type. It's capable of generating thumbnails for PDF files and provides preview view controller for PDF files.
public class PDFSpecificationProvider: FileSpecificationProvider {
    public class var extensions: [String] {
        return ["pdf"]
    }

    public class func thumbnail(forItemAt url: URL, with size: CGSize) -> UIImage? {
        return BorderDecorator(thumbnailGenerator: PDFThumbnailGenerator(url: url)).generate(size: size)
    }

    public class func viewControllerForItem(at url: URL, data: Data?, attributes: FileAttributes) -> UIViewController {
        return WebViewController(url: url)
    }
}
