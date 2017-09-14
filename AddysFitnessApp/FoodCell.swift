//
//  FoodViewCell.swift
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

class FoodCell: UITableViewCell {
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var playButtonOverlay: UIImageView!
    
    var content: Recipe! {
        didSet {
            cellName.text = content.name
            if let url = content.imageUrl {
                if let image = content.image {
                    cellImage.image = image
                    cellImage.layer.cornerRadius = 8
                } else {
                    DispatchQueue.global(qos: .default).async {
                        //os_log("recipe url is set", log: OSLog.default, type: .debug)
                        let imageData = NSData(contentsOf: url)
                        if let imageDat = imageData {
                            let image = UIImage(data: imageDat as Data)
                            self.content.image = image
                            DispatchQueue.main.async(execute: {() -> Void in
                                // Main thread stuff.
                                os_log("Image gotten from URL set food", log: OSLog.default, type: .debug)
                                self.cellImage.image = image
                                self.cellImage.layer.cornerRadius = 8
                            })
                        }
                        
                    }
                }
            }
        }
    }
}
