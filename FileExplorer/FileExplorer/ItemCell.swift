//
//  ItemCell.swift
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

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
}
protocol Editable {
    func setEditing(_ editing: Bool, animated: Bool)
}

enum ColorPallete {
    static let gray = UIColor(red: 200/255.0, green: 199/255.0, blue: 204/255.0, alpha: 0.5)
    static let blue = UIColor(red: 21/255.0, green: 126/255.0, blue: 251/255, alpha: 1.0)
}

enum LayoutConstants {
    static let separatorLeftInset: CGFloat = 22.0
    static let iconWidth: CGFloat = 44.0
}

final class ItemCell: SwipeCollectionViewCell, Editable {
    enum AccessoryType {
        case detailButton
        case disclosureIndicator
    }

    private var accessoryImageViewTapRecognizer: UITapGestureRecognizer
    private let separatorView: SeparatorView
    private let iconImageView: UIImageView
    private let titleTextLabel: UILabel
    private let subtitleTextLabel: UILabel
    private let accessoryImageView: UILabel
    private var customAccessoryType = AccessoryType.detailButton
    private let checkmarkButton: CheckmarkButton
    
    private var containerViewLeadingConstraint: NSLayoutConstraint!
    private var containerViewTrailingConstraint: NSLayoutConstraint!

    var tapAction: () -> Void = {}
    
    override init(frame: CGRect) {
        
        separatorView = SeparatorView()
        separatorView.backgroundColor = ColorPallete.gray
        

        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.borderWidth = 0
        //iconImageView.layer.borderColor = UIColor(red:248/255, green:45/255, blue:85/255, alpha:1.00).cgColor
        
        titleTextLabel = UILabel()
        titleTextLabel.numberOfLines = 1
        titleTextLabel.lineBreakMode = .byTruncatingMiddle
        titleTextLabel.font = UIFont.systemFont(ofSize: 17)
        
        
        subtitleTextLabel = UILabel()
        subtitleTextLabel.numberOfLines = 1
        subtitleTextLabel.lineBreakMode = .byTruncatingMiddle
        subtitleTextLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleTextLabel.textColor = UIColor.gray
        
        
        accessoryImageView = UILabel()
        accessoryImageView.font = UIFont.systemFont(ofSize: 18)
        accessoryImageView.textColor = UIColor(red:248/255, green:45/255, blue:85/255, alpha:1.00)
        //accessoryImageView.contentMode = .center
        

        checkmarkButton = CheckmarkButton()

        accessoryImageViewTapRecognizer = UITapGestureRecognizer(target: nil, action: nil)

        super.init(frame: frame)
        
        containerView.addSubview(separatorView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleTextLabel)
        containerView.addSubview(subtitleTextLabel)
        containerView.addSubview(accessoryImageView)
        
        containerView.backgroundColor = UIColor.dynamicColor(light: .white, dark: .black)
        
        
        backgroundColor = UIColor.dynamicColor(light: .white, dark: .black)

        accessoryImageViewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleAccessoryImageTap))
        accessoryImageViewTapRecognizer.delegate = self
        accessoryImageView.addGestureRecognizer(accessoryImageViewTapRecognizer)
        accessoryImageView.isUserInteractionEnabled = true

        addSubview(checkmarkButton)
        addSubview(containerView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        titleTextLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleTextLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkButton.translatesAutoresizingMaskIntoConstraints = false
        accessoryImageView.translatesAutoresizingMaskIntoConstraints = false

        setupContainerViewConstraints()
        setupSeparatorViewConstraints()
        setupIconImageViewConstraints()
        setupAccessoryImageViewConstraints()
        setupTitleLabelContstraints()
        setupSubtitleLabelConstraints()
        setupCheckmarkButtonConstraints()
        
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContainerViewConstraints() {
        containerViewLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        containerViewLeadingConstraint.isActive = true
        containerViewTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        containerViewTrailingConstraint.isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    private func setupSeparatorViewConstraints() {
        separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: LayoutConstants.separatorLeftInset).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }

    private func setupIconImageViewConstraints() {
        iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24.0).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: LayoutConstants.iconWidth).isActive = true
        iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0).isActive = true
        iconImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10.0).isActive = true
    }
    
    private func setupAccessoryImageViewConstraints() {
        accessoryImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15).isActive = true
        accessoryImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        accessoryImageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        accessoryImageView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)
        accessoryImageView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
    }
    
    private func setupTitleLabelContstraints() {
        titleTextLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12.0).isActive = true
        titleTextLabel.trailingAnchor.constraint(equalTo: accessoryImageView.leadingAnchor, constant: -10.0).isActive = true
        titleTextLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12.0).isActive = true
        titleTextLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        titleTextLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
    }
    
    private func setupSubtitleLabelConstraints() {
        subtitleTextLabel.leadingAnchor.constraint(equalTo: titleTextLabel.leadingAnchor).isActive = true
        subtitleTextLabel.trailingAnchor.constraint(equalTo: titleTextLabel.trailingAnchor).isActive = true
        subtitleTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 3.0).isActive = true
        subtitleTextLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh
            , for: .horizontal)
        subtitleTextLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
    }

    private func setupCheckmarkButtonConstraints() {
        checkmarkButton.trailingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: -4.0).isActive = true
        checkmarkButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1.0).isActive = true
    }
    
    var title: String? {
        get {
            return titleTextLabel.text
        }
        set(newValue) {
            titleTextLabel.text = newValue
        }
    }
    
    var subtitle: String? {
        get {
            return subtitleTextLabel.text
        }
        set(newValue) {
            subtitleTextLabel.text = newValue
        }
    }
    
    var iconImage: UIImage? {
        get {
            return iconImageView.image
        }
        set(newValue) {
            iconImageView.image = newValue
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set(newValue) {
            super.isSelected = newValue
            checkmarkButton.setSelected(newValue, animated: UIView.areAnimationsEnabled)
            setNeedsLayout()
        }
    }
    
    var isEditing: Bool = false {
        didSet {
            containerViewLeadingConstraint.constant = isEditing ? 38.0 : 0.0
            containerViewTrailingConstraint.constant = isEditing ? 38.0 : 0.0
            setNeedsLayout()
        }
    }

    func setEditing(_ editing: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.isEditing = editing
                self.layoutIfNeeded()
            }
        } else {
            self.isEditing = editing
        }
    }
    
    var accessoryType: AccessoryType {
        get {
            return customAccessoryType
        }
        set(newValue) {
            customAccessoryType = newValue
            switch customAccessoryType {
            case .detailButton:
                //accessoryImageView.image = UIImage.make(for: "DetailButtonImage")
                accessoryImageView.text = "ⓘ"
                accessoryImageViewTapRecognizer.isEnabled = true
                //accessoryImageView.textColor = UIColor(hex: 0x0075ff)
            case .disclosureIndicator:
                //accessoryImageView.image = UIImage.make(for: "DisclosureButtonImage")
                accessoryImageView.text = "〉"
                //accessoryImageView.textColor = UIColor(hex: 0x0075ff)
                accessoryImageViewTapRecognizer.isEnabled = false
            }
            setNeedsLayout()
        }
    }

    var maximumIconSize: CGSize {
        let max = Swift.max(Swift.max(iconImageView.frame.width, iconImageView.frame.height), LayoutConstants.iconWidth)
        return CGSize(width: max, height: max)
    }

    // MARK: Actions

    @objc func handleAccessoryImageTap() {
        tapAction()
    }
}

extension ItemCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

final class CollectionViewHeader: UICollectionReusableView {
    private let segmentedControl: UISegmentedControl
    var sortModeChangeAction: (SortMode) -> Void = { _ in }
    
    override init(frame: CGRect) {
        segmentedControl = UISegmentedControl(items: ["Name", "Date"])
        super.init(frame: frame)
        segmentedControl.sizeToFit()
        segmentedControl.frame.size = CGSize(width: 160.0, height: segmentedControl.bounds.size.height)
        segmentedControl.autoresizingMask = []
        segmentedControl.addTarget(self, action: #selector(handleSegmentedControlValueChanged), for: .valueChanged)
        addSubview(segmentedControl)
        sortMode = .name
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedControl.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var sortMode: SortMode {
        get {
            switch segmentedControl.selectedSegmentIndex {
            case 0: return .name
            case 1: return .date
            default: fatalError()
            }
        }
        set(newValue) {
            switch newValue {
            case .name: segmentedControl.selectedSegmentIndex = 0
            case .date: segmentedControl.selectedSegmentIndex = 1
            }
        }
    }

    @objc
    private func handleSegmentedControlValueChanged() {
        sortModeChangeAction(sortMode)
    }
}

final class CollectionViewFooter: UICollectionReusableView {
    var leftInset: CGFloat = LayoutConstants.separatorLeftInset
    private var separators = [SeparatorView]()
    
    override init(frame: CGRect) {
        for _ in 0..<15 {
            separators.append(SeparatorView())
        }
        super.init(frame: frame)
        for separator in separators {
            addSubview(separator)
        }
        tintColor = ColorPallete.gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for (i, separator) in separators.enumerated() {
            let size = CGSize(width: bounds.width - leftInset, height: 1.0)
            separator.frame.size = separator.sizeThatFits(size)
            separator.frame.origin = CGPoint(x: leftInset, y: CGFloat(i+1) * 64.0 - size.height)
        }
    }
    
    override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        set(newValue) {
            super.tintColor = newValue
            adjustAfterTintColorChange()
        }
    }

    override func tintColorDidChange() {
        adjustAfterTintColorChange()
    }

    private func adjustAfterTintColorChange() {
        for separator in separators {
            separator.backgroundColor = tintColor
        }
    }
}

final class SeparatorView: UIView {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 1.0/UIScreen.main.scale)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude, height: 1.0/UIScreen.main.scale)
    }
}
