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
    var manager: AWSUserFileManager!
    fileprivate var identityManager: AWSIdentityManager!

    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var workoutTitle: UILabel!
    let screenSize = UIScreen.main.bounds
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var workoutDescriptionText: UITextView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    var workout: WorkoutVids!
    var player: AVPlayer!
    var avpController: AVPlayerViewController!
    
    @IBOutlet weak var likeView: UIView!
    @IBOutlet weak var likeButton: UIImageView!
    
    override func viewDidLoad() {
        identityManager = AWSIdentityManager.default()
        manager = AWSUserFileManager.defaultUserFileManager()
        super.viewDidLoad()
        setupLikeButton()
        
        appDelegate.shouldRotate = true // or false to disable rotation
        
        videoPlayerView.frame = CGRect(x: 1, y: -20, width: screenSize.width - 2, height: screenSize.height/3 * 2)
        
        if let url = workout.vidUrl {
            player = AVPlayer(url: url)
            avpController = AVPlayerViewController()
            avpController.player = player
            avpController.view.frame = videoPlayerView.frame
            self.addChildViewController(avpController)
            self.videoPlayerView.addSubview(avpController.view)
            player.play()
        } else if let content = workout.vidContent {
            print("vidContent is not empty")
            content.getRemoteFileURL {
                (url: URL?, error: Error?) in
                guard let url = url else {
                    print("Error getting URL for file. \(String(describing: error))")
                    return
                }
                self.workout.vidUrl = url
                self.player = AVPlayer(url: url)
                self.avpController = AVPlayerViewController()
                self.avpController.player = self.player
                self.avpController.view.frame = self.videoPlayerView.frame
                self.addChildViewController(self.avpController)
                self.videoPlayerView.addSubview(self.avpController.view)
                self.player.play()
                return
            }
        }
        
        workoutDescriptionText.isEditable = false
        workoutDescriptionText.text = workout.description
        
        workoutTitle.text = workout.name
        
        addEditButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        appDelegate.shouldRotate = false
    }
    
    func addEditButton() {
        if let username = identityManager.identityProfile?.userName {
            if admin.contains(username) {
                os_log("add edit button", log: OSLog.default, type: .debug)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(WorkoutDetailViewController.editWorkout(_:)))
            }
        } else {
            os_log("not an admin", log: OSLog.default, type: .debug)
            
        }
    }
    
    func editWorkout(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
        let uploadWorkoutViewController = storyboard.instantiateViewController(withIdentifier: "UploadWorkouts") as! UploadWorkoutsViewController
        uploadWorkoutViewController.isEdit = true
        uploadWorkoutViewController.editWorkout = workout
        self.navigationController!.pushViewController(uploadWorkoutViewController, animated: true)
    }
    
    func animateButton() {
        let animatedLike = UIImageView()
        animatedLike.frame = likeView.frame
        if workout.liked {
            animatedLike.image = UIImage(named: "like")
        } else {
            animatedLike.image = UIImage(named: "liked")
        }
        self.view.addSubview(animatedLike)
        self.view.bringSubview(toFront: animatedLike)
        UIView.animate(withDuration: 0.5, animations: {
            if self.workout.liked {
                self.likeButton.image = UIImage(named: "like")
            } else {
                self.likeButton.image = UIImage(named: "liked")
            }
        })
        animatedLike.fadeOutLikeButton(completion: {_ in
            animatedLike.removeFromSuperview()
        })
    }
    
    func likeWorkout() {
        animateButton()
        
        let myLike: MyLikes! = MyLikes()
        myLike._userId = AWSIdentityManager.default().identityId!
        myLike._name = workout.name
        if let imgUrl = workout.imageUrl {
            myLike._imageUrl = "\(imgUrl)"
        }
        myLike._type = "workout"
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        myLike._createdDate = result
        
        if workout.liked {
         DynamoDbMyLikes.shared.removeMyLike(myLike){(errors: [NSError]?) -> Void in
             os_log("removed from sql", log: OSLog.default, type: .debug)
                 if errors != nil {
                 print("Error")
                 } else {
                    if let index = myLikes.index(where: {$0.title == myLike._name}) {
                        myLikes.remove(at: index)
                    }
                }
            }
         } else {
         DynamoDbMyLikes.shared.insertMyLike(myLike){(errors: [NSError]?) -> Void in
             os_log("Inserted into sql", log: OSLog.default, type: .debug)
                 if errors != nil {
                    print("Error")
                 } else {
                    let like = DynamoDbMyLikes.shared.formatOneLike(myLike)
                    like.img = self.workout.previewImage
                    myLikes.append(like)
                }
             }
         
         }
        workout.liked = !workout.liked
    }
    
    func setupLikeButton() {
        let tapLikeButton = UITapGestureRecognizer(target: self, action: #selector(self.likeWorkout))
        tapLikeButton.numberOfTapsRequired = 1
        likeButton.isUserInteractionEnabled = true
        likeButton.addGestureRecognizer(tapLikeButton)
        if workout.liked {
            os_log("setting like button", log: OSLog.default, type: .debug)
            DispatchQueue.main.async {
                self.likeButton.image = UIImage(named: "liked")
            }
        }
    }
    
}
