//
//  UserPoolSignUpConfirmationViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/8/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper

class UserPoolSignUpConfirmationViewController: UIViewController {
    
    var sentTo: String?
    var user: AWSCognitoIdentityUser?
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var confirmationCode: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.username.text = self.user!.username;
    }
    
    @IBAction func onConfirm(_ sender: Any) {
    }
    
    
    @IBAction func onResendConfirmationCode(_ sender: Any) {
    }

    
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
