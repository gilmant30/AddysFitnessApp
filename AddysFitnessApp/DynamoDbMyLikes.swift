//
//  LoadMyLikes.swift
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

class DynamoDbMyLikes {
    let workoutPrefix = "\(WorkoutS3DirectoryName)"
    let foodPrefix = "\(FoodS3DirectoryName)"
    
    class var shared: DynamoDbMyLikes {
        struct Static {
            static let instance: DynamoDbMyLikes = DynamoDbMyLikes()
        }
        return Static.instance
    }
    
    func formatLikes(_ myLikes: [MyLikes]) -> [Like] {
        os_log("Formatting myLike", log: OSLog.default, type: .debug)
        var likes = [Like]()
        for myLike in myLikes {
            let like: Like = formatOneLike(myLike)
            likes.append(like)
        }
        
        return likes
    }
    
    func formatOneLike(_ myLike: MyLikes) -> Like {
        let like: Like = Like()
        like.title = myLike._name!
        like.createdDate = myLike._createdDate!
        like.type = myLike._type!
        like.imgUrl = URL(fileURLWithPath: myLike._imageUrl!)
        
        return like
    }
    
    func formatLikesWithImage(_ type: String) {
        os_log("formatLikesWithImage", log: OSLog.default, type: .debug)
        if type == "workout" {
            if workoutAWSContent.count > 0 {
                for like in myLikes {
                    let key = workoutPrefix + like.title + ".jpg"
                    if let i = workoutAWSContent.index(where: { $0.key == key }) {
                        like.imageContent = workoutAWSContent[i]
                    }
                }
            }
        } else {
            if recipeAWSContent.count > 0 {
                for like in myLikes {
                    let key = foodPrefix + like.title + ".jpg"
                    if let i = recipeAWSContent.index(where: { $0.key == key }) {
                        like.imageContent = recipeAWSContent[i]
                    }
                }
            }
        }
    }
    
    func getMyLikes(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        if myLikes.count == 0 {
            let objectMapper = AWSDynamoDBObjectMapper.default()
            let queryExpression = AWSDynamoDBQueryExpression()
            
            queryExpression.keyConditionExpression = "#userId = :userId"
            queryExpression.expressionAttributeNames = ["#userId": "userId",]
            queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.default().identityId!,]
            
            objectMapper.query(MyLikes.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
                DispatchQueue.main.async(execute: {
                    completionHandler(response, error as NSError?)
                })
            }
        } else {
            completionHandler(nil, nil)
        }
    }
    
    func removeMyLike(_ likes:MyLikes, _ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        os_log("Removing like from sql", log: OSLog.default, type: .debug)
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        
        group.enter()
        
        objectMapper.remove(likes, completionHandler: {(error: Error?) -> Void in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    errors.append(error)
                })
            } else {
                if let i = myLikes.index(where: {$0.title == likes._name}) {
                    myLikes.remove(at: i)
                }
            }
            group.leave()
        })
        
        group.notify(queue: DispatchQueue.main, execute: {
            if errors.count > 0 {
                completionHandler(errors)
            }
            else {
                completionHandler(nil)
            }
        })
    }
    

    
    func insertMyLike(_ likes:MyLikes, _ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        os_log("Inserting like into sql", log: OSLog.default, type: .debug)
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        
        group.enter()
        
        objectMapper.save(likes, completionHandler: {(error: Error?) -> Void in
            if let error = error as NSError? {
                DispatchQueue.main.async(execute: {
                    errors.append(error)
                })
            } 
            group.leave()
        })
        
        group.notify(queue: DispatchQueue.main, execute: {
            if errors.count > 0 {
                completionHandler(errors)
            }
            else {
                completionHandler(nil)
            }
        })
    }

    
}
