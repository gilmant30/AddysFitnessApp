//
//  RecipeDetailViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/29/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

extension RecipeDetailViewController {
    
    func insertRecipeDetails(_ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        
        
        let insertRecipe: Food! = Food()
        
        insertRecipe._foodName = recipe.name
        insertRecipe._type = "recipe"
        insertRecipe._category = recipe.category
        insertRecipe._createdBy = AWSIdentityManager.default().identityId!
        insertRecipe._createdDate = result
        insertRecipe._description = recipe.description
        insertRecipe._ingredients = convertIngredientsToMap()
        insertRecipe._steps = convertArrayToSet()
        
        
        group.enter()
        
        
        objectMapper.save(insertRecipe, completionHandler: {(error: Error?) -> Void in
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
    
    func uploadLocalContent(_ localContent: AWSLocalContent) {
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                // Update the upload UI if it is a new upload and the table is not yet updated
                strongSelf.progressView.isHidden = false
                strongSelf.uploadLabel.isHidden = false
                strongSelf.progressView.progress = Float(content.progress.fractionCompleted)
            }
            }, completionHandler: {[weak self](content: AWSLocalContent?, error: Error?) -> Void in
                guard let strongSelf = self else { return }
                os_log("Downloading to S3 complete", log: OSLog.default, type: .debug)
                if let error = error {
                    os_log(error as! StaticString, log: OSLog.default, type: .debug)
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.insertRecipeDetails({(errors: [NSError]?) -> Void in
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
    
    func convertIngredientsToMap() -> [String:String] {
        var dictionary: [String: String] = [:]
        for value in recipe.ingredients {
            dictionary[value.ingredientName!] = value.amount
        }
        
        return dictionary
    }
    
    func convertArrayToSet() -> Set<String> {
        var set: Set<String> = Set()
        for value in recipe.steps {
            set.insert(value)
        }
        return set
    }

    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
}
