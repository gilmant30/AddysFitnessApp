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
    var url: URL?
    var prefix: String?
    var workoutType: String?
    
    var content: AWSContent! {
        didSet {
            self.content.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.url = url
                /*
                let asset = AVURLAsset(url: url as URL)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
                
                do {
                    let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                    
                    self.previewImage = UIImage(cgImage: imageRef)
                }
                catch let error as NSError
                {
                    print("Image generation failed with error \(error)")
                    return
                }
                 */
                return
            }

        }
    }
    
    
    
}
