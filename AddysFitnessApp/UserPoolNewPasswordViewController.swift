//
//  UserPoolNewPasswordViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/8/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import os.log

class UserPoolNewPasswordViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    var user: AWSCognitoIdentityUser?
    var activeField: UITextField?
    
    let myActivityIndicator = UIActivityIndicatorView()
    
    @IBOutlet weak var confirmationCode: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImage.addBlurEffect()
        
        confirmationCode.delegate = self
        newPassword.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        
    }
    
    
    @IBAction func onUpdatePassword(_ sender: Any) {
        os_log("Update password pressed", log: OSLog.default, type: .debug)
        guard let confirmationCodeValue = self.confirmationCode.text, !confirmationCodeValue.isEmpty else {
            let alertController = UIAlertController(title: "Password Field Empty",
                message: "Please enter a password of your choice.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            {
                (result : UIAlertAction) -> Void in
                print("You pressed OK")
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        myActivityIndicator.startAnimating()
        //confirm forgot password with input from ui.
        _ = self.user?.confirmForgotPassword(confirmationCodeValue, password: self.newPassword.text!).continueWith(block: {[weak self] (task: AWSTask) -> AnyObject? in
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
                } else {
                    let alertController = UIAlertController(title: "Password Reset Complete",
                            message: "Password Reset was completed successfully.", preferredStyle: UIAlertControllerStyle.alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                    {
                        (result : UIAlertAction) -> Void in
                        print("You pressed OK")
                    }
                    alertController.addAction(okAction)
                    strongSelf.myActivityIndicator.stopAnimating()
                    self?.present(alertController, animated: true, completion: nil)
                    strongSelf.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            })
            return nil
        })

    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
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
