//
//  WorkoutsViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 5/10/17.
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
extension WorkoutsViewController {
    
    func createTableHeader() -> UIStackView {
        let stackView = UIStackView()
        stackView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 140)
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        

        let upperBody = UIImage(named: "upperBodyWorkout")!
        upper.image = upperBody
        upper.layer.borderColor = UIColor.blue.cgColor
        upper.contentMode = .scaleAspectFit
        let lowerBody = UIImage(named: "lowerBodyWorkout")!
        lower.image = lowerBody
        lower.layer.borderColor = UIColor.blue.cgColor
        lower.contentMode = .scaleAspectFit
        let totalBody = UIImage(named: "totalBodyWorkout")!
        total.image = totalBody
        total.layer.borderColor = UIColor.blue.cgColor
        total.contentMode = .scaleAspectFit
        let fitTricks = UIImage(named: "fitTricks")!
        fit.image = fitTricks
        fit.layer.borderColor = UIColor.blue.cgColor
        fit.contentMode = .scaleAspectFit
        
        addTap()

        stackView.addArrangedSubview(upper)
        stackView.addArrangedSubview(lower)
        stackView.addArrangedSubview(total)
        stackView.addArrangedSubview(fit)
        
        
        return stackView
    }
    
    func addTap() {
        // create tapGestureRecognizer for images
        let tapUpperBody = UITapGestureRecognizer(target: self, action: #selector(self.upperBodyTapped))
        
        let tapLowerBody = UITapGestureRecognizer(target: self, action: #selector(self.lowerBodyTapped))
        
        let tapTotalBody = UITapGestureRecognizer(target: self, action: #selector(self.totalBodyTapped))
        
        let tapFitTricks = UITapGestureRecognizer(target: self, action: #selector(self.fitTricksTapped))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapUpperBody.numberOfTapsRequired = 1
        tapLowerBody.numberOfTapsRequired = 1
        tapTotalBody.numberOfTapsRequired = 1
        tapFitTricks.numberOfTapsRequired = 1
        
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
        
        upper.isUserInteractionEnabled = true
        upper.addGestureRecognizer(tapUpperBody)
        lower.isUserInteractionEnabled = true
        lower.addGestureRecognizer(tapLowerBody)
        total.isUserInteractionEnabled = true
        total.addGestureRecognizer(tapTotalBody)
        fit.isUserInteractionEnabled = true
        fit.addGestureRecognizer(tapFitTricks)
    }
    
    func upperBodyTapped() {
        categoryTapped(0)
    }
    
    func lowerBodyTapped() {
        categoryTapped(1)
    }
    
    func totalBodyTapped() {
        categoryTapped(2)
    }
    
    func fitTricksTapped() {
        categoryTapped(3)
    }
    
    func categoryTapped(_ index: Int) {
        resetBackground()
        if(index == 0){
            upper.backgroundColor = UIColor.darkGray
            self.workoutsSearchResults = workouts.filter {
                $0.workoutType == "upperBodyWorkout"
            }
        } else if(index == 1){
            lower.backgroundColor = UIColor.darkGray
            self.workoutsSearchResults = workouts.filter {
                $0.workoutType == "lowerBodyWorkout"
            }
        } else if(index == 2){
            total.backgroundColor = UIColor.darkGray
            self.workoutsSearchResults = workouts.filter {
                $0.workoutType == "totalBodyWorkout"
            }
        } else if(index == 3){
            fit.backgroundColor = UIColor.darkGray
            self.workoutsSearchResults = workouts.filter {
                $0.workoutType == "fitTricks"
            }
        } else {
            self.workoutsSearchResults = workouts
        }
        self.updateUserInterface()
    }

    
    func resetBackground() {
        upper.backgroundColor = UIColor.clear
        lower.backgroundColor = UIColor.clear
        total.backgroundColor = UIColor.clear
        fit.backgroundColor = UIColor.clear
    }

}
