//
//  SignInViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider
import os.log

class SignInViewController: UIViewController, UITextFieldDelegate {

    //MARK: - Properties
    @IBOutlet weak var customEmailField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    
    @IBOutlet weak var customSignInButton: UIButton!
    @IBOutlet weak var customCreateAccountButton: UIButton!
   
    @IBOutlet weak var customForgotPasswordButton: UIButton!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var customSignInImage: UIImageView!
    
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    let signInImage = UIImage(named: "SignIn")
    let myActivityIndicator = UIActivityIndicatorView()
    
    var didSignInObserver: AnyObject!
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AnyObject>?
    var activeField: UITextField?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Sign In Loading.")
        backgroundImage.addBlurEffect()
        let screenSize = UIScreen.main.bounds
        
        contentViewHeight.constant = screenSize.height
        
        // Custom UI Setup
        customSignInButton.addTarget(self, action: #selector(self.handleCustomSignIn), for: .touchUpInside)
        customCreateAccountButton.addTarget(self, action: #selector(self.handleUserPoolSignUp), for: .touchUpInside)
        customForgotPasswordButton.addTarget(self, action: #selector(self.handleUserPoolForgotPassword), for: .touchUpInside)
        
        customEmailField.delegate = self
        customPasswordField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility Methods
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        myActivityIndicator.startAnimating()
        AWSSignInManager.sharedInstance().login(signInProviderKey: signInProvider.identityProviderName, completionHandler: {(result: Any?, authState: AWSIdentityManagerAuthState, error: Error?) in
            print("result = \(String(describing: result)), error = \(String(describing: error))")
            // If no error reported by SignInProvider, discard the sign-in view controller.
            guard let _ = result else {
                self.showErrorDialog(signInProvider.identityProviderName, withError: error! as NSError)
                self.myActivityIndicator.stopAnimating()
                return
            }
            self.myActivityIndicator.stopAnimating()
            DispatchQueue.main.async(execute: {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
        print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        os_log("Text field did end editing", log: OSLog.default, type: .debug)
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        os_log("Text field is being edited", log: OSLog.default, type: .debug)
        self.activeField = textField
    }

}
