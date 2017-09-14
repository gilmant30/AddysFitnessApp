//
//  NewsFeed.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/5/17.
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

class NewsFeed {
    var title: String?
    var url: String?
    var imageUrl: String?
    var image: UIImage?
    var description: String?
    var canonicalUrl: String?
    var finalUrl: String?
}
