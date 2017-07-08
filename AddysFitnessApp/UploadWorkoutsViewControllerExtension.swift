//
//  UploadWorkoutsViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 5/8/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper
import os.log


extension UploadWorkoutsViewController {
    
    func categorySetup() {
        // create tapGestureRecognizer for images
        let tapUpperBody = UITapGestureRecognizer(target: self, action: #selector(self.upperBodySelected))
        
        let tapLowerBody = UITapGestureRecognizer(target: self, action: #selector(self.lowerBodySelected))
        
        let tapTotalBody = UITapGestureRecognizer(target: self, action: #selector(self.totalBodySelected))
        
        let tapFitTricks = UITapGestureRecognizer(target: self, action: #selector(self.fitTricksSelected))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapUpperBody.numberOfTapsRequired = 1
        tapLowerBody.numberOfTapsRequired = 1
        tapTotalBody.numberOfTapsRequired = 1
        tapFitTricks.numberOfTapsRequired = 1
        
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
    
        armWorkout.isUserInteractionEnabled = true
        armWorkout.addGestureRecognizer(tapUpperBody)
        legWorkout.isUserInteractionEnabled = true
        legWorkout.addGestureRecognizer(tapLowerBody)
        totalBodyWorkout.isUserInteractionEnabled = true
        totalBodyWorkout.addGestureRecognizer(tapTotalBody)
        fitTricks.isUserInteractionEnabled = true
        fitTricks.addGestureRecognizer(tapFitTricks)
    }
    
    func upperBodySelected() {
        categorySelected(0)
    }
    
    func lowerBodySelected() {
        categorySelected(1)
    }
    
    func totalBodySelected() {
        categorySelected(2)
    }
    
    func fitTricksSelected() {
        categorySelected(3)
    }
    
    func categorySelected(_ index: Int) {
        resetBackground()
        switch index {
        case 0:
            os_log("Clicked upper body workout", log: OSLog.default, type: .debug)
            armWorkout.backgroundColor = UIColor.darkGray
            workoutType = "upperBodyWorkout"
        case 1:
            os_log("Clicked lower body workout", log: OSLog.default, type: .debug)
            legWorkout.backgroundColor = UIColor.darkGray
            workoutType = "lowerBodyWorkout"
            
        case 2:
            os_log("Clicked total body workout", log: OSLog.default, type: .debug)
            totalBodyWorkout.backgroundColor = UIColor.darkGray
            workoutType = "totalBodyWorkout"
        
        case 3:
            os_log("Clicked fit tricks workout", log: OSLog.default, type: .debug)
            fitTricks.backgroundColor = UIColor.darkGray
            workoutType = "fitTricks"
            
        default:
            os_log("This should never be shown", log: OSLog.default, type: .debug)
        
        }
    }
    
    func resetBackground() {
        armWorkout.backgroundColor = UIColor.clear
        legWorkout.backgroundColor = UIColor.clear
        totalBodyWorkout.backgroundColor = UIColor.clear
        fitTricks.backgroundColor = UIColor.clear
    }
}
