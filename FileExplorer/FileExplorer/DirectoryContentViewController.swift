//
//  DirectoryContentViewController.swift
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

protocol DirectoryContentViewControllerDelegate: class {
    func directoryContentViewController(_ controller: DirectoryContentViewController, didChangeEditingStatus isEditing: Bool)
    func directoryContentViewController(_ controller: DirectoryContentViewController, didSelectItem item: Item<Any>)
    func directoryContentViewController(_ controller: DirectoryContentViewController, didSelectItemDetails item: Item<Any>)
    func directoryContentViewController(_ controller: DirectoryContentViewController, didChooseItems items: [Item<Any>])
}

final class DirectoryContentViewController: UICollectionViewController {
    weak var delegate: DirectoryContentViewControllerDelegate?

    fileprivate let viewModel: DirectoryContentViewModel

    private let toolbar: UIToolbar
    private var toolbarBottomConstraint: NSLayoutConstraint?
    private var isFirstLayout = true

    override var collectionViewLayout: UICollectionViewFlowLayout {
        get {
            return collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        }
    }

    init(viewModel: DirectoryContentViewModel) {
        self.viewModel = viewModel
        self.toolbar = UIToolbar.makeToolbar()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 200, height: 64.0)
        layout.minimumLineSpacing = 0

        super.init(collectionViewLayout: layout)
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let collectionView = collectionView else { return }

        collectionViewLayout.itemSize = CGSize(width: view.bounds.width, height: 64.0)
        collectionViewLayout.headerReferenceSize = CGSize(width: view.bounds.width, height: 44.0)
        collectionViewLayout.footerReferenceSize = CGSize(width: view.bounds.width, height: collectionView.frame.height - CGFloat(viewModel.numberOfItems(inSection: 0)) * collectionViewLayout.itemSize.height)
        if isFirstLayout {
            isFirstLayout = false
            collectionView.contentOffset.y = 44.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let collectionView = collectionView else { return }

        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []

        collectionView.backgroundColor = UIColor.white
        collectionView.registerCell(ofClass: ItemCell.self)
        collectionView.registerHeader(ofClass: CollectionViewHeader.self)
        collectionView.registerFooter(ofClass: CollectionViewFooter.self)
        collectionView.alwaysBounceVertical = true
        collectionView.allowsMultipleSelection = true
        collectionView.addSubview(toolbar)

        self.toolbarBottomConstraint = toolbar.pinToBottom(of: view)
        self.toolbarBottomConstraint?.constant = toolbar.bounds.height
        
        syncWithViewModel(false)
    }

    @objc func syncWithViewModel(_ animated: Bool) {
        if let items = toolbar.items {
            for barButtonItem in items {
                barButtonItem.isEnabled = viewModel.isDeleteActionEnabled
            }
        }

        syncToolbarWithViewModel()
        let editBarButtonItem = viewModel.isEditActionHidden ? nil : UIBarButtonItem(title: viewModel.editActionTitle, style: .plain, target: self, action: #selector(handleEditButtonTap))
        editBarButtonItem?.isEnabled = viewModel.isEditActionEnabled
        activeRightBarButtonItem = editBarButtonItem
        activeNavigationItemTitle = viewModel.title
        view.isUserInteractionEnabled = viewModel.isUserInteractionEnabled
        setEditing(viewModel.isEditing, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard let collectionView = collectionView, collectionView.isEditing != editing else {
            return
        }

        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems, !editing {
            for indexPath in indexPathsForSelectedItems {
                collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }

        collectionView.setEditing(editing, animated: animated)
        UIView.animate(withDuration: 0.2) {
            self.toolbarBottomConstraint?.constant = editing ? 0.0 : self.toolbar.bounds.height
            collectionView.contentInset.bottom = editing ? self.toolbar.bounds.height : 0.0
            collectionView.scrollIndicatorInsets = collectionView.contentInset
            collectionView.layoutIfNeeded()
        }

        viewModel.isEditing = editing
    }

    @objc func syncToolbarWithViewModel() {
        let selectActionButton = !viewModel.isSelectActionHidden ? UIBarButtonItem(title: viewModel.selectActionTitle, style: .plain, target: self, action: #selector(handleSelectButtonTap)) : nil
        selectActionButton?.isEnabled = viewModel.isSelectActionEnabled
        let deleteActionButton = !viewModel.isDeleteActionHidden ? UIBarButtonItem(title: viewModel.deleteActionTitle, style: .plain, target: self, action: #selector(handleDeleteButtonTap)) : nil
        deleteActionButton?.isEnabled = viewModel.isDeleteActionEnabled
        toolbar.items = [
            selectActionButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            deleteActionButton
            ].compactMap { $0 }
    }

    // MARK: Actions

    @objc func handleSelectButtonTap() {
        viewModel.chooseItems { selectedItems in
            delegate?.directoryContentViewController(self, didChooseItems: selectedItems)
        }
    }

    @objc func handleDeleteButtonTap() {
        showLoadingIndicator()
        viewModel.deleteItems(at: viewModel.indexPathsOfSelectedCells) { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.hideLoadingIndicator()
            
            if case .error(let error) = result {
                UIAlertController.presentAlert(for: error, in: strongSelf)
            }

            strongSelf.viewModel.isEditing = false
            strongSelf.delegate?.directoryContentViewController(strongSelf, didChangeEditingStatus: strongSelf.viewModel.isEditing)
        }
    }

    @objc func handleEditButtonTap() {
        viewModel.isEditing = !viewModel.isEditing
        delegate?.directoryContentViewController(self, didChangeEditingStatus: viewModel.isEditing)
    }
}

extension DirectoryContentViewController: DirectoryContentViewModelDelegate {
    func directoryViewModelDidChangeItemsList(_ viewModel: DirectoryContentViewModel) {
        guard let collectionView = collectionView else { return }
        collectionView.reloadData()
    }

    func directoryViewModelDidChange(_ viewModel: DirectoryContentViewModel) {
        syncWithViewModel(true)
    }

    func directoryViewModel(_ viewModel: DirectoryContentViewModel, didSelectItem item: Item<Any>) {
        delegate?.directoryContentViewController(self, didSelectItem: item)
    }
}

extension DirectoryContentViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(inSection: section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofClass: ItemCell.self, for: indexPath) as ItemCell
        let itemViewModel = viewModel.viewModel(for: indexPath)

        cell.tapAction = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.directoryContentViewController(strongSelf, didSelectItemDetails: strongSelf.viewModel.item(for: indexPath))
        }
        cell.isSelected = viewModel.indexPathsOfSelectedCells.contains { $0 == indexPath }
        cell.title = itemViewModel.title
        cell.subtitle = itemViewModel.subtitle
        cell.accessoryType = itemViewModel.accessoryType
        cell.iconImage = itemViewModel.thumbnailImage(with: cell.maximumIconSize)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableHeader(ofClass: CollectionViewHeader.self, for: indexPath) as CollectionViewHeader
            header.sortModeChangeAction = viewModel.sortModeChangeAction
            header.sortMode = viewModel.sortMode
            UIView.performWithoutAnimation {
                header.layoutIfNeeded()
            }
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            return collectionView.dequeueReusableFooter(ofClass: CollectionViewFooter.self, for: indexPath) as CollectionViewFooter
        } else {
            fatalError()
        }
    }
}

extension DirectoryContentViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.select(at: indexPath)
        if !viewModel.isSelectionEnabled {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        viewModel.deselect(at: indexPath)
    }
}

extension DirectoryContentViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchQuery = searchController.searchBar.text
    }
}
