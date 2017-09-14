//
//  DynamoDbWorkouts.swift
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

class DynamoDbWorkouts {
    
    class var shared: DynamoDbWorkouts {
        struct Static {
            static let instance: DynamoDbWorkouts = DynamoDbWorkouts()
        }
        return Static.instance
    }
    
    func formatWorkoutsList(_ objects: [MVPFitObjects]) {
        var workoutsList = [WorkoutVids]()
        for object in objects {
            if object._objectType == "workout" {
                let workout = formatWorkout(object)
                workoutsList.append(workout)
            }
        }
        
        workouts = workoutsList
    }
    
    func formatWorkout(_ object: MVPFitObjects) -> WorkoutVids {
        let workout = WorkoutVids()
        for (key, value) in object._objectInfo! {
            switch key {
            case "workoutName":
                workout.name = value as! String
                if myLikes.contains(where: { $0.title == workout.name }) {
                    print("Workout LIKED - \(workout.name)")
                    workout.liked = true
                }
            case "workoutDescription":
                workout.description = value as! String
            case "videoLength":
                workout.length = value as! String
            case "workoutType":
                workout.workoutType = value as! String
            default:
                break
            }
        }
        return workout
    }    
}
