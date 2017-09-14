//
//  HomeProfileViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/1/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

extension HomeProfileViewController {
    
    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        os_log("textFieldDidBeginEditing", log: OSLog.default, type: .debug)
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
        let changeInHeight = (keyboardFrame.height + 60) * (show ? 1 : -1)
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
    
    func dismissPicker() {
        view.endEditing(true)
    }
    
    func removeButtonTemplate() {
        maleButton.layer.backgroundColor = UIColor.clear.cgColor
        femaleButton.layer.backgroundColor = UIColor.clear.cgColor
        otherButton.layer.backgroundColor = UIColor.clear.cgColor
        
    }
    
    func genderButtonPressed(_ button: UIButton) {
        DispatchQueue.main.async {
            self.removeButtonTemplate()
            button.layer.backgroundColor = UIColor.red.cgColor
            
            if let genderValue = button.accessibilityHint {
                self.gender = genderValue
            }
        }
        
    }
    
    func setButtons() {
        editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(HomeProfileViewController.editProfileInfo(_:)))
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(HomeProfileViewController.doneEditProfileInfo(_:)))
        updateProfileButton.addTarget(self, action: #selector(HomeProfileViewController.updateAttributes(_:)), for: .touchUpInside)
        updateProfileButton.addTarget(self, action: #selector(HomeProfileViewController.holdDown(_:)), for: .touchDown)
        updateProfileButton.addTarget(self, action: #selector(HomeProfileViewController.release(_:)), for: .touchDragOutside)
        
        updateProfileButton.layer.borderColor = UIColor.red.cgColor
        updateProfileButton.layer.borderWidth = 1
        updateProfileButton.layer.cornerRadius = 10
        
    }
    
    func release(_ button: UIButton) {
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.red, for: .normal)
    }
    
    func holdDown(_ button: UIButton) {
        button.backgroundColor = UIColor.black
        button.setTitleColor(UIColor.white, for: .normal)
    }
}



