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
        
        
        let insertRecipe: MVPFitObjects! = MVPFitObjects()
        
        insertRecipe._objectApp = mvpApp
        insertRecipe._objectName = recipe.name
        insertRecipe._objectType = recipeObjectType
        insertRecipe._createdBy = AWSIdentityManager.default().identityId!
        insertRecipe._createdDate = result
        insertRecipe._objectInfo = createRecipeMap()
        
        
        
        
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
    
    func createRecipeMap() -> [String: Any] {
        var recipeMap = [String: Any]()
        
        recipeMap["description"] = recipe.description
        recipeMap["ingredients"] = convertIngredientsToMap()
        recipeMap["listSteps"] = recipe.steps
        recipeMap["foodName"] = recipe.name
        recipeMap["category"] = recipe.category
        
        return recipeMap
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
                        strongSelf.performSegue(withIdentifier: "unwindFromDetailToUpload", sender: self)
                    })
                }
        })
    }
    
    func uploadImageContent(_ localContent: AWSLocalContent) {
        localContent.uploadWithPin(onCompletion: false, progressBlock: {[weak self] (content: AWSLocalContent, progress: Progress) in
            guard let strongSelf = self else { return }
            }, completionHandler: {[weak self](content: AWSLocalContent?, error: Error?) -> Void in
                guard let strongSelf = self else { return }
                os_log("Downloading to S3 complete", log: OSLog.default, type: .debug)
                if let error = error {
                    os_log(error as! StaticString, log: OSLog.default, type: .debug)
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    print("Done")
                }
        })
    }
    
    func updateLocalContent() {
        self.insertRecipeDetails({(errors: [NSError]?) -> Void in
            os_log("Inserted into sql", log: OSLog.default, type: .debug)
            if errors != nil {
                self.showSimpleAlertWithTitle("Error", message: "Error saving sql data", cancelButtonTitle: "OK")
            }
            self.performSegue(withIdentifier: "unwindFromDetailToUpload", sender: self)
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
    
    func editRecipe(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Food", bundle: nil)
        let uploadFoodViewController = storyboard.instantiateViewController(withIdentifier: "UploadFood") as! UploadFoodViewController
        uploadFoodViewController.image = recipe.image
        uploadFoodViewController.isVideo = recipe.isVideo
        uploadFoodViewController.manager = self.manager
        uploadFoodViewController.newRecipe = recipe
        uploadFoodViewController.isEdit = true
        self.navigationController!.pushViewController(uploadFoodViewController, animated: true)
    }
    
    func holdDown(_ button: UIButton) {
        button.backgroundColor = UIColor.blue
        button.setTitleColor(UIColor.white, for: .normal)
    }
    
    func animateButton() {
        let animatedLike = UIImageView()
        animatedLike.frame = likeView.frame
        if recipe.liked {
            animatedLike.image = UIImage(named: "like")
        } else {
            animatedLike.image = UIImage(named: "liked")
        }
        self.view.addSubview(animatedLike)
        self.view.bringSubview(toFront: animatedLike)
        UIView.animate(withDuration: 0.5, animations: {
            if self.recipe.liked {
                self.likeButton.image = UIImage(named: "like")
            } else {
                self.likeButton.image = UIImage(named: "liked")
            }
        })
        animatedLike.fadeOutLikeButton(completion: {_ in
            animatedLike.removeFromSuperview()
        })
        
        
    }
    
    func likeRecipe() {
        animateButton()
        
         let myLike: MyLikes! = MyLikes()
         myLike._userId = AWSIdentityManager.default().identityId!
         myLike._name = recipe.name
         if let imgUrl = recipe.imageUrl {
            myLike._imageUrl = "\(imgUrl)"
         }
         myLike._type = "recipe"
         
         let date = Date()
         let formatter = DateFormatter()
         formatter.dateFormat = "MM.dd.yyyy"
         let result = formatter.string(from: date)
         myLike._createdDate = result
         if recipe.liked {
             DynamoDbMyLikes.shared.removeMyLike(myLike){(errors: [NSError]?) -> Void in
                 os_log("removed from sql", log: OSLog.default, type: .debug)
                 if errors != nil {
                    print("Error")
                 } else {
                    if let index = myLikes.index(where: {$0.title == myLike._name}) {
                        myLikes.remove(at: index)
                    }
                 }
             }
         } else {
             DynamoDbMyLikes.shared.insertMyLike(myLike){(errors: [NSError]?) -> Void in
                 os_log("Inserted into sql", log: OSLog.default, type: .debug)
                 if errors != nil {
                    print("Error")
                 } else {
                    let like = DynamoDbMyLikes.shared.formatOneLike(myLike)
                    like.img = self.recipe.image
                    myLikes.append(like)
                 }
             }
         }
        recipe.liked = !recipe.liked
        
        print("MyLikes saved succesfully")
    }
    
    func setupLikeButton() {
        let tapLikeButton = UITapGestureRecognizer(target: self, action: #selector(self.likeRecipe))
        tapLikeButton.numberOfTapsRequired = 1
        likeButton.isUserInteractionEnabled = true
        likeButton.addGestureRecognizer(tapLikeButton)
        likeView.layer.cornerRadius = 10
        if recipe.liked {
            DispatchQueue.main.async {
                self.likeButton.image = UIImage(named: "liked")
            }
        }
    }
    
    func pinBackground(_ view: UIView, to stackView: UIStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
    
    
}
