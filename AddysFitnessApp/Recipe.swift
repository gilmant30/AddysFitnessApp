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
    
}


class Ingredients {
    var amount: String?
    var ingredientName: String?
}
