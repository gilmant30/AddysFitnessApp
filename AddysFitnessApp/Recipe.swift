//
//  Recipe.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/24/17.
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

class Recipe {
    var name: String = ""
    var description: String = ""
    var ingredients: [Ingredients] = []
    var steps: [String] = []
    var image: UIImage?
    var category: String = ""
    var imageUrl: URL?
    var videoUrl: URL?
    var isVideo: Bool = false
    var liked: Bool = false
    var imageContent: AWSContent!
    {
        didSet {
            print("setting recipe image content")
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
    
    var videoContent: AWSContent! {
        didSet {
            self.isVideo = true
            print("setting recipe video content")
            self.videoContent.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.videoUrl = url
                return
            }
        }
    }
}


class Ingredients {
    var amount: String?
    var ingredientName: String?
}
