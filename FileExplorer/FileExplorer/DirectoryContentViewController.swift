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
protocol DirectoryContentViewControllerDelegate: AnyObject {
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

    //SWIPE
    var defaultOptions = SwipeOptions()
    var isSwipeRightEnabled = true
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    var usesTallCells = false
    //SWIPE
    init(viewModel: DirectoryContentViewModel) {
        self.viewModel = viewModel
        self.toolbar = UIToolbar.makeToolbar()

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 200, height: 64.0)
        layout.minimumLineSpacing = 0

        super.init(collectionViewLayout: layout)
        viewModel.delegate = self
        navigationItem.title = ""
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

        collectionView.backgroundColor = UIColor.dynamicColor(light: .white, dark: .black)
        collectionView.registerCell(ofClass: ItemCell.self)
        collectionView.registerHeader(ofClass: CollectionViewHeader.self)
        collectionView.registerFooter(ofClass: CollectionViewFooter.self)
        collectionView.alwaysBounceVertical = true
        collectionView.allowsMultipleSelection = true
        collectionView.addSubview(toolbar)

        self.toolbarBottomConstraint = toolbar.pinToBottom(of: view)
        self.toolbarBottomConstraint?.constant = toolbar.bounds.height
        
        self.toolbar.isHidden = true
        
        syncWithViewModel(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = ""
    }
    
    func syncWithViewModel(_ animated: Bool) {
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
            self.toolbar.isHidden.toggle()
            self.toolbarBottomConstraint?.constant = editing ? 0.0 : self.toolbar.bounds.height
            collectionView.contentInset.bottom = editing ? self.toolbar.bounds.height : 0.0
            collectionView.scrollIndicatorInsets = collectionView.contentInset
            collectionView.layoutIfNeeded()
        }

        viewModel.isEditing = editing
    }

    func syncToolbarWithViewModel() {
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
        cell.delegate = self
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

extension DirectoryContentViewController: SwipeCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {

        let flag = SwipeAction(style: .default, title: nil, handler: nil)
        flag.hidesWhenSelected = true
        configure(action: flag, with: .flag)
        
        let delete = SwipeAction(style: .destructive, title: nil) { [self] action, indexPath in
            viewModel.deleteItems(at: [indexPath]) { [weak self] result in
                guard let strongSelf = self else { return }
                delegate?.directoryContentViewController(strongSelf, didChangeEditingStatus: strongSelf.viewModel.isEditing)
            }
        }
        configure(action: delete, with: .trash)
        
        return [delete]
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive
        options.transitionStyle = defaultOptions.transitionStyle
        
        switch buttonStyle {
        case .backgroundColor:
            options.buttonSpacing = 11
        case .circular:
            options.buttonSpacing = 4
        #if canImport(Combine)
            if #available(iOS 13.0, *) {
                options.backgroundColor = UIColor.systemGray6
            } else {
                options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
            }
        #else
            options.backgroundColor = #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        #endif
        }
        
        return options
    }
    
    func visibleRect(for collectionView: UICollectionView) -> CGRect? {
        if usesTallCells == false { return nil }
        
        if #available(iOS 11.0, *) {
            return collectionView.safeAreaLayoutGuide.layoutFrame
        } else {
            let topInset = navigationController?.navigationBar.frame.height ?? 0
            let bottomInset = navigationController?.toolbar?.frame.height ?? 0
            let bounds = collectionView.bounds
            
            return CGRect(x: bounds.origin.x, y: bounds.origin.y + topInset, width: bounds.width, height: bounds.height - bottomInset)
        }
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color(forStyle: buttonStyle)
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color(forStyle: buttonStyle)
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}
