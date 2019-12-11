//
//  UICollectionView+Extension.swift
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

extension UICollectionView {
    @objc func registerCell(ofClass cellClass: AnyClass) {
        register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(ofClass cellClass: AnyClass, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: cellClass), for: indexPath) as? T else {
            let stringDescribingCellClass = String(describing: cellClass)
            fatalError("Cell with class \(stringDescribingCellClass) can't be dequeued")
        }
        if let editableCell = cell as? Editable {
            editableCell.setEditing(isEditing, animated: false)
        }
        return cell
    }
    
    @objc func registerFooter(ofClass viewClass: AnyClass) {
        register(viewClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: viewClass))
    }
    
    func dequeueReusableFooter<T: UICollectionReusableView>(ofClass cellClass: AnyClass, for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: cellClass), for: indexPath) as! T
    }
    
    @objc func registerHeader(ofClass viewClass: AnyClass) {
        register(viewClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: viewClass))
    }
    
    func dequeueReusableHeader<T: UICollectionReusableView>(ofClass cellClass: AnyClass, for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: cellClass), for: indexPath) as! T
    }

    func header<T: UICollectionReusableView>(for indexPath: IndexPath) -> T? {
        return supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath) as? T
    }
}

extension UICollectionView {
    @nonobjc static var kIsEditingKey = "isEditing"
    @nonobjc static var kToolbarKey = "toolbar"
    @nonobjc static var kToolbarBottomConstraint = "bottomConstraint"

    @objc var isEditing: Bool {
        get {
            return (objc_getAssociatedObject(self, &UICollectionView.kIsEditingKey) as? NSNumber)?.boolValue ?? false
        }
        set(newValue) {
            setEditing(newValue, animated: false)
        }
    }
    
    @objc var toolbar: UIToolbar? {
        get {
            return (objc_getAssociatedObject(self, &UICollectionView.kToolbarKey)) as? UIToolbar
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UICollectionView.kToolbarKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private var toolbarBottomConstraint: NSLayoutConstraint? {
        get {
            return (objc_getAssociatedObject(self, &UICollectionView.kToolbarBottomConstraint)) as? NSLayoutConstraint
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UICollectionView.kToolbarBottomConstraint, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    @objc func setEditing(_ editing: Bool, animated: Bool) {
        for cell in visibleCells {
            guard let cell = cell as? Editable else {
                continue
            }
            cell.setEditing(editing, animated: animated)
        }

        objc_setAssociatedObject(self, &UICollectionView.kIsEditingKey, NSNumber(value: editing), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}


