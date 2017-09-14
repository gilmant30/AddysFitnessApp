//
//  S3Workouts.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/26/17.
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

class S3Workouts {
    var awsManager: AWSUserFileManager!
    var marker: String?
    var didLoadAllImages: Bool = false
    
    class var shared: S3Workouts {
        struct Static {
            static let instance: S3Workouts = S3Workouts()
        }
        return Static.instance
    }
}
