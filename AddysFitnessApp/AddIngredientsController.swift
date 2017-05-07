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
    @IBOutlet weak var inputStackView: UIStackView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var ingredientTextField: UITextField!
    
    @IBOutlet weak var ingredientInputStackView: UIStackView!
    @IBOutlet weak var ingredientInputStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var backgroundImage: UIImageView!
    override func viewDidLoad() {
        navigationItem.title = "Add Ingredients"
        let screenSize = UIScreen.main.bounds
        contentViewHeight.constant = screenSize.height
        screenWidth = screenSize.width
        loadIngredientsList()
        contentViewHeight.constant = screenSize.height
        
        amountTextFields.append(amountTextField)
        ingredientTextFields.append(ingredientTextField)
        
        setupUIElements()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddIngredientsController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AddIngredientsController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // blur it
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.contentView.bounds
        self.backgroundImage.addSubview(blurView)
    }
    
    func setupUIElements() {
        amountTextField.delegate = self
        ingredientTextField.delegate = self
        amountTextField.layer.borderColor = UIColor.blue.cgColor
        amountTextField.layer.borderWidth = 0.5
        amountTextField.layer.cornerRadius = 2
        
        ingredientTextField.layer.borderColor = UIColor.blue.cgColor
        ingredientTextField.layer.borderWidth = 0.5
        ingredientTextField.layer.cornerRadius = 2
        
        
        for case let button as UIButton in ingredientStackView.subviews {
            button.layer.cornerRadius = 10
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1
        }
    }
    
    func loadIngredientsList() {
        for i in 0 ..< ingredients.count {
            if(i == 0) {
                amountTextField.text = ingredients[i].amount
                ingredientTextField.text = ingredients[i].ingredientName
            } else {
                addNewStackView(true, ingredients[i])
            }
        }
    }
    
    func addNewStackView(_ insertText: Bool, _ ingredient: Ingredients) {
        let newStackView = createStackView(insertText, ingredient.ingredientName!, ingredient.amount!)
        
        ingredientInputStackView.addArrangedSubview(newStackView)
        
        ingredientInputStackViewHeight.constant += 45
        contentViewHeight.constant += 45
    }
    
    func addIngredientFields() {
        let temp = Ingredients()
        temp.amount = ""
        temp.ingredientName = ""
        addNewStackView(false, temp)
    }
    
    func createStackView(_ insertText: Bool, _ ingredient: String, _ amount: String) -> UIStackView {
        let newStackView = UIStackView()
        newStackView.frame = CGRect(x: 0, y: 0, width: ingredientInputStackView.frame.width, height: 30)
        newStackView.alignment = .fill
        newStackView.distribution = .fillEqually
        newStackView.axis = .horizontal
        newStackView.spacing = 10
        
        let amountText = TextField()
        amountText.frame = amountTextField.frame
        amountText.delegate = self
        amountText.layer.borderColor = amountTextField.layer.borderColor
        amountText.textAlignment = amountTextField.textAlignment
        amountText.font = amountTextField.font
        amountText.layer.borderWidth = amountTextField.layer.borderWidth
        amountText.layer.cornerRadius = amountTextField.layer.cornerRadius
        
        let ingredientText = TextField()
        ingredientText.frame = CGRect(x: 0, y: 0, width: ingredientTextField.frame.width, height: 30)
        ingredientText.delegate = self
        ingredientText.textAlignment = ingredientTextField.textAlignment
        ingredientText.font = ingredientTextField.font
        ingredientText.layer.cornerRadius = ingredientTextField.layer.cornerRadius
        ingredientText.layer.borderColor = ingredientTextField.layer.borderColor
        ingredientText.layer.borderWidth = ingredientTextField.layer.borderWidth
        
        if(insertText) {
            amountText.text = amount
            ingredientText.text = ingredient
        } else {
            amountText.placeholder = "Enter Amount"
            ingredientText.placeholder = "Enter Ingredient"
        }
        
        ingredientTextFields.append(ingredientText)
        amountTextFields.append(amountText)
        
        newStackView.addArrangedSubview(amountText)
        newStackView.addArrangedSubview(ingredientText)
        
        return newStackView
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
