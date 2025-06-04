import Cocoa
import Quartz
import Foundation
import UniformTypeIdentifiers

class PreviewViewController: NSViewController, QLPreviewingController {
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
    
    override func loadView() {
        self.view = NSView()
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        // Handler must be called on main thread
        DispatchQueue.main.async {
            do {
                let preview = try self.generateFolderPreview(for: url)
                self.view.subviews.removeAll()
                self.view.addSubview(preview)
                
                // Set up constraints
                preview.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    preview.topAnchor.constraint(equalTo: self.view.topAnchor),
                    preview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    preview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    preview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
                
                handler(nil)
            } catch {
                handler(error)
            }
        }
    }
    
    private func generateFolderPreview(for url: URL) throws -> NSView {
        let containerView = NSView()
        
        // Create background
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Create scroll view for the content
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create content view
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Header
        let headerView = createHeaderView(for: url)
        contentView.addSubview(headerView)
        
        // File list
        let fileListView = try createFileListView(for: url)
        contentView.addSubview(fileListView)
        
        // Layout header and file list
        headerView.translatesAutoresizingMaskIntoConstraints = false
        fileListView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            fileListView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            fileListView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fileListView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fileListView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Set up scroll view
        scrollView.documentView = contentView
        containerView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Set content view width to scroll view width
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        return containerView
    }
    
    private func createHeaderView(for url: URL) -> NSView {
        let headerView = NSView()
        
        // Folder icon
        let iconView = NSImageView()
        iconView.image = NSWorkspace.shared.icon(forFile: url.path)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Folder name
        let nameLabel = NSTextField(labelWithString: url.lastPathComponent)
        nameLabel.font = NSFont.boldSystemFont(ofSize: 18)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Path label
        let pathLabel = NSTextField(labelWithString: url.path)
        pathLabel.font = NSFont.systemFont(ofSize: 12)
        pathLabel.textColor = NSColor.secondaryLabelColor
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(iconView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(pathLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            pathLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            pathLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            pathLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        return headerView
    }
    
    private func createFileListView(for url: URL) throws -> NSView {
        let listView = NSView()
        var currentY: CGFloat = 0
        
        // Get directory contents
        let fileManager = FileManager.default
        
        // Check if we have permission to read the directory
        guard fileManager.isReadableFile(atPath: url.path) else {
            return createErrorView(message: "Cannot read folder contents - permission denied")
        }
        
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .localizedNameKey
            ], options: [.skipsHiddenFiles])
        } catch {
            return createErrorView(message: "Error reading folder: \(error.localizedDescription)")
        }
        
        // Handle empty folders
        if contents.isEmpty {
            return createEmptyFolderView()
        }

        // Sort contents: directories first, then files, both alphabetically
        let sortedContents = contents.sorted { item1, item2 in
            let isDir1 = (try? item1.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let isDir2 = (try? item2.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            
            if isDir1 && !isDir2 {
                return true
            } else if !isDir1 && isDir2 {
                return false
            } else {
                return item1.lastPathComponent.localizedCaseInsensitiveCompare(item2.lastPathComponent) == .orderedAscending
            }
        }
        
        // Create file rows
        for (index, fileURL) in sortedContents.enumerated() {
            let fileRow = createFileRow(for: fileURL, at: index)
            listView.addSubview(fileRow)
            
            fileRow.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fileRow.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
                fileRow.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
                fileRow.topAnchor.constraint(equalTo: listView.topAnchor, constant: currentY),
                fileRow.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            currentY += 44
        }
        
        // Set list view height
        listView.translatesAutoresizingMaskIntoConstraints = false
        listView.heightAnchor.constraint(equalToConstant: currentY).isActive = true
        
        // Add summary at the bottom if there are items
        if !sortedContents.isEmpty {
            let summaryView = createSummaryView(itemCount: sortedContents.count)
            listView.addSubview(summaryView)
            
            summaryView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                summaryView.leadingAnchor.constraint(equalTo: listView.leadingAnchor),
                summaryView.trailingAnchor.constraint(equalTo: listView.trailingAnchor),
                summaryView.topAnchor.constraint(equalTo: listView.topAnchor, constant: currentY + 16),
                summaryView.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            // Update list view height to include summary
            listView.heightAnchor.constraint(equalToConstant: currentY + 36).isActive = true
        }
        
        return listView
    }
    
    private func createFileRow(for url: URL, at index: Int) -> NSView {
        let rowView = NSView()
        
        // Alternating background colors
        rowView.wantsLayer = true
        if index % 2 == 0 {
            rowView.layer?.backgroundColor = NSColor.alternatingContentBackgroundColors[0].cgColor
        } else {
            rowView.layer?.backgroundColor = NSColor.alternatingContentBackgroundColors[1].cgColor
        }
        
        // File icon
        let iconView = NSImageView()
        iconView.image = NSWorkspace.shared.icon(forFile: url.path)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // File name
        let nameLabel = NSTextField(labelWithString: url.lastPathComponent)
        nameLabel.font = NSFont.systemFont(ofSize: 13)
        nameLabel.isEditable = false
        nameLabel.isBordered = false
        nameLabel.backgroundColor = NSColor.clear
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // File info (size, date)
        let infoText = getFileInfoText(for: url)
        let infoLabel = NSTextField(labelWithString: infoText)
        infoLabel.font = NSFont.systemFont(ofSize: 11)
        infoLabel.textColor = NSColor.secondaryLabelColor
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rowView.addSubview(iconView)
        rowView.addSubview(nameLabel)
        rowView.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor, constant: -8),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoLabel.leadingAnchor, constant: -8),
            
            infoLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -8),
            infoLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
        
        return rowView
    }
    
    private func createSummaryView(itemCount: Int) -> NSView {
        let summaryView = NSView()
        
        let summaryText = itemCount == 1 ? "1 item" : "\(itemCount) items"
        let summaryLabel = NSTextField(labelWithString: summaryText)
        summaryLabel.font = NSFont.systemFont(ofSize: 11)
        summaryLabel.textColor = NSColor.secondaryLabelColor
        summaryLabel.alignment = .center
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        summaryView.addSubview(summaryLabel)
        
        NSLayoutConstraint.activate([
            summaryLabel.centerXAnchor.constraint(equalTo: summaryView.centerXAnchor),
            summaryLabel.centerYAnchor.constraint(equalTo: summaryView.centerYAnchor)
        ])
        
        return summaryView
    }
    
    private func createErrorView(message: String) -> NSView {
        let errorView = NSView()
        errorView.wantsLayer = true
        errorView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = NSColor.secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        errorView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            errorView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        return errorView
    }
    
    private func createEmptyFolderView() -> NSView {
        let emptyView = NSView()
        emptyView.wantsLayer = true
        emptyView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let label = NSTextField(labelWithString: "This folder is empty")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = NSColor.secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
            emptyView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        return emptyView
    }
    
    private func getFileInfoText(for url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ])
            
            var infoComponents: [String] = []
            
            if let isDirectory = resourceValues.isDirectory, isDirectory {
                infoComponents.append("Folder")
            } else if let fileSize = resourceValues.fileSize {
                infoComponents.append(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
            }
            
            if let modificationDate = resourceValues.contentModificationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                infoComponents.append(formatter.string(from: modificationDate))
            }
            
            return infoComponents.joined(separator: " • ")
        } catch {
            return ""
        }
    }
}
