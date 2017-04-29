//
//  AddIngredientsController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/26/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC


class AddIngredientsController: UIViewController, UITextFieldDelegate {
    
    var ingredients: [Ingredients] = []
    var ingredientTextFields: [UITextField] = []
    var amountTextFields: [UITextField] = []
    var activeField: UITextField?
    let screenSize = UIScreen.main.bounds
    var screenWidth: CGFloat!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var ingredientStackView: UIStackView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        navigationItem.title = "Add Ingredients"
        let screenSize = UIScreen.main.bounds
        contentViewHeight.constant = screenSize.height
        screenWidth = screenSize.width
        loadIngredientsList()
        
        for case let button as UIButton in ingredientStackView.subviews {
            button.layer.cornerRadius = 10
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddIngredientsController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AddIngredientsController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func loadIngredientsList() {
        
        for i in 0 ..< ingredients.count {
            let amountText = UITextField()
            amountText.text = "\(ingredients[i].amount ?? "")"
            if (i == 0) {
                amountText.frame = CGRect(x: 8, y: self.ingredientStackView.frame.origin.y + 30, width: (screenWidth/2) - 5, height: 30)
            } else {
                let textField: UITextField = ingredientTextFields[ingredientTextFields.count - 1]
                amountText.frame = CGRect(x: 8, y: textField.frame.origin.y + 65, width: (screenWidth/2) - 5, height: 30)
            }
            
            amountText.delegate = self
            
            amountText.backgroundColor = UIColor.white
            amountText.layer.borderColor = UIColor.blue.cgColor
            amountText.layer.borderWidth = 0.5
            amountText.layer.cornerRadius = 2
            
            let ingredientText = UITextField()
            ingredientText.text = "\(ingredients[i].ingredientName ?? "")"
            if (i == 0) {
                ingredientText.frame = CGRect(x: screenWidth/2 + 5, y: self.ingredientStackView.frame.origin.y + 30, width: (screenWidth/2) - 10, height: 30)
            } else {
                let textField: UITextField = ingredientTextFields[ingredientTextFields.count - 1]
                ingredientText.frame = CGRect(x: screenWidth/2 + 5, y: textField.frame.origin.y + 65, width: (screenWidth/2) - 10, height: 30)
            }
            
            ingredientText.delegate = self
            ingredientText.backgroundColor = UIColor.white
            ingredientText.layer.borderColor = UIColor.darkGray.cgColor
            ingredientText.layer.borderWidth = 0.5
            ingredientText.layer.cornerRadius = 2
            
            ingredientTextFields.append(ingredientText)
            amountTextFields.append(amountText)
            
            contentViewHeight.constant += 65
            stackViewHeight.constant += 65
            
            contentView.addSubview(amountText)
            contentView.addSubview(ingredientText)

        }
    }
    
    func addIngredientFields() {
         let ingredientAmount = UITextField()
         let ingredientName = UITextField()
         
         if ingredientTextFields.count > 0 {
             os_log("some ingredients added already", log: OSLog.default, type: .debug)
             let textField: UITextField = ingredientTextFields[ingredientTextFields.count - 1]
             ingredientAmount.frame = CGRect(x: 8, y: textField.frame.origin.y + 65, width: (screenSize.width/2) - 5, height: 30)
             ingredientAmount.placeholder = "Add Amount"
             ingredientAmount.backgroundColor = UIColor.white
             
             ingredientName.frame = CGRect(x: screenSize.width/2 + 5, y: textField.frame.origin.y + 65, width: (screenSize.width/2) - 10, height: 30)
             ingredientName.placeholder = "Add Name"
             ingredientName.backgroundColor = UIColor.white
             ingredientName.layer.borderColor = UIColor.darkGray.cgColor
             ingredientName.layer.borderWidth = 0.5
            ingredientName.layer.cornerRadius = 2
            
            ingredientAmount.layer.borderColor = UIColor.blue.cgColor
            ingredientAmount.layer.borderWidth = 0.5
            ingredientAmount.layer.cornerRadius = 2
            
             
             ingredientName.delegate = self
             ingredientAmount.delegate = self
             
             ingredientTextFields.append(ingredientName)
             amountTextFields.append(ingredientAmount)
             
             contentViewHeight.constant += 65
             stackViewHeight.constant += 65
             
             contentView.addSubview(ingredientAmount)
             contentView.addSubview(ingredientName)
         
         } else {
             os_log("no ingredients added yet", log: OSLog.default, type: .debug)
             ingredientAmount.frame = CGRect(x: 8, y: self.ingredientStackView.frame.origin.y + 30, width: (screenSize.width/2) - 5, height: 30)
             ingredientAmount.placeholder = "Add Amount"
             ingredientAmount.backgroundColor = UIColor.white
             
             ingredientName.frame = CGRect(x: screenSize.width/2 + 5, y: self.ingredientStackView.frame.origin.y + 30, width: (screenSize.width/2) - 10, height: 30)
             ingredientName.placeholder = "Add Name"
             ingredientName.backgroundColor = UIColor.white
    
            ingredientName.layer.borderColor = UIColor.darkGray.cgColor
            ingredientName.layer.borderWidth = 0.5
            ingredientName.layer.cornerRadius = 2
            
            ingredientAmount.layer.borderColor = UIColor.blue.cgColor
            ingredientAmount.layer.borderWidth = 0.5
            ingredientAmount.layer.cornerRadius = 2
            
             ingredientName.delegate = self
             ingredientAmount.delegate = self
             
             ingredientTextFields.append(ingredientName)
             amountTextFields.append(ingredientAmount)
             
             contentViewHeight.constant += 65
             stackViewHeight.constant += 65
             
             contentView.addSubview(ingredientAmount)
             contentView.addSubview(ingredientName)
         }
     }
    
    func verifyAllIngredientsAdded() -> Bool {
        os_log("Verifying all text fields have input", log: OSLog.default, type: .debug)
        
        ingredients.removeAll()
        
        for i in 0..<ingredientTextFields.count {
            let ingredient = Ingredients()
            ingredient.ingredientName = ingredientTextFields[i].text ?? ""
            ingredient.amount = amountTextFields[i].text ?? ""
            
            if !(ingredient.ingredientName == "" || ingredient.amount == "") {
                ingredients.append(ingredient)
            }
        }
        return true
    }
    
    // MARK: - Action
    
    @IBAction func addIngredientTapped(_ sender: Any) {
        addIngredientFields()
    }
    
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        if(verifyAllIngredientsAdded()) {
            os_log("Clicked finish going to unwind segue", log: OSLog.default, type: .debug)
            self.performSegue(withIdentifier: "unwindToUploadFood", sender: self)
        } else {
            os_log("Error with verifying inputs", log: OSLog.default, type: .debug)
        }
    }
    
    // MARK: - Keyboard
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        os_log("Text field is being edited", log: OSLog.default, type: .debug)
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
