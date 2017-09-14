//
//  RecipeDetailViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/28/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

let RecipeImagesDirectoryName = "public/recipeImages/"
class RecipeDetailViewController: UIViewController {
    var manager: AWSUserFileManager!
    var recipe: Recipe!
    var preview: Bool = false
    var isVideo: Bool = false
    var isEdit: Bool = false
    var data:Data!
    var image:UIImage?
    
    @IBOutlet weak var stepStackView: UIStackView!
    @IBOutlet weak var ingredientStackView: UIStackView!
    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var recipeTitle: UILabel!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ingredientStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var stepStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var stepLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var uploadRecipe: UIButton!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var recipeDescription: UILabel!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playButtonOverlay: UIImageView!
    @IBOutlet weak var recipeVideo: UIView!
    var player: AVPlayer!
    var avpController: AVPlayerViewController!
    let screenSize = UIScreen.main.bounds
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    fileprivate var identityManager: AWSIdentityManager!
    
    var stepsBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
        view.layer.cornerRadius = 10.0
        return view
    }()
    
    var ingredientsBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
        view.layer.cornerRadius = 10.0
        return view
    }()
    
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var likeView: UIView!
    override func viewDidLoad() {
        identityManager = AWSIdentityManager.default()
        uploadLabel.isHidden = true
        progressView.isHidden = true
        if !isVideo {
            recipeVideo.isHidden = true
            playButtonOverlay.isHidden = true
        } else {
            recipeImage.isHidden = true
        }
        if recipe != nil {
            recipeDescription.lineBreakMode = .byWordWrapping
            recipeDescription.numberOfLines = 0
            if preview {
                manager = AWSUserFileManager.defaultUserFileManager()
                if isEdit {
                    navigationItem.title = "Edit Recipe"
                    uploadRecipe.setTitle("Update", for: .normal)
                } else {
                    navigationItem.title = "Preivew Recipe"
                }
                likeView.isHidden = true
                uploadRecipe.addTarget(self, action: #selector(RecipeDetailViewController.uploadNewRecipe(_:)), for: .touchUpInside)
                uploadRecipe.addTarget(self, action: #selector(RecipeDetailViewController.holdDown(_:)), for: .touchDown)
                uploadRecipe.layer.cornerRadius = 10
                uploadRecipe.layer.borderColor = UIColor.red.cgColor
                uploadRecipe.layer.borderWidth = 0.5

            } else {
                navigationItem.title = "Recipe Detail"
                addEditButton()
                setupLikeButton()
                uploadRecipe.isHidden = true
            }
            ingredientStackViewHeight.constant = (CGFloat(recipe.ingredients.count * 30))
            viewRecipeDetails()
            recipeDescription.layer.cornerRadius = 10.0
            pinBackground(ingredientsBackgroundView, to: ingredientStackView)
            pinBackground(stepsBackgroundView, to: stepStackView)
            recipeDescription.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
            
        }
    }
    
    func addEditButton() {
        if let username = identityManager.identityProfile?.userName {
            if admin.contains(username) {
                os_log("add edit button", log: OSLog.default, type: .debug)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(RecipeDetailViewController.editRecipe(_:)))
            }
        } else {
            os_log("not an admin", log: OSLog.default, type: .debug)
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        appDelegate.shouldRotate = false
    }
    
    func viewRecipeDetails() {
        if isVideo {
            displayVideo()
        } else {
            recipeImage.image = recipe?.image
        }
        recipeTitle.text = "\(recipe.name)"
        recipeDescription.text = "\(recipe.description)"
        insertIngredients()
        insertSteps()
    }
    
    func displayVideo() {
        if preview {
            recipeVideo.isHidden = true
            recipeImage.isHidden = false
            playButtonOverlay.isHidden = false
            recipeImage.image = recipe?.image
        } else {
            playButtonOverlay.isHidden = true
            appDelegate.shouldRotate = true // or false to disable rotation
            
            recipeVideo.frame = CGRect(x: 1, y: -20, width: screenSize.width - 2, height: screenSize.height/3 * 2)
            
            if let url = recipe.videoUrl {
                player = AVPlayer(url: url)
                avpController = AVPlayerViewController()
                avpController.player = player
                avpController.view.frame = recipeVideo.frame
                self.addChildViewController(avpController)
                self.recipeVideo.addSubview(avpController.view)
                player.play()
            }
        }
    }
    
    func insertIngredients() {
        os_log("inserting ingredients", log: OSLog.default, type: .debug)
        print("Ingredient count - \(recipe.ingredients.count)")
        for ingredient in recipe.ingredients {
            let ingredientLabel = UILabel()
            //ingredientLabel.frame = CGRect(x: 0, y: 0, width: stepStackView.frame.width, height: 30)
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold(ingredient.amount!)
                .normal(" " + ingredient.ingredientName!)
            ingredientLabel.attributedText = formattedString
            ingredientLabel.numberOfLines = 0
            ingredientLabel.lineBreakMode = .byWordWrapping
            ingredientLabel.sizeToFit()
            ingredientLabel.attributedText = formattedString
            
            let labelSize = rectForText(text: ingredient.amount! + ingredient.ingredientName!, font: ingredientLabel.font, maxSize: CGSize(width: ingredientStackView.frame.width, height: 999))
            let labelHeight = labelSize.height + 10
            ingredientLabel.frame = CGRect(x: 0, y: 0, width: ingredientStackView.frame.width, height: labelHeight)
            contentViewHeight.constant += labelHeight + 15
            ingredientStackView.addArrangedSubview(ingredientLabel)

            
            
            //contentViewHeight.constant += 30
            //ingredientStackView.addArrangedSubview(ingredientLabel)
            
        }
    }
    
    func insertSteps() {
        os_log("inserting steps", log: OSLog.default, type: .debug)
        print("Steps count - \(recipe.steps.count)")
        print("recipe steps \(recipe.steps)")
        for i in 0..<recipe.steps.count {
            let stepsLabel = UILabel()
            
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold("\(i+1). ")
                .normal(recipe.steps[i])
            print("step \(i+1) is \(recipe.steps[i])")
            stepsLabel.numberOfLines = 0
            stepsLabel.lineBreakMode = .byWordWrapping
            stepsLabel.sizeToFit()
            stepsLabel.attributedText = formattedString
            
            let labelSize = rectForText(text: recipe.steps[i], font: stepsLabel.font, maxSize: CGSize(width: ingredientStackView.frame.width, height: 999))
            let labelHeight = labelSize.height + 10
            stepsLabel.frame = CGRect(x: 0, y: 0, width: ingredientStackView.frame.width, height: labelHeight)
            contentViewHeight.constant += labelHeight + 15
            stepStackView.addArrangedSubview(stepsLabel)
            stepStackViewHeight.constant += labelHeight + 10

        }

    }
    
    func rectForText(text: String, font: UIFont, maxSize: CGSize) -> CGSize {
        let attrString = NSAttributedString.init(string: text, attributes: [NSFontAttributeName:font])
        let rect = attrString.boundingRect(with: maxSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        let size = CGSize(width: rect.size.width, height: rect.size.height)
        return size
    }
    
    func uploadNewRecipe(_ button: UIButton) {
        uploadRecipe.setTitleColor(.black, for: .normal)
        uploadRecipe.layer.backgroundColor = UIColor.clear.cgColor
        os_log("uploading new recipe", log: OSLog.default, type: .debug)
        if isEdit {
            updateRecipe()
        } else {
            if isVideo {
                let key: String = "\(FoodS3DirectoryName)\(recipe.name).mp4"
                let localContent = manager.localContent(with: data, key: key)
                uploadLocalContent(localContent)

                let imageKey: String = "\(FoodS3DirectoryName)\(recipe.name).jpg"
                let imgData = UIImageJPEGRepresentation(recipe.image!, 0.25)
                let imageContent = manager.localContent(with: imgData, key: imageKey)
                uploadImageContent(imageContent)
            } else {
                let key: String = "\(FoodS3DirectoryName)\(recipe.name).jpg"
                data = UIImageJPEGRepresentation(recipe.image!, 0.25)
                let localContent = manager.localContent(with: data, key: key)
                uploadLocalContent(localContent)
            }
        }
        
    }
    
    func updateRecipe() {
        os_log("update recipe", log: OSLog.default, type: .debug)
        updateLocalContent()
    }
    
    @IBAction func likeButton(_ sender: Any) {
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
        
        DynamoDbMyLikes.shared.insertMyLike(myLike){(errors: [NSError]?) -> Void in
            os_log("Inserted into sql", log: OSLog.default, type: .debug)
            if errors != nil {
                print("Error")
            }
            
            print("MyLikes saved succesfully")
            
        }
    }
}

extension NSMutableAttributedString {
    func bold(_ text:String) -> NSMutableAttributedString {
        let attrs:[String:AnyObject] = [NSFontAttributeName : UIFont(name: "HelveticaNeue-Bold", size: 16)!]
        let boldString = NSMutableAttributedString(string:"\(text)", attributes:attrs)
        self.append(boldString)
        return self
    }
    
    func normal(_ text:String)->NSMutableAttributedString {
        let normal =  NSAttributedString(string: text)
        self.append(normal)
        return self
    }
}
