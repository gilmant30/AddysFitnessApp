//
//  WorkoutLoadingScreenViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/21/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
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

var workouts = [WorkoutVids]()
var workoutsLoaded = false
let WorkoutVideosDirectoryName = "public/workoutVideos/"
private var cellAssociationKey: UInt8 = 0


class WorkoutLoadingScreenViewController: UIViewController{
    var prefix: String!

    fileprivate var manager: AWSUserFileManager!
    fileprivate var identityManager: AWSIdentityManager!
    fileprivate var user: AWSCognitoCredentialsProvider!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!

    override func viewDidLoad() {
        os_log("Opening loading screen for workouts", log: OSLog.default, type: .debug)
        manager = AWSUserFileManager.defaultUserFileManager()
        identityManager = AWSIdentityManager.default()
    }
    
    func getWorkoutDetails(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "workoutIndex"
        queryExpression.keyConditionExpression = "#workoutIndex = :workoutIndex"
        queryExpression.expressionAttributeNames = ["#workoutIndex": "workoutIndex",]
        queryExpression.expressionAttributeValues = [":workoutIndex": "workout",]
        
        objectMapper.query(Workouts.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func loadVideoDetails() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            }
            else if response!.items.count == 0 {
                self.myActivityIndicator.stopAnimating()
            }
            else {
                print("items count - \(response!.items.count)")
                DispatchQueue.main.async {
                    self.loadMoreContents()
                    workoutsLoaded = true
                }
                DispatchQueue.main.async {
                    self.formatVideoDetails(response)
                }
            }
        }
        
        if(!workoutsLoaded || refresh) {
            os_log("loading videoDetails content", log: OSLog.default, type: .debug)
            self.getWorkoutDetails(completionHandler)
            os_log("after loading videoDetails content", log: OSLog.default, type: .debug)
        } else {
            os_log("workouts already loaded", log: OSLog.default, type: .debug)
            self.myActivityIndicator.stopAnimating()
            self.workoutsSearchResults = workouts
            updateUserInterface()
        }
    }

    
}
