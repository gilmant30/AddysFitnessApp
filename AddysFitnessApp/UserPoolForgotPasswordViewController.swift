//
//  UserPoolForgotPasswordViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/8/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import AWSCognitoUserPoolsSignIn

class UserPoolForgotPasswordViewController: UIViewController {
    
    //MARK: Properties
    
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?
    
    @IBOutlet weak var username: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool.init(forKey: AWSCognitoUserPoolsSignInProviderKey)
    }
    
    @IBAction func onForgotPassword(_ sender: Any) {
        guard let username = self.username.text, !username.isEmpty else {
            let alertController = UIAlertController(title: "Missing UserName",
                message: "Please enter a valid user name.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        self.user = self.pool?.getUser(self.username.text!)
        self.user?.forgotPassword().continueWith(block: {[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else {return nil}
            DispatchQueue.main.async(execute: {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                        message: error.userInfo["message"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default)
                    {
                        (result : UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                } else {
                    strongSelf.performSegue(withIdentifier: "NewPasswordSegue", sender: sender)
                }
            })
            return nil
        })
    }

    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
