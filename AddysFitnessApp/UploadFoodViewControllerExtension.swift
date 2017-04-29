//
//  UploadFoodViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/24/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

extension UploadFoodViewController {
    
    func formatButtons() {
        ingredientButton.layer.cornerRadius = 10
        ingredientButton.layer.borderColor = UIColor.black.cgColor
        ingredientButton.layer.borderWidth = 1
        
        stepButton.layer.cornerRadius = 10
        stepButton.layer.borderColor = UIColor.black.cgColor
        stepButton.layer.borderWidth = 1
        
        previewButton.layer.cornerRadius = 10
        previewButton.layer.borderColor = UIColor.black.cgColor
        previewButton.layer.borderWidth = 1

    }
    
    func setupCategories() {
        categoriesToButtons()
        let bfastTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.addCategory))
        bfastLabel.isUserInteractionEnabled = true
        bfastTap.numberOfTapsRequired = 1
        bfastLabel.addGestureRecognizer(bfastTap)
        
        let lunchTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.addCategory))
        lunchLabel.isUserInteractionEnabled = true
        lunchTap.numberOfTapsRequired = 1
        lunchLabel.addGestureRecognizer(lunchTap)
        
        let dinnerTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.addCategory))
        dinnerLabel.isUserInteractionEnabled = true
        dinnerTap.numberOfTapsRequired = 1
        dinnerLabel.addGestureRecognizer(dinnerTap)
        
        let snackTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UploadFoodViewController.addCategory))
        snackLabel.isUserInteractionEnabled = true
        snackTap.numberOfTapsRequired = 1
        snackLabel.addGestureRecognizer(snackTap)
        
        bfastLabel.tag = 1
        lunchLabel.tag = 2
        dinnerLabel.tag = 3
        snackLabel.tag = 4
    }
    
    func categoriesToButtons() {
        for case let label as UILabel in categoryStackView.subviews {
            label.layer.cornerRadius = 5
            label.layer.borderColor = UIColor.black.cgColor
            label.layer.borderWidth = 0.5
            label.layer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    func addCategory(tapsender: UITapGestureRecognizer) {
        let sender = tapsender.view!.tag
        
        resetCategory()
        
        switch sender {
        case 1:
            os_log("Adding bfast category", log: OSLog.default, type: .debug)
            newRecipe.category = "bfast"
            bfastLabel.backgroundColor = UIColor.darkGray
        case 2:
            os_log("Adding lunch category", log: OSLog.default, type: .debug)
            newRecipe.category = "lunch"
            lunchLabel.backgroundColor = UIColor.darkGray
        case 3:
            os_log("Adding dinner category", log: OSLog.default, type: .debug)
            newRecipe.category = "dinner"
            dinnerLabel.backgroundColor = UIColor.darkGray
        case 4:
            os_log("Adding snack category", log: OSLog.default, type: .debug)
            newRecipe.category = "snack"
            snackLabel.backgroundColor = UIColor.darkGray
        default:
            os_log("This shouldn't be called", log: OSLog.default, type: .debug)
        }
    }
    
    
    func resetCategory() {
        bfastLabel.backgroundColor = UIColor.white
        lunchLabel.backgroundColor = UIColor.white
        dinnerLabel.backgroundColor = UIColor.white
        snackLabel.backgroundColor = UIColor.white
    }
    
}
