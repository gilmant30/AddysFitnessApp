//
//  WorkoutsViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/12/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import MediaPlayer
import AVFoundation
import MobileCoreServices
import AWSMobileHubHelper
import os.log

import ObjectiveC


//let UserFilesPublicDirectoryName = "public"
//let UserFilesPrivateDirectoryName = "private"
private var cellAssociationKey: UInt8 = 0

class WorkoutsViewController: UITableViewController {
    
    var prefix: String!
    
    @IBOutlet weak var pathLabel: UILabel!
    fileprivate var manager: AWSUserFileManager!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var marker: String?
    fileprivate var didLoadAllContents: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.tableView.delegate = self
        manager = AWSUserFileManager.defaultUserFileManager()
        os_log("Entering Workouts storyboard", log: OSLog.default, type: .debug)
        
        // Sets up the UIs.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WorkoutsViewController.showContentManagerActionOptions(_:)))
        navigationItem.title = "Get Fit with Addyson"
        
        // Sets up the date formatter.
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        didLoadAllContents = false
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = ""
        }
        
        //refreshContents()
        //updateUserInterface()
        //loadMoreContents()
    }
    
    fileprivate func updateUserInterface() {
       DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func showContentManagerActionOptions(_ sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadObjectAction = UIAlertAction(title: "Upload New Workout", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.sendToUploadWorkouts()
        })
        alertController.addAction(uploadObjectAction)
        let refreshAction = UIAlertAction(title: "Refresh", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.refreshContents()
        })
        alertController.addAction(refreshAction)
        let downloadObjectsAction = UIAlertAction(title: "Download Recent", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.downloadObjectsToFillCache()
        })
        alertController.addAction(downloadObjectsAction)
        let removeAllObjectsAction = UIAlertAction(title: "Clear Cache", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.manager.clearCache()
            //self.updateUserInterface()
        })
        alertController.addAction(removeAllObjectsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func refreshContents() {
        os_log("refreshContents - Started", log: OSLog.default, type: .debug)
        marker = nil
        loadMoreContents()
    }
    
    fileprivate func loadMoreContents() {
        print("loadMoreContents - started")
        manager.listAvailableContents(withPrefix: prefix, marker: marker) {
            [weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents, contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllContents = false
                } else {
                    strongSelf.didLoadAllContents = true
                }
                strongSelf.marker = nextMarker
            }
            strongSelf.updateUserInterface()
        }
    }
    
    fileprivate func downloadObjectsToFillCache() {
        manager.listRecentContents(withPrefix: prefix) {[weak self] (contents: [AWSContent]?, error: Error?) in
            guard let strongSelf = self else { return }
            
            contents?.forEach({ (content: AWSContent) in
                if !content.isCached && !content.isDirectory {
                    strongSelf.downloadContent(content, pinOnCompletion: false)
                }
            })
        }
    }
    
    // MARK:- Content user action methods
    
    fileprivate func showActionOptionsForContent(_ rect: CGRect, content: AWSContent) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if alertController.popoverPresentationController != nil {
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRect(x: rect.midX, y: rect.midY, width: 1.0, height: 1.0)
        }
        if content.isCached {
            let openAction = UIAlertAction(title: "Open", style: .default, handler: {(action: UIAlertAction) -> Void in
                DispatchQueue.main.async {
                    self.openContent(content)
                }
            })
            alertController.addAction(openAction)
        }
        
        // Allow opening of remote files natively or in browser based on their type.
        let openRemoteAction = UIAlertAction(title: "Open Remote", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.openRemoteContent(content)
            
        })
        alertController.addAction(openRemoteAction)
        
        // If the content hasn't been downloaded, and it's larger than the limit of the cache,
        // we don't allow downloading the content.
        if content.knownRemoteByteCount + 4 * 1024 < self.manager.maxCacheSize {
            // 4 KB is for local metadata.
            var title = "Download"
            
            if let downloadedDate = content.downloadedDate, let knownRemoteLastModifiedDate = content.knownRemoteLastModifiedDate, knownRemoteLastModifiedDate.compare(downloadedDate) == .orderedDescending {
                title = "Download Latest Version"
            }
            let downloadAction = UIAlertAction(title: title, style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.downloadContent(content, pinOnCompletion: false)
            })
            alertController.addAction(downloadAction)
        }
        let downloadAndPinAction = UIAlertAction(title: "Download & Pin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.downloadContent(content, pinOnCompletion: true)
        })
        alertController.addAction(downloadAndPinAction)
        if content.isCached {
            if content.isPinned {
                let unpinAction = UIAlertAction(title: "Unpin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.unPin()
                    self.updateUserInterface()
                })
                alertController.addAction(unpinAction)
            } else {
                let pinAction = UIAlertAction(title: "Pin", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.pin()
                    self.updateUserInterface()
                })
                alertController.addAction(pinAction)
            }
            let removeAction = UIAlertAction(title: "Delete Local Copy", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                content.removeLocal()
                self.updateUserInterface()
            })
            alertController.addAction(removeAction)
        }
        
        let removeFromRemoteAction = UIAlertAction(title: "Delete Remote File", style: .destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.confirmForRemovingContent(content)
        })
        
        alertController.addAction(removeFromRemoteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func downloadContent(_ content: AWSContent, pinOnCompletion: Bool) {
        content.download(with: .ifNewerExists, pinOnCompletion: pinOnCompletion, progressBlock: {[weak self] (content: AWSContent, progress: Progress) in
            guard let strongSelf = self else { return }
            if strongSelf.contents!.contains( where: {$0 == content} ) {
                let row = strongSelf.contents!.index(where: {$0  == content})!
                let indexPath = IndexPath(row: row, section: 1)
                strongSelf.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }) {[weak self] (content: AWSContent?, data: Data?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                print("Failed to download a content from a server. \(error)")
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to download a content from a server.", cancelButtonTitle: "OK")
            }
        }
    }
    
    fileprivate func openContent(_ content: AWSContent) {
        if content.isAudioVideo() { // Video and sound files
            let directories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [AnyObject]
            let cacheDirectoryPath = directories.first as! String
            
            let movieURL: URL = URL(fileURLWithPath: "\(cacheDirectoryPath)/\(content.key.getLastPathComponent())")
            
            try? content.cachedData.write(to: movieURL, options: [.atomic])
            
            let player = AVPlayer(url: movieURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
            
            /*
            let controller: MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: movieURL)
            controller.moviePlayer.prepareToPlay()
            controller.moviePlayer.play()
            presentMoviePlayerViewControllerAnimated(controller)
             */
        } else {
            showSimpleAlertWithTitle("Sorry!", message: "We can only open video files.", cancelButtonTitle: "OK")
        }
    }
    
    fileprivate func openRemoteContent(_ content: AWSContent) {
        content.getRemoteFileURL {
            [weak self] (url: URL?, error: Error?) in
            guard let strongSelf = self else { return }
            guard let url = url else {
                print("Error getting URL for file. \(error)")
                return
            }
            if content.isAudioVideo() { // Open Audio and Video files natively in app.
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                strongSelf.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
                /*
                let controller: MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: url)
                controller.moviePlayer.prepareToPlay()
                controller.moviePlayer.play()
                strongSelf.presentMoviePlayerViewControllerAnimated(controller)
                */
            }
        }
    }
    
    fileprivate func confirmForRemovingContent(_ content: AWSContent) {
        let alertController = UIAlertController(title: "Confirm", message: "Do you want to delete the content from the server? This cannot be undone.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Yes", style: .default) {[weak self] (action: UIAlertAction) in
            guard let strongSelf = self else { return }
            strongSelf.removeContent(content)
        }
        alertController.addAction(okayAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func removeContent(_ content: AWSContent) {
        content.removeRemoteContent {[weak self] (content: AWSContent?, error: Error?) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to delete an object from the remote server. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to delete an object from the remote server.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.showSimpleAlertWithTitle("Object Deleted", message: "The object has been deleted successfully.", cancelButtonTitle: "OK")
                    strongSelf.refreshContents()
                }
            }
        }
    }
    
    // MARK:- Content uploads
    
    fileprivate func showImagePicker() {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String, kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    fileprivate func sendToUploadWorkouts() {
        performSegue(withIdentifier: "ShowUploadWorkouts", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        os_log("Sending to UploadWorkouts Page", log: OSLog.default, type: .debug)
    }
    
    fileprivate func askForFilename(_ data: Data) {
        let alertController = UIAlertController(title: "File Name", message: "Please specify the file name.", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        let doneAction = UIAlertAction(title: "Done", style: .default) {[unowned self] (action: UIAlertAction) in
            let specifiedKey = alertController.textFields!.first!.text!
            if specifiedKey.characters.count == 0 {
                self.showSimpleAlertWithTitle("Error", message: "The file name cannot be empty.", cancelButtonTitle: "OK")
                return
            } else {
                let key: String = "\(self.prefix!)\(specifiedKey)"
                self.uploadWithData(data, forKey: key)
            }
        }
        alertController.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func uploadLocalContent(_ localContent: AWSLocalContent) {
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                // Update the upload UI if it is a new upload and the table is not yet updated
                if(strongSelf.tableView.numberOfRows(inSection: 0) == 0 || strongSelf.tableView.numberOfRows(inSection: 0) < strongSelf.manager.uploadingContents.count) {
                    strongSelf.updateUploadUI()
                } else {
                    for uploadContent in strongSelf.manager.uploadingContents {
                        if uploadContent.key == content.key {
                            let index = strongSelf.manager.uploadingContents.index(of: uploadContent)!
                            let indexPath = IndexPath(row: index, section: 0)
                            strongSelf.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                }
            }
        }) {[weak self] (content: AWSLocalContent?, error: Error?) in
            guard let strongSelf = self else { return }
            strongSelf.updateUploadUI()
            if let error = error {
                print("Failed to upload an object. \(error)")
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
            } else {
                strongSelf.refreshContents()
            }
        }
        updateUploadUI()
    }
    
    fileprivate func uploadWithData(_ data: Data, forKey key: String) {
        let localContent = manager.localContent(with: data, key: key)
        uploadLocalContent(localContent)
    }
    
    fileprivate func createFolderForKey(_ key: String) {
        let localContent = manager.localContent(with: nil, key: key)
        uploadLocalContent(localContent)
    }
    
    fileprivate func updateUploadUI() {
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contents = self.contents {
            return contents.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WorkoutVideoCell = tableView.dequeueReusableCell(withIdentifier: "WorkoutsViewCell", for: indexPath) as! WorkoutVideoCell
        
        let content: AWSContent = contents![indexPath.row]
        cell.prefix = prefix
        cell.content = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let contents = self.contents, indexPath.row == contents.count - 1, !didLoadAllContents {
            loadMoreContents()
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Process only if it is a listed file. Ignore actions for files that are uploading
        let content = contents![indexPath.row]
        if content.isDirectory {
            let storyboard: UIStoryboard = UIStoryboard(name: "Workouts", bundle: nil)
            let viewController: WorkoutsViewController = storyboard.instantiateViewController(withIdentifier: "Workouts") as! WorkoutsViewController
            viewController.prefix = content.key
            navigationController?.pushViewController(viewController, animated: true)
        } else {
            let rowRect = tableView.rectForRow(at: indexPath);
            showActionOptionsForContent(rowRect, content: content)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 125.0;//Choose your custom row height
    }
}

// MARK:- UIImagePickerControllerDelegate

extension WorkoutsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString

        // Handle Video Uploads
        if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            askForFilename(try! Data(contentsOf: videoURL))
        }
    }
}

class WorkoutVideoCell: UITableViewCell {
    
    @IBOutlet weak var workoutDescription: UILabel!
    @IBOutlet weak var workoutTitle: UILabel!
    @IBOutlet weak var workoutVideoImage: UIImageView!
    // @IBOutlet weak var downloadedImageView: UIImageView!
    // @IBOutlet weak var progressView: UIProgressView!
    
    var prefix: String?
    
    var content: AWSContent! {
        didSet {
            var displayFilename: String = self.content.key
            if let prefix = self.prefix {
                if displayFilename.characters.count > prefix.characters.count {
                    displayFilename = displayFilename.substring(from: prefix.endIndex)
                }
            }
            workoutTitle.text = displayFilename
            
            //display preview image for workout list
            if(content.isAudioVideo()) {
                videoPreviewUiimage(vidImage: workoutVideoImage)
            } else {
                // workoutVideoImage.image = nil
            }
            // downloadedImageView.isHidden = !content.isCached
            var contentByteCount: UInt = content.fileSize
            if contentByteCount == 0 {
                contentByteCount = content.knownRemoteByteCount
            }
            
            if content.isDirectory {
                workoutDescription.text = "This is a folder"
                accessoryType = .disclosureIndicator
            } else {
                workoutDescription.text = contentByteCount.aws_stringFromByteCount()
                accessoryType = .none
            }
            
            if let downloadedDate = content.downloadedDate, let knownRemoteLastModifiedDate = content.knownRemoteLastModifiedDate, knownRemoteLastModifiedDate.compare(downloadedDate) == .orderedDescending {
                workoutDescription.text = "\(workoutDescription.text!) - New Version Available"
                workoutDescription.textColor = UIColor.blue
            } else {
                workoutDescription.textColor = UIColor.black
            }
        }
    }
    
    //set preview UIImage for videos
    func videoPreviewUiimage(vidImage: UIImageView) {
        content.getRemoteFileURL {
            [weak self] (url: URL?, error: Error?) in
            guard self != nil else { return }
            guard let url = url else {
                print("Error getting URL for file. \(error)")
                return
            }
            let asset = AVURLAsset(url: url as URL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
        
            let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
        
            do {
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                
                vidImage.image = UIImage(cgImage: imageRef)
            }
            catch let error as NSError
            {
                print("Image generation failed with error \(error)")
                return
            }
            return
        }
    }
}


// MARK: - Utility

extension WorkoutsViewController {
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AWSContent {
    fileprivate func isAudioVideo() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".mov")
            || lowerCaseKey.hasSuffix(".mp4")
            || lowerCaseKey.hasSuffix(".mpv")
            || lowerCaseKey.hasSuffix(".3gp")
            || lowerCaseKey.hasSuffix(".mpeg")
            || lowerCaseKey.hasSuffix(".aac")
            || lowerCaseKey.hasSuffix(".mp3")
    }
    
    fileprivate func isImage() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".jpg")
            || lowerCaseKey.hasSuffix(".png")
            || lowerCaseKey.hasSuffix(".jpeg")
    }
}

extension UInt {
    fileprivate func aws_stringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension String {
    fileprivate func getLastPathComponent() -> String {
        let nsstringValue: NSString = self as NSString
        return nsstringValue.lastPathComponent
    }
}
