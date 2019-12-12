//
//  FileViewController.swift
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

final class FileViewController: UIViewController {
    private let viewModel: FileViewModel
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    init(viewModel: FileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []

        let imageView = ImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)

        let titleView = TitleView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.title = viewModel.title
        titleView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        titleView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)


        let attributesView = AttributesView()
        attributesView.translatesAutoresizingMaskIntoConstraints = false
        attributesView.numberOfAttributes = viewModel.numberOfAttributes
        attributesView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        attributesView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        for (index, label) in attributesView.attributeNamesColumn.labels.enumerated() {
            let attributeViewModel = viewModel.attribute(for: index)
            label.text = attributeViewModel.attributeName
        }
        for (index, label) in attributesView.attributeValuesColumn.labels.enumerated() {
            let attributeViewModel = viewModel.attribute(for: index)
            label.text = attributeViewModel.attributeValue
        }

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(attributesView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(stackView)

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        activeNavigationItemTitle = viewModel.title

        view.setNeedsLayout()
        view.layoutIfNeeded()
        imageView.customImage = viewModel.thumbnailImage(with: CGSize(width: imageView.bounds.width, height: imageView.bounds.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.frame = view.bounds
        scrollView.contentSize = view.bounds.size
        stackView.frame = CGRect(origin: CGPoint.zero, size: view.bounds.size)
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

final class ImageView: UIView {
    private let customImageView: UIImageView

    override init(frame: CGRect) {
        customImageView = UIImageView()
        customImageView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)

        addSubview(customImageView)
        customImageView.backgroundColor = UIColor.white
        customImageView.contentMode = .scaleAspectFit
        customImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        customImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        customImageView.widthAnchor.constraint(equalTo: widthAnchor, constant: -40).isActive = true
        customImageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -38).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var customImage: UIImage? {
        get {
            return customImageView.image
        }
        set(newValue) {
            customImageView.image = newValue
        }
    }
}

final class TitleView: UIView {
    private let titleLabel: UILabel

    override init(frame: CGRect) {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 23.0)
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1.0).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -20.0).isActive = true
        titleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        let topSeparator = SeparatorView()
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        topSeparator.backgroundColor = ColorPallete.gray
        addSubview(topSeparator)
        topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        topSeparator.topAnchor.constraint(equalTo: topAnchor).isActive = true

        let bottomSeparator = SeparatorView()
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparator.backgroundColor = ColorPallete.gray
        addSubview(bottomSeparator)
        bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomSeparator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var title: String? {
        get {
            return titleLabel.text
        }
        set(newValue) {
            titleLabel.text = newValue
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 42.0)
    }
}

final class AttributesView: UIView {
    private let stackView = UIStackView()
    fileprivate let attributeNamesColumn = AttributesColumnView()
    fileprivate let attributeValuesColumn = AttributesColumnView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        stackView.addArrangedSubview(attributeNamesColumn)
        attributeNamesColumn.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(attributeValuesColumn)
        attributeValuesColumn.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.layoutMargins = UIEdgeInsets(top: 16.0, left: 0, bottom: 17.0, right: 0.0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.distribution = .fillProportionally
        stackView.spacing = 10.0
        addSubview(stackView)
        stackView.edges(equalTo: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var numberOfAttributes: Int = 0 {
        didSet {
            attributeNamesColumn.numberOfAttributes = numberOfAttributes
            for label in attributeNamesColumn.labels {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.textAlignment = .right
                label.font = UIFont.systemFont(ofSize: 15.0)
                label.textColor = ColorPallete.gray
            }

            attributeValuesColumn.numberOfAttributes = numberOfAttributes
            for label in attributeValuesColumn.labels {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.textAlignment = .left
                label.font = UIFont.systemFont(ofSize: 15.0)
                label.textColor = UIColor.black
            }
        }
    }
}

final class AttributesColumnView: UIView {
    @objc var labels = [UILabel]()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10.0
        addSubview(stackView)
        stackView.edges(equalTo: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc var numberOfAttributes: Int = 0 {
        didSet {
            for view in labels {
                stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }

            for _ in 0..<numberOfAttributes {
                let label = UILabel()
                labels.append(label)
                stackView.addArrangedSubview(label)
            }
        }
    }
}
