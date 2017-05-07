//
//  RecipeDetailViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/28/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

let RecipeImagesDirectoryName = "public/recipeImages/"
class RecipeDetailViewController: UIViewController {
    var manager: AWSUserFileManager!
    var recipe: Recipe!
    var preview: Bool = false
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
    
    override func viewDidLoad() {
        uploadLabel.isHidden = true
        progressView.isHidden = true
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
            stepStackViewHeight.constant = (CGFloat(recipe.steps.count * 30))
            viewRecipeDetails()
        }
    }
    
    func viewRecipeDetails() {
        recipeImage.image = recipe?.image
        recipeTitle.text = "\(recipe.name)"
        recipeDescription.text = "\(recipe.description)"
        insertIngredients()
        insertSteps()
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
        print("Ingredient count - \(recipe.ingredients.count)")
        for i in 0..<recipe.steps.count {
            let ingredientLabel = UILabel()
            ingredientLabel.frame = CGRect(x: 0, y: 0, width: ingredientStackView.frame.width, height: 30)
            let formattedString = NSMutableAttributedString()
            formattedString
                .bold("\(i+1). ")
                .normal(recipe.steps[i])
            ingredientLabel.attributedText = formattedString
            
            contentViewHeight.constant += 30
            stepStackView.addArrangedSubview(ingredientLabel)
            
        }

    }
    
    func uploadNewRecipe() {
        os_log("unwinding from upload", log: OSLog.default, type: .debug)
        performSegue(withIdentifier: "unwindFromDetailToUpload", sender: self)
        /*
        let key: String = "\(RecipeImagesDirectoryName)\(recipe.name).png"
        data = UIImagePNGRepresentation(recipe.image!)!
        let localContent = manager.localContent(with: data, key: key)
        uploadLocalContent(localContent)
         */
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
