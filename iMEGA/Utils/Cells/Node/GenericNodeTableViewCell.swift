
final class GenericNodeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailPlayImageView: UIImageView!
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var labelImageView: UIImageView!
    @IBOutlet weak var favouriteView: UIView!
    @IBOutlet weak var favouriteImageView: UIImageView!
    @IBOutlet weak var linkView: UIView!
    @IBOutlet weak var linkImageView: UIImageView!
    
    @IBOutlet weak var versionedImageView: UIImageView!
    @IBOutlet weak var secondaryLabel: UILabel!
    @IBOutlet weak var secondaryRightLabel: UILabel!
    @IBOutlet weak var downloadedImageView: UIImageView!
    
    @IBOutlet weak var moreButton: UIButton!
    
    var viewModel: NodeCellViewModel! {
        didSet {
            viewModel?.invokeCommand = { [weak self] command in
                DispatchQueue.main.async { self?.executeCommand(command) }
            }
        }
    }
    
    func executeCommand(_ command: NodeCellViewModel.Command) {
        switch command {
        case .config(let nodeModel):
            config(nodeModel)
        
        case .hideVideoIndicator(let isHidden):
            thumbnailPlayImageView.isHidden = isHidden
        
        case .hideLabel(let isHidden):
            labelView.isHidden = isHidden
            
        case .setLabel(let labelImageName):
            let labelImage = UIImage(named: labelImageName)
            labelImageView.image = labelImage
            
        case .setThumbnail(let thumbnailFilePath):
            let thumbnailImage = UIImage(contentsOfFile: thumbnailFilePath)!
            thumbnailImageView.image = thumbnailImage
            
        case .setIcon(let iconName):
            let iconImage = UIImage(named: iconName)!
            thumbnailImageView.image = iconImage
            
        case .setSecondaryLabel(let numberOfFilesAndFolders):
            secondaryLabel.text = numberOfFilesAndFolders
            
        case .setVersions(let hasVersions):
            versionedImageView.isHidden = !hasVersions
        
        case .setBeingDownloaded(let isBeingDownloaded):
            if isBeingDownloaded {
                secondaryLabel.text = NSLocalizedString("queued", comment: "Text shown when one file has been selected to be downloaded but it's on the queue to be downloaded, it's pending for download")
                moreButton.isHidden = true
            } else {
                viewModel.dispatch(.isDownloaded)
                moreButton.isHidden = false
            }
            
        case .setDownloaded(let isDownloaded):
            downloadedImageView.isHidden = !isDownloaded
        }
    }
    
    @IBAction func moreButtonTouchUpInside(_ sender: UIButton) {
        viewModel?.dispatch(.moreTouchUpInside(sender))
    }
    
    // MARK: - Private
    
    private func config(_ nodeModel: NodeModel) {
        viewModel.dispatch(.isBeingDownloaded)
        
        favouriteView.isHidden = !nodeModel.isFavourite
        
        viewModel.dispatch(.manageLabel)
        
        linkView.isHidden = !nodeModel.isExported

        viewModel.dispatch(.manageThumbnail)
        
        if !nodeModel.name.mnz_isVideoPathExtension {
            thumbnailPlayImageView.isHidden = true
        }
        
        if nodeModel.isTakenDown {
            mainLabel.attributedText = attributedTakenDownNameWithHeight(nodeModel: nodeModel, height: mainLabel.font.capHeight)
            mainLabel.textColor = .mnz_red(for: traitCollection)
        } else {
            mainLabel.text = nodeModel.name
            mainLabel.textColor = .mnz_label()
            secondaryLabel.textColor = .mnz_subtitles(for: traitCollection)
        }
        
        if nodeModel.isFile {
            secondaryLabel.text = sizeAndModicationDate(nodeModel)
            viewModel.dispatch(.hasVersions)
        } else if nodeModel.isFolder {
            viewModel.dispatch(.getFilesAndFolders)
            versionedImageView.isHidden = true
        }
        
        thumbnailImageView.accessibilityIgnoresInvertColors = true
        thumbnailPlayImageView.accessibilityIgnoresInvertColors = true
    }
    
    private func attributedTakenDownNameWithHeight(nodeModel: NodeModelProtocol, height: CGFloat) -> NSAttributedString {
        let name = nodeModel.name + " "
        let nameMutableAttributedString = NSMutableAttributedString(string: name)
        let takendownImageName = "isTakendown"
        
        let takedownImageAttributedString = NSAttributedString.mnz_attributedString(fromImageNamed: takendownImageName, fontCapHeight: height)!
        nameMutableAttributedString.append(takedownImageAttributedString)
        
        return nameMutableAttributedString
    }
    
    private func sizeAndModicationDate(_ nodeModel: NodeModelProtocol) -> String {
        let modificationTime = nodeModel.modificationTime as NSDate
        let modificationTimeString: String = modificationTime.mnz_formattedDateMediumTimeShortStyle()
        
        return sizeForFile(nodeModel) + " • " + modificationTimeString
    }
    
    private func sizeForFile(_ nodeModel: NodeModelProtocol) -> String {
        return Helper.memoryStyleString(fromByteCount: Int64(nodeModel.size));
    }
}
