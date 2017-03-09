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

class UserPoolsSignUpViewController: UIViewController {
    //MARK: Properties
    
    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var email: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool.init(forKey: AWSCognitoUserPoolsSignInProviderKey)
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
                UIAlertView(title: "Missing Required Fields",
                            message: "Username / Password are required for registration.",
                            delegate: nil,
                            cancelButtonTitle: "Ok").show()
                return
        }
        
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        if let phoneValue = self.phone.text, !phoneValue.isEmpty {
            let phone = AWSCognitoIdentityUserAttributeType()
            phone?.name = "phone_number"
            phone?.value = phoneValue
            attributes.append(phone!)
        }
        
        if let emailValue = self.email.text, !emailValue.isEmpty {
            let email = AWSCognitoIdentityUserAttributeType()
            email?.name = "email"
            email?.value = emailValue
            attributes.append(email!)
        }
        
        //sign up the user
        self.pool?.signUp(userNameValue, password: passwordValue, userAttributes: attributes, validationData: nil).continueWith {[weak self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: {
                if let error = task.error as? NSError {
                    UIAlertView(title: error.userInfo["__type"] as? String,
                                message: error.userInfo["message"] as? String,
                                delegate: nil,
                                cancelButtonTitle: "Ok").show()
                    return
                }
                
                if let result = task.result as AWSCognitoIdentityUserPoolSignUpResponse! {
                    // handle the case where user has to confirm his identity via email / SMS
                    if (result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed) {
                        strongSelf.sentTo = result.codeDeliveryDetails?.destination
                        strongSelf.performSegue(withIdentifier: "SignUpConfirmSegue", sender:sender)
                    } else {
                        UIAlertView(title: "Registration Complete",
                                    message: "Registration was successful.",
                                    delegate: nil,
                                    cancelButtonTitle: "Ok").show()
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
}
