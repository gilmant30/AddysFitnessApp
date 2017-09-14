//
//  WorkoutVideoCell.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/10/17.
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


class WorkoutVideoCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var videoLength: UILabel!
    
    var prefix: String?
    
    var content: WorkoutVids! {
        didSet {
            fileNameLabel.text = content.name
            detailLabel.text = content.description
            videoLength.text = content.length
            if let url = content.imageUrl {
                if let image = content.previewImage {
                     os_log("Preview Image set for workout", log: OSLog.default, type: .debug)
                    previewImage.image = image
                } else {
                    DispatchQueue.global(qos: .default).async {
                        //os_log("recipe url is set", log: OSLog.default, type: .debug)
                        let imageData = NSData(contentsOf: url)
                        if let imageDat = imageData {
                            let image = UIImage(data: imageDat as Data)
                            self.content.previewImage = image
                            DispatchQueue.main.async(execute: {() -> Void in
                                // Main thread stuff.
                                 os_log("workout image being set", log: OSLog.default, type: .debug)
                                self.previewImage.image = image
                            })
                        }
                        
                    }
                }
            }
        }
    }
}

