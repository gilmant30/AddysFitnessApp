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


class UploadWorkoutsViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    var data:Data!
    var manager:AWSUserFileManager!
    var url:URL!
    var selectedCategory:String?
    fileprivate var dateFormatter: DateFormatter!
    var activeField: UITextField?
    var workoutType: String?
    var isEdit: Bool = false
    var editWorkout: WorkoutVids!
    
    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var workoutDescription: UITextView!
    @IBOutlet weak var workoutTitle: UITextField!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var workoutLength: UILabel!
    @IBOutlet weak var armWorkout: UIImageView!
    @IBOutlet weak var legWorkout: UIImageView!
    @IBOutlet weak var totalBodyWorkout: UIImageView!
    @IBOutlet weak var fitTricks: UIImageView!
    @IBOutlet weak var uploadWorkoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if isEdit {
            manager = AWSUserFileManager.defaultUserFileManager()
            self.workoutTitle.isUserInteractionEnabled = false
            uploadWorkoutButton.setTitle("Update", for: UIControlState.normal)
            self.workoutType = editWorkout.workoutType
            self.workoutTitle.text = editWorkout.name
            self.workoutDescription.text = editWorkout.description
            self.workoutLength.text = editWorkout.length
            self.url = editWorkout.imageUrl
            if let type = self.workoutType {
                switch type {
                case "upperBodyWorkout":
                    upperBodySelected()
                case "lowerBodyWorkout":
                    lowerBodySelected()
                case "totalBodyWorkout":
                    totalBodySelected()
                case "fitTricks":
                    fitTricksSelected()
                default:
                    upperBodySelected()
                }
            }
        }
        
        os_log("Entering Upload Workouts View", log: OSLog.default, type: .debug)
        navigationItem.title = "MVPFit"
        self.progressView.isHidden = true
        self.uploadingLabel.isHidden = true
        self.workoutTitle.delegate = self
        self.workoutDescription.delegate = self
        workoutDescription.layer.borderColor = UIColor.lightGray.cgColor
        workoutDescription.layer.borderWidth = 2
        videoPreviewUIImage()
        categorySetup()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dismissKeyboard()
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
                    strongSelf.saveSqlWorkout({(error: NSError?) -> Void in
                        os_log("Inserted into sql", log: OSLog.default, type: .debug)
                        if error != nil {
                            strongSelf.showSimpleAlertWithTitle("Error", message: "Error saving sql data", cancelButtonTitle: "OK")
                        }
                        strongSelf.showSimpleAlertWithTitle("Complete!", message: "Upload Completed Succesfully", cancelButtonTitle: "OK")
                        strongSelf.navigationController?.popViewController(animated: true)
                    })
                }
            })
    }

    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func uploadWorkoutImage(_ localContent: AWSLocalContent) {
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
                    print("uploaded image complete")
                }
        })
    }

    
    func saveSqlWorkout(_ completionHandler: @escaping (_ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        
        let mvpFitObject: MVPFitObjects = MVPFitObjects()
        
        mvpFitObject._createdBy = AWSIdentityManager.default().identityId!
        mvpFitObject._createdDate = result
        mvpFitObject._objectApp = mvpApp
        mvpFitObject._objectName = workoutTitle.text
        mvpFitObject._objectType = workoutObjectType
        mvpFitObject._objectInfo = createWorkoutMap()
        
        objectMapper.save(mvpFitObject, completionHandler: {(error: Error?) -> Void in
            if error != nil {
                completionHandler(error! as NSError)
            } else {
                completionHandler(nil)
            }
        })
        
    }
    
    func createWorkoutMap() -> [String: String] {
        var workoutMap = [String: String]()
        
        workoutMap["workoutName"] = workoutTitle.text
        workoutMap["workoutDescription"] = workoutDescription.text
        workoutMap["videoLength"] = workoutLength.text
        workoutMap["workoutType"] = workoutType
        
        return workoutMap
    }

    
    @IBAction func uploadWorkout(_ sender: Any) {
        if(workoutTitle.hasText) {
            if workoutType != nil {
                if let title: String = workoutTitle.text {
                    if isEdit {
                        self.saveSqlWorkout({(error: NSError?) -> Void in
                            os_log("Inserted into sql", log: OSLog.default, type: .debug)
                            if error != nil {
                                self.showSimpleAlertWithTitle("Error", message: "Error saving sql data", cancelButtonTitle: "OK")
                            }
                            self.editWorkout.description = self.workoutDescription.text
                            self.showSimpleAlertWithTitle("Complete!", message: "Upload Completed Succesfully", cancelButtonTitle: "OK")
                            self.navigationController?.popViewController(animated: true)
                        })
                    } else {
                        let key: String = "\(WorkoutS3DirectoryName)\(title).mp4"
                        let localContent = manager.localContent(with: data, key: key)
                        uploadLocalContent(localContent)
                        
                        if let image = self.previewImage.image {
                            let imageKey: String = "\(WorkoutS3DirectoryName)\(title).jpg"
                            let imageData: Data = UIImageJPEGRepresentation(image, 0.25)!
                            let imageContent = manager.localContent(with: imageData, key: imageKey)
                            uploadWorkoutImage(imageContent)
                        }
                    }
                    //self.uploadWithData(data, forKey: key)
                }
            } else {
                self.showSimpleAlertWithTitle("Error", message: "Select a category type.", cancelButtonTitle: "OK")
            }
        } else {
            self.showSimpleAlertWithTitle("Error", message: "The title name cannot be empty.", cancelButtonTitle: "OK")
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
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        os_log("textFieldDidBeginEditing", log: OSLog.default, type: .debug)
        self.activeField = textField
    }
    
    func adjustingHeight(show:Bool, notification:NSNotification) {
        // 1
        var userInfo = notification.userInfo!
        // 2
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        // 3
        let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        // 4
        let changeInHeight = (keyboardFrame.height + 40) * (show ? 1 : -1)
        //5
        UIView.animate(withDuration: animationDurarion, animations: { () -> Void in
            self.contentViewHeight.constant += changeInHeight
        })
        
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }
    
    
    func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (_) -> Void in
            self.scrollView.contentSize.height = self.contentView.frame.height
        }
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
