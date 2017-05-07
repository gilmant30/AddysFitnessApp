//
//  WorkoutDetailViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 5/1/17.
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

class WorkoutDetailViewController: UIViewController {
    
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var workoutDescription: UILabel!
    @IBOutlet weak var workoutTitle: UILabel!
    let screenSize = UIScreen.main.bounds
    
    var workout: WorkoutVids!
    var player: AVPlayer!
    var avpController: AVPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.shouldRotate = true // or false to disable rotation
        
        videoPlayerView.frame = CGRect(x: 1, y: -20, width: screenSize.width - 2, height: screenSize.height/3 * 2)
        
        if let url = workout.url {
            player = AVPlayer(url: url)
            avpController = AVPlayerViewController()
            avpController.player = player
            avpController.view.frame = videoPlayerView.frame
            self.addChildViewController(avpController)
            self.videoPlayerView.addSubview(avpController.view)
            player.play()
        }
        
        workoutTitle.text = workout.name
        workoutDescription.numberOfLines = 0
        workoutDescription.lineBreakMode = .byWordWrapping
        workoutDescription.text = workout.description
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
}
