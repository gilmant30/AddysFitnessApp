//
//  S3Workouts.swift
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

class S3Profile {
    var awsManager: AWSUserFileManager!
    let imgPrefix: String = "\(ProfileImagesDirectoryName)"
    var marker: String?
    var didLoadAllImages: Bool = false
    let identityManager = AWSIdentityManager.default()
    
    class var shared: S3Profile {
        struct Static {
            static let instance: S3Profile = S3Profile()
        }
        return Static.instance
    }
    
    func loadImageContents() {
        let key = "\(ProfileImagesDirectoryName)\(identityManager.identityId).jpg"
        os_log("S3Profile - loadImageContents Start", log: OSLog.default, type: .debug)
        awsManager = AWSUserFileManager.defaultUserFileManager()
        if let manager = awsManager {
            os_log("S3Profile - loadImageContnets Middle", log: OSLog.default, type: .debug)
            manager.listAvailableContents(withPrefix: imgPrefix, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
                guard let strongSelf = self else { return }
                if let error = error {
                    print("Failed to load the list of contents. \(error)")
                }
                if let contents = contents, contents.count > 0 {
                    if let nextMarker = nextMarker, !nextMarker.isEmpty {
                        strongSelf.didLoadAllImages = false
                    } else {
                        strongSelf.didLoadAllImages = true
                    }
                    strongSelf.marker = nextMarker
                    if strongSelf.didLoadAllImages {
                        print("S3Profile image content count - \(contents.count)")
                        profileImageLoaded = true
                        if let i = contents.index(where: {$0.key == key} ) {
                            profileImageContents = contents[i]
                            return
                        }
                    }
                } else {
                    print("no profile image yet")
                }
            }
        } else {
            print("ERROR with manager")
        }
    }
}
