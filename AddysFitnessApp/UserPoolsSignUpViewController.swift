//
//  UserPoolsSignUpViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/8/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider
import AWSCognitoUserPoolsSignIn
import os.log

class UserPoolsSignUpViewController: UIViewController, UITextFieldDelegate {
    //MARK: Properties
    
    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?
    var activeField: UITextField?
    let capitalLetterRegEx  = ".*[A-Z]+.*"
    let lowerLetterRegEx = ".*[a-z]+.*"
    let specialCharacterRegEx  = ".*[!&^%$#@()/.,?]+.*"
    
    let myActivityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var lowerCaseLetter: UILabel!
    @IBOutlet weak var symbolLetter: UILabel!
    @IBOutlet weak var upperCaseLetter: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool.init(forKey: AWSCognitoUserPoolsSignInProviderKey)
        backgroundImage.addBlurEffect()
        
        username.delegate = self
        password.delegate = self
        email.delegate = self
        password.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let signUpConfirmationViewController = segue.destination as? UserPoolSignUpConfirmationViewController {
            signUpConfirmationViewController.sentTo = self.sentTo
            signUpConfirmationViewController.user = self.pool?.getUser(self.username.text!)
        }

    }

    @IBAction func onSignUp(_ sender: Any) {
        guard let userNameValue = self.username.text, !userNameValue.isEmpty,
            let passwordValue = self.password.text, !passwordValue.isEmpty else {
                let alertController = UIAlertController(title: "Missing Required Fields",
                                        message: "Username / Password are required for registration.", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                {
                    (result : UIAlertAction) -> Void in
                    print("You pressed OK")
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
        
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        if let emailValue = self.email.text, !emailValue.isEmpty {
            let email = AWSCognitoIdentityUserAttributeType()
            email?.name = "email"
            email?.value = emailValue
            attributes.append(email!)
        }
        self.myActivityIndicator.startAnimating()
        //sign up the user
        self.pool?.signUp(userNameValue, password: passwordValue, userAttributes: attributes, validationData: nil).continueWith {[weak self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                message: error.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
                    {
                        (result : UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    strongSelf.myActivityIndicator.stopAnimating()
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
                
                if let result = task.result as AWSCognitoIdentityUserPoolSignUpResponse! {
                    // handle the case where user has to confirm his identity via email / SMS
                    if (result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed) {
                        strongSelf.sentTo = result.codeDeliveryDetails?.destination
                        strongSelf.performSegue(withIdentifier: "SignUpConfirmSegue", sender:sender)
                    } else {
                        let alertController = UIAlertController(title: "Registration Complete",
                        message: "Registration was successful.", preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
                        {
                            (result : UIAlertAction) -> Void in
                            print("You pressed OK")
                        }
                        strongSelf.myActivityIndicator.stopAnimating()
                        alertController.addAction(okAction)
                        self?.present(alertController, animated: true, completion: nil)
                        strongSelf.presentingViewController?.dismiss(animated: true, completion: nil)
                    }
                }
                
            })
            return nil
        }

    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        print("text field changed")
        if let password = password.text {
            let lower = NSPredicate(format:"SELF MATCHES %@", lowerLetterRegEx)
            let upper = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
            if(lower.evaluate(with: password)) {
                lowerCaseLetter.text = "o Lowercase Letter"
                lowerCaseLetter.textColor = UIColor.green
            } else {
                lowerCaseLetter.text = "x Lowercase Letter"
                lowerCaseLetter.textColor = UIColor.red
                }
            if(upper.evaluate(with: password)) {
                upperCaseLetter.text = "o Uppercase Letter"
                upperCaseLetter.textColor = UIColor.green
            } else {
                upperCaseLetter.text = "x Uppercase Letter"
                upperCaseLetter.textColor = UIColor.red
            }
            if(password.characters.count >= 6) {
                symbolLetter.text = "o At least 6 characters long"
                symbolLetter.textColor = UIColor.green
            } else {
                symbolLetter.text = "o At least 6 characters long"
                symbolLetter.textColor = UIColor.red
            }
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
        self.activeField = textField
    }

}
