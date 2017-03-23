//
//  UploadWorkoutsViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/15/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import CoreMedia
import MediaPlayer
import AVFoundation
import MobileCoreServices
import AWSMobileHubHelper
import os.log

import ObjectiveC


class UploadWorkoutsViewController: UIViewController {
    
    //MARK: Properties
    var videoData: Data!
    fileprivate var manager: AWSUserFileManager!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!

    var prefix: String!
    
    @IBOutlet weak var videoToUpload: UIImageView!
    @IBOutlet weak var workoutTitle: UITextField!
    @IBOutlet weak var workoutDescription: UITextView!
    @IBOutlet weak var videoLength: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var uploadingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = AWSUserFileManager.defaultUserFileManager()
        
        navigationItem.title = "New"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showVideoPicker(_:)))
        
        // Sets up the date formatter.
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        progressBar.isHidden = true
        uploadingLabel.isHidden = true
        
        self.prefix = ""
    }
    
    // MARK: Content uploads
    
    func showVideoPicker(_ sender: AnyObject) {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    private func uploadWithData(_ key: String) {
        if let data = self.videoData {
            let localContent: AWSLocalContent = manager.localContent(with: data, key: key)
            localContent.uploadWithPin(
                onCompletion: false,
                progressBlock: {[weak self](content: AWSLocalContent, progress: Progress) -> Void in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        if content.status == .running {
                            strongSelf.progressBar.progress = Float(content.progress.fractionCompleted)
                            strongSelf.progressBar.isHidden = false
                            strongSelf.uploadingLabel.isHidden = false
                        } else {
                            strongSelf.progressBar.isHidden = true
                            strongSelf.uploadingLabel.isHidden = true
                        }
                    }
                },
                completionHandler: {[weak self](content: AWSLocalContent?, error: Error?) -> Void in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        print("Failed to upload an object. \(error)")
                    } else {
                        strongSelf.uploadingLabel.text = "Upload Complete!"
                        strongSelf.progressBar.isHidden = true
                    }
            })
        } else {
            self.showSimpleAlertWithTitle("Error", message: "The workout video has an error", cancelButtonTitle: "OK")
        }
    }
    
    // MARK: Actions
    
    @IBAction func uploadVideo(_ sender: Any) {
        let title = workoutTitle.text!
        if title.characters.count == 0 {
            self.showSimpleAlertWithTitle("Error", message: "The Workout title cannot be empty.", cancelButtonTitle: "OK")
        } else {
            let key: String = "public/\(title)"
            uploadWithData(key)
        }
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
                
            }
        }) {[weak self] (content: AWSLocalContent?, error: Error?) in
            guard let strongSelf = self else { return }
           
            if let error = error {
                print("Failed to upload an object. \(error)")
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
            } else {
            }
        }
    }
    
    fileprivate func uploadWithData(_ data: Data, forKey key: String) {
        let localContent = manager.localContent(with: data, key: key)
        uploadLocalContent(localContent)
    }

}

// MARK:- UIImagePickerControllerDelegate

extension UploadWorkoutsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        
        // Handle Video Uploads
        if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            askForFilename(try! Data(contentsOf: videoURL))
            // let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            // self.videoData = try! Data(contentsOf: videoURL)
            // remove for testing purposes
            // videoPreviewUiimage(url: videoURL)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //set preview UIImage for videos
    func videoPreviewUiimage(url: URL) {
        let asset = AVURLAsset(url: url as URL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
            
        let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
        let duration = CMTimeGetSeconds(asset.duration)
        videoLength.text = "\(duration)"
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            
            videoToUpload.image = UIImage(cgImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return
        }
        return
    }
    
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
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
