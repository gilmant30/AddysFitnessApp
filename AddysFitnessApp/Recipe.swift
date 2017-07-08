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
    var url: URL?
    var isVideo: Bool = false
    var content: AWSContent!
    {
        didSet {
            print("setting aws content")
            self.content.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.url = url
                if self.content.key.contains(".mp4") {
                    print("url contains mp4")
                    self.isVideo = true
                    let asset = AVURLAsset(url: url as URL)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                
                    let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
                
                    do {
                        let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                    
                        self.image = UIImage(cgImage: imageRef)
                    }
                    catch let error as NSError
                    {
                        print("Image generation failed with error \(error)")
                        return
                    }
                }
                return
            }
        }
    }
    
}


class Ingredients {
    var amount: String?
    var ingredientName: String?
}
