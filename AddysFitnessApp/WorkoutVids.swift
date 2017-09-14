//
//  WorkoutVids.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/3/17.
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

class WorkoutVids {
    var name: String?
    var description: String?
    var length: String?
    var previewImage: UIImage?
    var imageUrl: URL?
    var vidUrl: URL?
    var vidPrefix: String?
    var imgPrefix: String?
    var workoutType: String?
    var liked: Bool = false
    
    var imageContent: AWSContent! {
        didSet {
            os_log("workouts setting image content", log: OSLog.default, type: .debug)
            self.imageContent.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.imageUrl = url
                return
            }

        }
    }
    
    var vidContent: AWSContent! {
        didSet {
            os_log("workouts setting video content", log: OSLog.default, type: .debug)
            self.vidContent.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.vidUrl = url
                return
            }
        }
    }
    
    
    
}
