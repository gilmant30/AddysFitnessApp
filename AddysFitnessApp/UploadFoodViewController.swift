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

class UploadFoodViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    var manager:AWSUserFileManager!
    var foodType: String?
    var newRecipe = Recipe()
    var activeField: UITextField?
    var animateContenetView = true
    var image: UIImage?
    
    @IBOutlet weak var foodView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var ingredientButton: UIButton!
    @IBOutlet weak var stepButton: UIButton!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var recipeTitle: UITextField!
    @IBOutlet weak var recipeDescription: UITextView!
    
    @IBOutlet weak var categoryStackView: UIStackView!
    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var bfastLabel: UILabel!
    @IBOutlet weak var lunchLabel: UILabel!
    @IBOutlet weak var dinnerLabel: UILabel!
    @IBOutlet weak var snackLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        if let foodImage = image {
            foodView.image = foodImage
        }
        
        setupCategories()
        
        navigationItem.title = "Add Recipe"
        
        recipeTitle.delegate = self
        recipeDescription.delegate = self
        
        ingredientsLabel.text = "Ingredients: \(newRecipe.ingredients.count)"
        stepsLabel.text = "Steps: \(newRecipe.steps.count)"
        
        formatButtons()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // blur it
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.contentView.bounds
        self.backgroundImage.addSubview(blurView)
    }

    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ingredients") {
            os_log("Heading to add ingredients view", log: OSLog.default, type: .debug)
            let ingredientsViewController = segue.destination as! AddIngredientsController
            ingredientsViewController.ingredients = newRecipe.ingredients
        } else if (segue.identifier == "steps") {
            os_log("Heading to add steps view", log: OSLog.default, type: .debug)
            let stepsViewController = segue.destination as! AddStepsViewController
            stepsViewController.steps = newRecipe.steps
        } else if (segue.identifier == "recipeDetail") {
            os_log("Heading to add preview recipe view", log: OSLog.default, type: .debug)
            let previewRecipeViewController = segue.destination as! RecipeDetailViewController
            previewRecipeViewController.recipe = newRecipe
            previewRecipeViewController.preview = true
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "recipeDetail" {
            return validateInput()
        }
        
        return true
    }
    
    func validateInput() -> Bool {
        if let title = recipeTitle.text, title != "" {
            if let description = recipeDescription.text, description != "" {
                newRecipe.name = title
                newRecipe.description = description
                newRecipe.image = recipeImage.image
            } else {
                showSimpleAlertWithTitle("ERROR!", message: "Description cannot be empty", cancelButtonTitle: "Ok")
                return false
            }
        } else {
            showSimpleAlertWithTitle("ERROR!", message: "Title cannot be empty", cancelButtonTitle: "Ok")
            return false
        }
        
        return true
    }
    
    @IBAction func unwindToUploadFood(segue: UIStoryboardSegue) {
        // Here you can receive the parameter(s) from secondVC
        os_log("Unwinding from addIngredientsVC", log: OSLog.default, type: .debug)
        let addIngredientsViewController: AddIngredientsController = segue.source as! AddIngredientsController
        newRecipe.ingredients = addIngredientsViewController.ingredients
        ingredientsLabel.text = "Ingredients: \(newRecipe.ingredients.count)"
    }
    
    @IBAction func unwindFromStepsToUploadFood(segue: UIStoryboardSegue) {
        os_log("Unwinding from addStepsVC", log: OSLog.default, type: .debug)
        let addStepsViewController = segue.source as! AddStepsViewController
        newRecipe.steps = addStepsViewController.steps
        stepsLabel.text = "Steps: \(newRecipe.steps.count)"
    }
    
    @IBAction func unwindFromDetailToUploadFood(segue: UIStoryboardSegue) {
        os_log("Unwinding from detailVC", log: OSLog.default, type: .debug)
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"  // Recognizes enter key in keyboard
        {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
}
