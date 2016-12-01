test: 
	xcodebuild \
	-workspace FileExplorer/FileExplorer.xcworkspace \
	-scheme FileExplorerTestHostApp \
	-destination "platform=iOS Simulator,name=iPhone 7,OS=10.1" \
	test \
	| xcpretty -ct
clean: 
	xcodebuild \
	-workspace FileExplorer/FileExplorer.xcworkspace \
	-scheme FileExplorerTestHostApp \
	clean
