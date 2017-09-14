//
//  NewsFeedCell.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/8/17.
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

class NewsFeedCell: UITableViewCell {
    @IBOutlet weak var feedImage: UIImageView!
    @IBOutlet weak var feedTitle: UILabel!
    @IBOutlet weak var feedUrl: UILabel!
    
    var article: NewsFeed! {
        didSet {
            if let url = article.canonicalUrl {
                self.feedUrl.text = url
            } else {
                self.feedUrl.text = "Error"
            }
            if let title = article.title {
                self.feedTitle.text = title
            } else {
                self.feedTitle.text = "Title"
            }
            if let urlString = article.imageUrl {
                if let image = article.image {
                    self.feedImage.image = image
                } else {
                    DispatchQueue.global(qos: .default).async {
                        //os_log("recipe url is set", log: OSLog.default, type: .debug)
                        let url = URL(string: urlString)
                        let imageData = NSData(contentsOf: url!)
                        if let imageDat = imageData {
                            let image = UIImage(data: imageDat as Data)
                            self.article.image = image
                            DispatchQueue.main.async(execute: {() -> Void in
                                // Main thread stuff.
                                self.feedImage.image = image
                            })
                        }
                        
                    }
                }
            }
            

        }
    }

}
