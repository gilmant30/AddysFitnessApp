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
import AWSDynamoDB
import os.log

import ObjectiveC


class UploadWorkoutsViewController: UIViewController {
    var data:Data!
    var manager:AWSUserFileManager!
    var url:URL!
    var selectedCategory:String?
    fileprivate var dateFormatter: DateFormatter!
    
    @IBOutlet weak var workoutTitle: UITextField!
    @IBOutlet weak var workoutDescription: UITextView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var armVideo: UILabel!
    @IBOutlet weak var legVideo: UILabel!
    @IBOutlet weak var cardioVideo: UILabel!
    @IBOutlet weak var abVideo: UILabel!
    @IBOutlet weak var workoutLength: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        os_log("Entering Upload Workouts View", log: OSLog.default, type: .debug)
        navigationItem.title = "MVPFit"
        self.progressView.isHidden = true
        self.uploadingLabel.isHidden = true
        setIcons()
        videoPreviewUIImage()
    }
    
    fileprivate func uploadLocalContent(_ localContent: AWSLocalContent) {
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                // Update the upload UI if it is a new upload and the table is not yet updated
                strongSelf.progressView.isHidden = false
                strongSelf.uploadingLabel.isHidden = false
                strongSelf.progressView.progress = Float(content.progress.fractionCompleted)
            }
            }, completionHandler: {[weak self](content: AWSLocalContent?, error: Error?) -> Void in
                guard let strongSelf = self else { return }
                os_log("Downloading to S3 complete", log: OSLog.default, type: .debug)
                if let error = error {
                    os_log(error as! StaticString, log: OSLog.default, type: .debug)
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.insertNoSqlWorkout({(errors: [NSError]?) -> Void in
                        os_log("Inserted into sql", log: OSLog.default, type: .debug)
                        if errors != nil {
                            strongSelf.showSimpleAlertWithTitle("Error", message: "Error saving sql data", cancelButtonTitle: "OK")
                        }
                        strongSelf.showSimpleAlertWithTitle("Complete!", message: "Upload Completed Succesfully", cancelButtonTitle: "OK")
                        strongSelf.navigationController?.popViewController(animated: true)
                    })
                }
            })
    }
    
    /*fileprivate func uploadWithData(_ data: Data, forKey key: String) {
        let localContent = manager.localContent(with: data, key: key)
        uploadLocalContent(localContent)
    }*/

    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func uploadWorkout(_ sender: Any) {
        if selectedCategory != nil {
            if(workoutTitle.hasText) {
                if let title: String = workoutTitle.text {
                    let key: String = "\(WorkoutVideosDirectoryName)\(title).mp4"
                    let localContent = manager.localContent(with: data, key: key)
                    uploadLocalContent(localContent)
                    //self.uploadWithData(data, forKey: key)
                }
            } else {
                self.showSimpleAlertWithTitle("Error", message: "The title name cannot be empty.", cancelButtonTitle: "OK")
            }
        } else {
            self.showSimpleAlertWithTitle("Error", message: "You must specify a workout category.", cancelButtonTitle: "OK")
        }
    }
    
    //set preview UIImage for videos
    func videoPreviewUIImage() {
            guard let url = self.url else {
                self.showSimpleAlertWithTitle("Error", message: "Error getting video.", cancelButtonTitle: "OK")
                return
            }
            let asset = AVURLAsset(url: url as URL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
            
            do {
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                let time = CMTimeGetSeconds(asset.duration)
                let minutes = Int(time) / 60 % 60
                let seconds = Int(time) % 60
                self.workoutLength.text = String(format:"%02i:%02i", minutes, seconds)
                self.previewImage.image = UIImage(cgImage: imageRef)
            }
            catch let error as NSError
            {
                print("Image generation failed with error \(error)")
                return
            }
    }
    
    func insertNoSqlWorkout(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        os_log("Inserting into sql", log: OSLog.default, type: .debug)
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        
        let dbWorkout: Workouts! = Workouts()
        
        dbWorkout._createdBy = AWSIdentityManager.default().identityId!
        dbWorkout._videoLength = workoutLength.text
        dbWorkout._workoutName = workoutTitle.text
        dbWorkout._workoutType = selectedCategory
        dbWorkout._videoDescription = workoutDescription.text
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        dbWorkout._createdDate = result
    
        group.enter()
        
        objectMapper.save(dbWorkout, completionHandler: {(error: Error?) -> Void in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    errors.append(error)
                })
            }
            group.leave()
        })
        
        group.notify(queue: DispatchQueue.main, execute: {
            if errors.count > 0 {
                completionHandler(errors)
            }
            else {
                completionHandler(nil)
            }
        })
    }
    
    func setIcons() {
        // create tapGestureRecognizer for images
        let tapArmWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleArmWorkouts))
        let tapLegWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleLegWorkouts))
        let tapCardioBodyWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleCardioWorkouts))
        let tapAbsWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleAbsWorkouts))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapArmWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapLegWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapCardioBodyWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapAbsWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
        armVideo.isUserInteractionEnabled = true
        armVideo.addGestureRecognizer(tapArmWorkoutsGestureRecognizer)
        legVideo.isUserInteractionEnabled = true
        legVideo.addGestureRecognizer(tapLegWorkoutsGestureRecognizer)
        cardioVideo.isUserInteractionEnabled = true
        cardioVideo.addGestureRecognizer(tapCardioBodyWorkoutsGestureRecognizer)
        abVideo.isUserInteractionEnabled = true
        abVideo.addGestureRecognizer(tapAbsWorkoutsGestureRecognizer)
    }
    
    func handleArmWorkouts() {
        armVideo.backgroundColor = UIColor.lightGray
        legVideo.backgroundColor = UIColor.white
        cardioVideo.backgroundColor = UIColor.white
        abVideo.backgroundColor = UIColor.white
        selectedCategory = "armVideos"
    }
    
    func handleLegWorkouts() {
        armVideo.backgroundColor = UIColor.white
        legVideo.backgroundColor = UIColor.lightGray
        cardioVideo.backgroundColor = UIColor.white
        abVideo.backgroundColor = UIColor.white
        selectedCategory = "legVideos"
    }
    
    func handleAbsWorkouts() {
        armVideo.backgroundColor = UIColor.white
        legVideo.backgroundColor = UIColor.white
        cardioVideo.backgroundColor = UIColor.white
        abVideo.backgroundColor = UIColor.lightGray
        selectedCategory = "abVideos"
    }
    
    func handleCardioWorkouts() {
        armVideo.backgroundColor = UIColor.white
        legVideo.backgroundColor = UIColor.white
        cardioVideo.backgroundColor = UIColor.lightGray
        abVideo.backgroundColor = UIColor.white
        selectedCategory = "cardioVideos"
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
