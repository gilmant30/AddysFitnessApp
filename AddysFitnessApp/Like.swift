//
//  Like.swift
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

class Like {
    var title: String = ""
    var imgUrl: URL?
    var img: UIImage?
    var createdDate: String = ""
    var type: String = ""
    
    var imageContent: AWSContent! {
        didSet {
            self.imageContent.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.imgUrl = url
                return
            }
            
        }
    }
    
    
}
