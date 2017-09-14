//
//  LoadingOverlay.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/25/17.
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

public class LoadingOverlay{

    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    func displayOverlay(_ displayText: String = "") {
        if  let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let window = appDelegate.window {
            os_log("display overlay", log: OSLog.default, type: .debug)
            let window = UIApplication.shared.keyWindow!
            let imageNum = arc4random_uniform(8)
            print("Image num = \(imageNum)")
            let image = UIImage(named: "loadingImage\(imageNum)")
            overlayView = UIImageView(image: image!)
            overlayView.frame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height)
            overlayView.contentMode = .scaleAspectFill
            activityIndicator.frame = CGRect(x:0, y:0, width:40, height:40)
            activityIndicator.activityIndicatorViewStyle = .whiteLarge
            activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y:overlayView.bounds.height / 2)
            activityIndicator.hidesWhenStopped = true
            overlayView.addSubview(activityIndicator)
            
            if displayText != "" {
                let label = UILabel()
                label.frame = CGRect(x:0, y:0, width: 200, height: 100)
                label.adjustsFontSizeToFitWidth = true
                label.text = displayText
                label.textColor = UIColor.white
                label.center = CGPoint(x: overlayView.bounds.width / 2, y:((overlayView.bounds.height / 2) + 50))
                overlayView.addSubview(label)
            }
            activityIndicator.startAnimating()
            window.addSubview(overlayView)
        }
    }
    
    func removeOverlay() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
    
    
}
