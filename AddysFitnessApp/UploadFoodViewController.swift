//
//  UploadFoodViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/11/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

class UploadFoodViewController: UIViewController {
    var data:Data!
    var manager:AWSUserFileManager!
    var foodType: String?
    
    @IBOutlet weak var foodImage: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var foodName: UITextField!
    @IBOutlet weak var foodDescription: UITextField!
    @IBOutlet weak var bfastType: UILabel!
    @IBOutlet weak var lunchType: UILabel!
    @IBOutlet weak var dinnerType: UIStackView!
    @IBOutlet weak var snacksType: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Add Food"
        uploadingLabel.isHidden = true
        progressView.isHidden = true
        
    }
        
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
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
                    strongSelf.insertNoSqlFood({(errors: [NSError]?) -> Void in
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
    
    func insertNoSqlFood(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        os_log("Inserting into sql", log: OSLog.default, type: .debug)
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        
        let dbConsumable: Consumable! = Consumable()
        
        //dbConsumable._createdBy = AWSIdentityManager.default().identityId!
        dbConsumable._consumableType = foodType
        dbConsumable._name = foodName.text
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        //dbConsumable._createdDate = result
        
        group.enter()
        
        objectMapper.save(dbConsumable, completionHandler: {(error: Error?) -> Void in
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

    // MARK: - Action
    
    @IBAction func uploadFood(_ sender: UIButton) {
        if let name = foodName, name.hasText {
            if let description = foodDescription, description.hasText {
                if foodType != nil {
                    let key: String = "\(FoodImagesDirectoryName)\(name)"
                    let localContent = manager.localContent(with: data, key: key)
                    uploadLocalContent(localContent)
                } else {
                    showSimpleAlertWithTitle("Error!", message: "Please select a food category", cancelButtonTitle: "Ok")
                }
            } else {
                showSimpleAlertWithTitle("Error!", message: "Please input a description for the food", cancelButtonTitle: "Ok")
            }
        } else {
            showSimpleAlertWithTitle("Error!", message: "Please input a title for the food", cancelButtonTitle: "Ok")
        }
    }
}
