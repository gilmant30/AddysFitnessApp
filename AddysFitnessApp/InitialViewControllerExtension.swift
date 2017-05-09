//
//  InitialViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 5/9/17.
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

extension InitialViewController {
    func getS3Data() {
        DispatchQueue.main.sync {
            getRecipes()
        }
        DispatchQueue.main.sync {
            getWorkouts()
        }
    }
    
    func getRecipes() {
        manager.listAvailableContents(withPrefix: FoodImagesDirectoryName, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents, contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllImages = false
                } else {
                    strongSelf.didLoadAllImages = true
                }
                print("contents count - \(contents.count)")
                strongSelf.marker = nextMarker
                strongSelf.addImages(_ contents:[AWSContent])
            }
        }
    }
    
    func addImages(contents:[AWSContent]) {
        os_log("Adding images to recipes", log: OSLog.default, type: .debug)
        if let contents = self.contents, contents.count > 0 {
            for content in contents {
                if recipes.count > 0 {
                    let key = FoodImagesDirectoryName + "\(content.key).jpg"
                    if let i = recipes.index(where: { $0.key == key }) {
                        recipe.content = contents[i]
                    }
                } else {
                    let recipe = Recipe()
                    recipe.content = content
                }
            }
        }
    }

    
    func getWorkouts() {
        
    }
    
    
}
