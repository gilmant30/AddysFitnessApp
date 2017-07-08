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
    var data:Data!
    
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
    
    override func viewDidLoad() {
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
                navigationItem.title = "Preivew Recipe"
                let uploadTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RecipeDetailViewController.uploadNewRecipe))
                uploadTap.numberOfTapsRequired = 1
                uploadRecipe.addGestureRecognizer(uploadTap)

                
            } else {
                navigationItem.title = "Recipe Detail"
                uploadRecipe.isHidden = true
            }
            ingredientStackViewHeight.constant = (CGFloat(recipe.ingredients.count * 30))
            viewRecipeDetails()
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
            
            if let url = recipe.url {
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
            ingredientLabel.frame = CGRect(x: 0, y: 0, width: stepStackView.frame.width, height: 30)
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold(ingredient.amount!)
                .normal(" " + ingredient.ingredientName!)
            ingredientLabel.attributedText = formattedString
            
            
            contentViewHeight.constant += 30
            ingredientStackView.addArrangedSubview(ingredientLabel)
            
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
            contentViewHeight.constant += labelHeight + 10
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
    
    func uploadNewRecipe() {
        os_log("uploading new recipe", log: OSLog.default, type: .debug)
        if isVideo {
            let key: String = "\(RecipeImagesDirectoryName)\(recipe.name).mp4"
            let localContent = manager.localContent(with: data, key: key)
            uploadLocalContent(localContent)
        } else {
            let key: String = "\(RecipeImagesDirectoryName)\(recipe.name).jpg"
            data = UIImageJPEGRepresentation(recipe.image!, 0.25)
            let localContent = manager.localContent(with: data, key: key)
            uploadLocalContent(localContent)
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
