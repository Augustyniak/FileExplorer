//
//  DirectoryContentViewModelTests.swift
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

final class MockedDirectoryContentViewModelDelegate: DirectoryContentViewModelDelegate {
    var directoryViewModelDidChangeItemsListWasCalled = false
    var directoryViewModelDidChangeWasCalled = false

    func directoryViewModelDidChangeItemsList(_ viewModel: DirectoryContentViewModel) {
        directoryViewModelDidChangeItemsListWasCalled = true
    }

    func directoryViewModelDidChange(_ viewModel: DirectoryContentViewModel) {
        directoryViewModelDidChangeWasCalled = true
    }
    
    func directoryViewModel(_ viewModel: DirectoryContentViewModel, didSelectItem item: Item<Any>) {
        
    }
}

final class MockedFileService: FileService {
    func load(item: Item<Any>, completionBlock: @escaping (Result<LoadedItem<Any>>) -> ()) {

    }

    func delete(items: [Item<Any>], completionBlock: @escaping (_ result: Result<Void>, _ removedItems: [Item<Any>], _ itemsNotRemovedDueToFailure: [Item<Any>]) -> Void) {
        completionBlock(.success(), items, [Item<Any>]())
    }
}

final class DirectoryContentViewModelTests: XCTestCase {
    var viewModel: DirectoryContentViewModel!
    var viewModelDelegate: MockedDirectoryContentViewModelDelegate!
    var directoryItem: Item<Any>!
    var itemsInDirectory: [Item<Any>]!

    override func setUp() {
        super.setUp()

        let directoryURL = FileManager.createCacheDirectory()
        directoryItem = Item<Any>.makeTestDirectory(at: directoryURL)

        itemsInDirectory = [
            Item<Any>.makeTestImage(at: directoryURL.appendingPathComponent("image.png")),
            Item<Any>.makeTestAudio(at: directoryURL.appendingPathComponent("audio.mp3")),
            Item<Any>.makeTestVideo(at: directoryURL.appendingPathComponent("video.avi")),
            Item<Any>.makeTestPDF(at: directoryURL.appendingPathComponent("pdf.pdf")),
            Item<Any>.makeTestDirectory(at: directoryURL.appendingPathComponent("directory"))
        ]

        self.viewModelDelegate = MockedDirectoryContentViewModelDelegate()
        let loadedItem = LoadedItem(item: directoryItem, attributes: FileAttributes(), resource: itemsInDirectory).cast() as LoadedDirectoryItem

        viewModel = DirectoryContentViewModel(item: loadedItem, fileSpecifications: FileSpecifications(), configuration: Configuration())
        viewModel.delegate = self.viewModelDelegate
    }

    func testWhetherItemIsRemoved() {
        let numberOfItemsInFirstSection = viewModel.numberOfItems(inSection: 0)
        let expectation = self.expectation(description: "removal completion block")
        viewModel.deleteItems(at: [IndexPath.make(item: 0)], completionBlock: { result in
            if result.isSuccess {
                expectation.fulfill()
            }
            XCTAssertEqual(self.viewModel.numberOfItems(inSection: 0), numberOfItemsInFirstSection - 1)
        })

        waitForExpectations(timeout: 1.0)
    }

    func testWhetherDelegateIsInformedAboutItemRemoval() {
        let expectation = self.expectation(description: "removal completion block")
        viewModel.deleteItems(at: [IndexPath.make(item: 0)], completionBlock: { result in
            XCTAssertTrue(self.viewModelDelegate.directoryViewModelDidChangeItemsListWasCalled)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0)
    }
}


final class NonDiscDirectoryContentViewModelTests: XCTestCase {
    var fileService: MockedFileService!
    var viewModel: DirectoryContentViewModel!
    var viewModelDelegate: MockedDirectoryContentViewModelDelegate!
    var directoryItem: Item<Any>!
    var loadedItem: LoadedItem<[Item<Any>]>!
    var itemsInDirectory: [Item<Any>]!

    override func setUp() {
        super.setUp()

        let savedTimeInterval = NSDate().timeIntervalSince1970
        let directoryURL = URL(fileURLWithPath: "directory/directory1")
        directoryItem = Item<Any>.nonDiscDirectory(at: directoryURL)!

        itemsInDirectory = [
            Item<Any>.nonDiscFile(at: directoryURL.appendingPathComponent("image.png"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval+1))!,
            Item<Any>.nonDiscFile(at: directoryURL.appendingPathComponent("audio.mp3"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval))!,
            Item<Any>.nonDiscFile(at: directoryURL.appendingPathComponent("video.avi"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval+2))!,
            Item<Any>.nonDiscFile(at: directoryURL.appendingPathComponent("pdf.pdf"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval+3))!,
            Item<Any>.nonDiscDirectory(at: directoryURL.appendingPathComponent("directory"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval+4))!,
            Item<Any>.nonDiscDirectory(at: directoryURL.appendingPathComponent("directory2"), modificationDate: Date(timeIntervalSince1970: savedTimeInterval+5))!
        ]

        viewModelDelegate = makeViewModelDelegate()

        loadedItem = LoadedItem(item: directoryItem, attributes: FileAttributes(), resource: itemsInDirectory).cast() as LoadedItem<[Item<Any>]>
        fileService = MockedFileService()
        viewModel = makeViewModel(filteringConfiguration: FilteringConfiguration())
        viewModel.delegate = viewModelDelegate
    }

    //Mark:

    func testTitle() {
        XCTAssertEqual(viewModel.title, directoryItem.url.lastPathComponent)
    }

    func testEditingActionTitle() {
        viewModel.isEditing = false
        XCTAssertEqual(viewModel.editActionTitle, NSLocalizedString("Select", comment: ""))
        viewModel.isEditing = true
        XCTAssertEqual(viewModel.editActionTitle, NSLocalizedString("Cancel", comment: ""))
    }

    func testWhetherAllItemsAreDeselectedAfterViewModelExitsEditingState() {
        viewModel.isEditing = true
        viewModel.select(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(viewModel.indexPathsOfSelectedCells.count, 1)
        
        viewModel.isEditing = false
        XCTAssertEqual(viewModel.indexPathsOfSelectedCells.count, 0)
    }

    func testWhetherDelegateIsNotifiedAboutChangeAfterEditingStateIsEnabled() {
        viewModel.isEditing = false
        viewModel.isEditing = true
        XCTAssertTrue(viewModelDelegate.directoryViewModelDidChangeWasCalled)
    }

    //Mark: Editing Action

    func testWhetherEditingActionIsHiddenWhenSelectionsAndDeletionsAreDisabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canChooseDirectories = false
        actionsConfiguration.canChooseFiles = false
        actionsConfiguration.canRemoveDirectories = false
        actionsConfiguration.canRemoveFiles = false

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        XCTAssertTrue(viewModel.isEditActionHidden)
    }

    func testWhetherEditingActionIsHiddenWhenSelectionsAreDisabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canChooseDirectories = false
        actionsConfiguration.canChooseFiles = false
        actionsConfiguration.canRemoveDirectories = true
        actionsConfiguration.canRemoveFiles = true

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        XCTAssertFalse(viewModel.isEditActionHidden)
    }

    func testWhetherEditingActionIsHiddenWhenDeletionsAreDisabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canChooseDirectories = false
        actionsConfiguration.canChooseFiles = false
        actionsConfiguration.canRemoveDirectories = true
        actionsConfiguration.canRemoveFiles = true

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        XCTAssertFalse(viewModel.isEditActionHidden)
    }

    //Mark: Filtering

    func testWhetherFileFilterAreApplied() {
        var filteringConfiguration = FilteringConfiguration()
        filteringConfiguration.fileFilters = [
            Filter.extension(itemsInDirectory[0].extension),
            Filter.extension(itemsInDirectory[1].extension)
        ]

        viewModel = makeViewModel(filteringConfiguration: filteringConfiguration)

        let displayedItems = self.getDisplayedItems()
        for item in displayedItems {
            XCTAssertTrue(item.url.pathExtension == itemsInDirectory[0].extension || item.url.pathExtension == itemsInDirectory[1].extension)
        }
    }

    func testWhetherIgnoredFilesFiltersAreApplied() {
        var filteringConfiguration = FilteringConfiguration()
        filteringConfiguration.ignoredFileFilters = [
            Filter.extension(itemsInDirectory[0].extension),
            Filter.extension(itemsInDirectory[1].extension)
        ]

        viewModel = makeViewModel(filteringConfiguration: filteringConfiguration)

        let displayedItems = self.getDisplayedItems()
        for item in displayedItems {
            XCTAssertFalse(item.url.pathExtension == itemsInDirectory[0].extension || item.url.pathExtension == itemsInDirectory[1].extension)
        }
    }

    //Mark: Selections

    func testWhetherSelectionActionStateIsCorrectWhenFileAndDirectorySelectionsAreEnabledAndMultipleSelectionIsDisabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: true,
                                                        canChooseDirectories: true,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionStateIsCorrectWhenOnlyFileSelectionsAreEnabledAndMultipleSelectionIsDisabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: true,
                                                        canChooseDirectories: false,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionStateIsCorrectWhenOnlyDirectorySelectionsAreEnabledAndMultipleSelectionIsDisabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: false,
                                                        canChooseDirectories: true,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionIsHiddenWhenDirectoryAndFilesSelectionsAreDisabledAndMultipleSelectionIsDisabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: true,
                                                        canChooseDirectories: true,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)

        XCTAssertFalse(viewModel.isSelectActionHidden)
    }

    func testWhetherSelectionActionStateIsCorrectWhenFileAndDirectorySelectionsAreEnabledAndMultipleSelectionIsEnabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: true,
                                                        canChooseDirectories: true,
                                                        allowsMultipleSelection: true)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionStateIsCorrectWhenOnlyFileSelectionsAreEnabledAndMultipleSelectionIsEnabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: true,
                                                        canChooseDirectories: false,
                                                        allowsMultipleSelection: true)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionStateIsCorrectWhenOnlyDirectorySelectionsAreEnabledAndMultipleSelectionIsEnabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: false,
                                                        canChooseDirectories: true,
                                                        allowsMultipleSelection: true)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertFalse(viewModel.isSelectActionEnabled)
    }

    func testWhetherSelectionActionIsHiddenWhenDirectoryAndFileSelectionsAreDisabledAndMultipleSelectionIsEnabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: false,
                                                        canChooseDirectories: false,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)

        XCTAssertTrue(viewModel.isSelectActionHidden)
    }


    //Mark: Deletions

    func testWhetherDeleteActionIsHiddenWhenDirectoryAndFileSelectionAreDisabled() {
        let actionsConfiguration = ActionsConfiguration(canRemoveFiles: false,
                                                        canRemoveDirectories: false,
                                                        canChooseFiles: false,
                                                        canChooseDirectories: false,
                                                        allowsMultipleSelection: false)
        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)

        XCTAssertTrue(viewModel.isDeleteActionHidden)
    }

    func testWhetherDeleteActionBecomesDisabledAfterViewModelExitsEditingState() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canRemoveFiles = true
        actionsConfiguration.canRemoveDirectories = true

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true
        viewModel.select(at: IndexPath(item: 0, section: 0))
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.isEditing = false
        XCTAssertFalse(viewModel.isDeleteActionEnabled)
    }

    func testWhetherDeleteActionStateIsCorrectWhenFileAndDirectoryDeletionAreEnabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canRemoveFiles = true
        actionsConfiguration.canRemoveDirectories = true

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        XCTAssertFalse(viewModel.isDeleteActionEnabled)

        let indexPathsOfFiles = self.indexPathsOfFiles()
        let indexPathsOfDirectories = self.indexPathsOfDirectories()

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[0])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathsOfDirectories[1])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        viewModel.deselect(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.deselect(at: indexPathsOfDirectories[0])
        viewModel.deselect(at: indexPathsOfDirectories[1])
        XCTAssertFalse(viewModel.isDeleteActionEnabled)
    }

    func testWhetherDeleteActionStateIsCorrectWhenOnlyDirectoryDeletionsAreEnabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canRemoveFiles = false
        actionsConfiguration.canRemoveDirectories = true

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathOfFiles = self.indexPathsOfFiles()

        viewModel.select(at: indexPathOfDirectory())
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathOfFiles[0])
        XCTAssertFalse(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathOfFiles[1])
        XCTAssertFalse(viewModel.isDeleteActionEnabled)

        viewModel.deselect(at: indexPathOfFiles[0])
        viewModel.deselect(at: indexPathOfFiles[1])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)
    }

    func testWhetherDeleteActionStateIsCorrectWhenOnlyFileDeletionsAreEnabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canRemoveFiles = true
        actionsConfiguration.canRemoveDirectories = false

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true

        let indexPathsOfFiles = self.indexPathsOfFiles()

        viewModel.select(at: indexPathsOfFiles[0])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathsOfFiles[1])
        XCTAssertTrue(viewModel.isDeleteActionEnabled)

        viewModel.select(at: indexPathOfDirectory())
        XCTAssertFalse(viewModel.isDeleteActionEnabled)

        viewModel.deselect(at: indexPathsOfFiles[0])
        viewModel.deselect(at: indexPathsOfFiles[1])
    }

    func testWhetherDeleteActionIsHiddenWhenFileAndDirectoryDeletionsAreDisabled() {
        var actionsConfiguration = ActionsConfiguration()
        actionsConfiguration.canRemoveFiles = false
        actionsConfiguration.canRemoveDirectories = false

        viewModel = makeViewModel(actionsConfiguration: actionsConfiguration)
        viewModel.isEditing = true
        XCTAssertTrue(viewModel.isDeleteActionHidden)
    }

    //Mark: Sorting

    func testWhetherSortByNameWorks() {
        let itemsInExpectedOrder = [
            "audio.mp3",
            "directory",
            "directory2",
            "image.png",
            "pdf.pdf",
            "video.avi"
        ]

        //check initial order
        verifyOrderOfItems(itemsInExpectedOrder)
        viewModel.sortMode = .name
        verifyOrderOfItems(itemsInExpectedOrder)
    }


    func testWhetherSortByModificationDateWorks() {
        let itemsInExpectedOrder = [
            "directory2",
            "directory",
            "pdf.pdf",
            "video.avi",
            "image.png",
            "audio.mp3"
            ]

        viewModel.sortMode = .date
        verifyOrderOfItems(itemsInExpectedOrder)
    }

    func testWhetherDelegateIsNotifiedWhenSortOrderChanges() {
        XCTAssertFalse(viewModelDelegate.directoryViewModelDidChangeItemsListWasCalled)
        viewModel.sortModeChangeAction(.name)
        XCTAssertTrue(viewModelDelegate.directoryViewModelDidChangeItemsListWasCalled)
    }

    func verifyOrderOfItems(_ itemsInExpectedOrder: [String]) {
        for i in 0..<viewModel.numberOfItems(inSection: 0) {
            let itemViewModel = viewModel.viewModel(for: IndexPath.make(item: i))
            XCTAssertEqual(itemViewModel.title, itemsInExpectedOrder[i])
        }
    }
}

extension NonDiscDirectoryContentViewModelTests {
    func makeViewModel(fileSpecifications: FileSpecifications = FileSpecifications(), configuration: Configuration = Configuration()) -> DirectoryContentViewModel {
        return DirectoryContentViewModel(item: loadedItem, fileSpecifications: fileSpecifications, configuration: configuration, fileService: fileService)
    }

    func makeViewModel(fileSpecifications: FileSpecifications = FileSpecifications(), actionsConfiguration: ActionsConfiguration = ActionsConfiguration(), filteringConfiguration: FilteringConfiguration = FilteringConfiguration()) -> DirectoryContentViewModel {
        let configuration = Configuration(actionsConfiguration: actionsConfiguration, filteringConfiguration: filteringConfiguration)
        return makeViewModel(fileSpecifications: fileSpecifications, configuration: configuration)
    }

    func makeViewModelDelegate() -> MockedDirectoryContentViewModelDelegate {
        return MockedDirectoryContentViewModelDelegate()
    }

    func getDisplayedItems() -> [Item<Any>] {
        var displayedItems = [Item<Any>]()
        for i in 0..<viewModel.numberOfItems(inSection: 0) {
            displayedItems.append(viewModel.item(for: IndexPath(item: i, section: 0)))
        }
        return displayedItems
    }

    func indexPathsOfDirectories() -> [IndexPath] {
        let displayedItems = getDisplayedItems()
        return displayedItems.flatMap {
            if $0.type == .directory {
                return IndexPath(item: displayedItems.index(of: $0)!, section: 0)
            } else {
                return nil
            }}
    }

    func indexPathOfDirectory() -> IndexPath {
        return indexPathsOfDirectories().first!
    }

    func indexPathsOfFiles() -> [IndexPath] {
        let displayedItems = getDisplayedItems()
        return displayedItems.flatMap {
            if $0.type == .file {
                return IndexPath(item: displayedItems.index(of: $0)!, section: 0)
            } else {
                return nil
            }}
    }
}
