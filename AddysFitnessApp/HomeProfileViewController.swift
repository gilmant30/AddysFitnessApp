//
//  HomeProfileViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/22/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import AWSCognitoUserPoolsSignIn
import os.log

var profileInfo: Profile = Profile()
let ProfileImagesDirectoryName = "public/profileImages/"
var profileImageContents: AWSContent = AWSContent()
var profileImageLoaded: Bool = false

class HomeProfileViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var updateProfileButton: UIButton!
    
    @IBOutlet weak var genderStackView: UIStackView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileIntro: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var birthdayTextField: UITextField!
  
    @IBOutlet weak var updateButtonView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    var user: AWSCognitoIdentityUser?
    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var pool: AWSCognitoIdentityUserPool?
    var attributeList = [AWSCognitoIdentityUserAttributeType]()
    var activeField: UITextField?
    var gender: String?
    let datePicker = UIDatePicker()
    var editButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    var updateViewHeight: CGFloat?
    var data: Data?
    var newProfileImage: Bool = false
    let myActivityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setButtons()
        uploadImageButton.isHidden = true
        displayEditButton(true)
        
        updateViewHeight = updateButtonView.frame.height
        
        self.pool = AWSCognitoIdentityUserPool(forKey: AWSCognitoUserPoolsSignInProviderKey)
        if (self.user == nil) {
            self.user = self.pool?.currentUser()
        }
        
        if profileInfo.email == "" {
            user?.getDetails().continueOnSuccessWith{ (task) -> AnyObject? in
                DispatchQueue.main.async(execute: {
                    let response = task.result
                    let attributeMap = response?.userAttributes
                    if let map = attributeMap {
                        profileInfo.createUserProfile(map)
                        self.firstNameTextField.text = profileInfo.givenName
                        self.lastNameTextField.text = profileInfo.familyName
                        self.gender = profileInfo.gender
                        self.birthdayTextField.text = profileInfo.birthday
                        self.updateLabelData()
                    }
                    self.setInitialGender()
                })
                return nil
            }
        } else {
            self.firstNameTextField.text = profileInfo.givenName
            self.lastNameTextField.text = profileInfo.familyName
            self.gender = profileInfo.gender
            self.birthdayTextField.text = profileInfo.birthday
            self.updateLabelData()
        }
        
        hideLabels(false)
        initialSetup()
        
        if profileInfo.givenName == "" {
            profileIntro.isHidden = true
        } else {
            profileIntro.text = "Hi \(profileInfo.givenName!)!"
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UploadFoodViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if profileInfo.email == "" {
            LoadingOverlay.shared.displayOverlay()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                LoadingOverlay.shared.removeOverlay()
            })
        }
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .white
        self.view.addSubview(myActivityIndicator)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dismissKeyboard()
    }
    
    func updateAttributes(_ button: UIButton) {
        myActivityIndicator.startAnimating()
        profileInfo.givenName = firstNameTextField.text
        profileInfo.familyName = lastNameTextField.text
        profileInfo.gender = gender
        profileInfo.birthday = birthdayTextField.text
        
        self.updateUserProfile()
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.red, for: .normal)
    }
    
    func setInitialGender() {
        if let gender = gender {
            switch gender {
                case "male":
                    maleButton.layer.backgroundColor = UIColor.red.cgColor
                    maleButton.titleLabel?.textColor = UIColor.black
                case "female":
                    femaleButton.layer.backgroundColor = UIColor.red.cgColor
                    femaleButton.titleLabel?.textColor = UIColor.black
                default:
                    otherButton.layer.backgroundColor = UIColor.red.cgColor
                    otherButton.titleLabel?.textColor = UIColor.black
            }
        }
    }
    
    func updateUserProfile() {
        let attributeList:[AWSCognitoIdentityUserAttributeType] = profileInfo.addAttributesToList()
        self.user!.update(attributeList).continueWith(block: { (task:AWSTask<AWSCognitoIdentityUserUpdateAttributesResponse>) -> Any? in
            if task.error != nil {
                self.showSimpleAlertWithTitle("Error!", message: "Error updating profile", cancelButtonTitle: "Ok")
                self.myActivityIndicator.stopAnimating()
            } else {
                self.updateLabelData()
                self.myActivityIndicator.stopAnimating()
                self.showSimpleAlertWithTitle("Success!", message: "Profile has been updated", cancelButtonTitle: "Ok")
            }
            
            return nil
        })
    }
    
    func updateLabelData() {
        DispatchQueue.main.async {
            self.firstNameLabel.text = profileInfo.givenName
            self.lastNameLabel.text = profileInfo.familyName
            self.emailLabel.text = profileInfo.email
            self.genderLabel.text = profileInfo.gender
            self.gender = profileInfo.gender
            self.birthdayLabel.text = profileInfo.birthday
        }
    }
    
    func hideLabels(_ displayLabel: Bool) {
        let displayText = !displayLabel
        self.firstNameTextField.isHidden = displayText
        self.lastNameTextField.isHidden = displayText
        self.birthdayTextField.isHidden = displayText
        self.genderStackView.isHidden = displayText
        
        self.firstNameLabel.isHidden = displayLabel
        self.lastNameLabel.isHidden = displayLabel
        self.birthdayLabel.isHidden = displayLabel
        self.genderLabel.isHidden = displayLabel
        
        self.profileIntro.text = "Hi \(profileInfo.givenName!)!"
        self.profileIntro.isHidden = displayLabel
        
        //self.uploadImageButton.isHidden = displayText
        
    }
    
    func editProfileInfo(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.displayEditButton(false)
            self.hideLabels(true)
            self.showUpdateButton(show: true)
        }
    }
    
    func doneEditProfileInfo(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.displayEditButton(true)
            self.hideLabels(false)
            self.showUpdateButton(show: false)
        }
    }
    
    func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        birthdayTextField.text = dateFormatter.string(from: sender.date)
        
    }
    
    func displayEditButton(_ display:Bool) {
        DispatchQueue.main.async {
            if(display) {
                self.navigationItem.rightBarButtonItem = self.editButton
            } else {
                self.navigationItem.rightBarButtonItem = self.doneButton
            }
        }
        
    }
    
    
    func showUpdateButton(show:Bool) {
        let adjustingHeight = self.updateViewHeight! * (show ? 1 : -1)
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.contentViewHeight.constant += adjustingHeight
        })
        
        updateButtonView.isHidden = !show
        
    }
    
    func initialSetup() {
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        birthdayTextField.delegate = self
        datePicker.datePickerMode = UIDatePickerMode.date
        birthdayTextField.inputView = datePicker
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged), for: UIControlEvents.valueChanged)
        let toolBar = UIToolbar().ToolbarPiker(mySelect: #selector(self.dismissPicker))
        
        birthdayTextField.inputAccessoryView = toolBar
        
        maleButton.addTarget(self, action: #selector(self.genderButtonPressed(_:)), for: .touchUpInside)
        maleButton.accessibilityHint = "male"
        femaleButton.addTarget(self, action: #selector(self.genderButtonPressed(_:)), for: .touchUpInside)
        femaleButton.accessibilityHint = "female"
        otherButton.addTarget(self, action: #selector(self.genderButtonPressed(_:)), for: .touchUpInside)
        otherButton.accessibilityHint = ""
        showUpdateButton(show: false)
        
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
}

extension UIToolbar {
    
    func ToolbarPiker(mySelect : Selector) -> UIToolbar {
        
        let toolBar = UIToolbar()
        
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: mySelect)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([ spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
}
