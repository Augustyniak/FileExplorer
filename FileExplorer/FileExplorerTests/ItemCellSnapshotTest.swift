//
//  ItemCellSnapshotTest.swift
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
import FBSnapshotTestCase


final class MockCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(ofClass: ItemCell.self, for: indexPath)
    }
}

final class ItemCellSnapshotTest: FBSnapshotTestCase {
    var cell: ItemCell!
    var collectionView: UICollectionView!
    let dataSource = MockCollectionViewDataSource()
    
    override func setUp() {
        super.setUp()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 375, height: 64)
        collectionView = UICollectionView(frame: CGRect.iPhone6Bounds, collectionViewLayout: layout)
        collectionView.dataSource = dataSource
        collectionView.registerCell(ofClass: ItemCell.self)
        
        cell = collectionView.dequeueReusableCell(ofClass: ItemCell.self, for: IndexPath(item: 0, section: 0)) as ItemCell //ItemCell(frame: CGRect(x: 0, y: 0, width: 375, height: 64))
        cell.title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent a tortor mattis, malesuada risus a, ultrices justo. Duis non accumsan dui. Curabitur semper nunc eget erat venenatis vulputate."
        cell.subtitle = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas et pharetra metus, non finibus elit. Suspendisse potenti. Maecenas at nunc in arcu sollicitudin dignissim."
    }
    
    override func tearDown() {
        super.tearDown()
        
    }
    
    func testDetailAccessoryButton() {
        cell.accessoryType = .detailButton
        cell.iconImage = UIImage.makeImage(withColor: UIColor.red, size: CGSize(width: 60, height: 100))
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        FBSnapshotVerifyView(cell)
    }
    
    func testDisclosureIndicatorAccessoryButton() {
        cell.accessoryType = .disclosureIndicator
        FBSnapshotVerifyView(cell)
    }
    
    func testSelectionStateNotSelected() {
        cell.accessoryType = .detailButton
        cell.isEditing = true
        cell.isSelected = false
        FBSnapshotVerifyView(cell)
    }
    
    func testSelectionStateSelected() {
        cell.accessoryType = .detailButton
        cell.isEditing = true
        cell.isSelected = true
        FBSnapshotVerifyView(cell)
    }
    
}
