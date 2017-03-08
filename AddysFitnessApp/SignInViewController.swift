//
//  SignInViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper


class SignInViewController: UIViewController {

    //MARK: - Properties
    @IBOutlet weak var customEmailField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Sign In Loading.")
    }
}
