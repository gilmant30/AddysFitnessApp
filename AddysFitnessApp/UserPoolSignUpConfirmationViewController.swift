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
import os.log

class UserPoolSignUpConfirmationViewController: UIViewController, UITextFieldDelegate {
    
    var sentTo: String?
    var user: AWSCognitoIdentityUser?
    var activeField: UITextField?
    
    let myActivityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var confirmationCode: UITextField!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var sendTo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.username.text = self.user!.username
        self.sendTo.text = "\(self.sentTo!)"
        username.delegate = self
        confirmationCode.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        backgroundImage.addBlurEffect()
        
    }
    
    @IBAction func onConfirm(_ sender: Any) {
        guard let confirmationCodeValue = self.confirmationCode.text, !confirmationCodeValue.isEmpty else {
            let alertController = UIAlertController(title: "Confirmation code missing.",
                    message: "Please enter a valid confirmation code.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        self.myActivityIndicator.startAnimating()
        self.user?.confirmSignUp(self.confirmationCode.text!, forceAliasCreation: true).continueWith(block: {[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: {
                if let error = task.error as? NSError {
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
                } else {
                    let alertController = UIAlertController(title: "Registration Complete",
                        message: "Registration was successful.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                    {
                        (result : UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    strongSelf.myActivityIndicator.stopAnimating()
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                    strongSelf.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            })
            return nil
        })

    }
    
    
    @IBAction func onResendConfirmationCode(_ sender: Any) {
        self.user?.resendConfirmationCode().continueWith(block: {[weak self] (task: AWSTask<AWSCognitoIdentityUserResendConfirmationCodeResponse>) -> AnyObject? in
            guard let _ = self else { return nil }
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
                } else if let result = task.result as AWSCognitoIdentityUserResendConfirmationCodeResponse! {
                    let alertController = UIAlertController(title: "Code Resent",
                            message: "RCode resent to \(result.codeDeliveryDetails?.destination!)", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                    {
                        (result : UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
            })
            return nil
        })

    }

    
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
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
