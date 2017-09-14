//
//  MyLikesViewController.swift
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

import ObjectiveC

var myLikes = [Like]()
var likesLoaded: Bool = false

class MyLikesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var mainViewImage: UIImageView!
    @IBOutlet weak var mainViewTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewDetailButton: UIButton!
    var getLikesStatus: String?
    var selectedLike: Like? = nil
    var awsManager: AWSUserFileManager!
    var marker: String?
    var didLoadAllWorkoutImages: Bool?
    var didLoadAllFoodImages: Bool?
    var refresh: Bool = false
    var activityIndicator = UIActivityIndicatorView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.layer.borderColor = UIColor.lightGray.cgColor
        mainView.layer.borderWidth = 0.5
        self.navigationItem.title = "MyLikes"
        awsManager = AWSUserFileManager.defaultUserFileManager()
        setupViewDetailButton()
        activityIndicator.frame = CGRect(x:0, y:0, width:40, height:40)
        activityIndicator.color = UIColor.red
        activityIndicator.center = CGPoint(x: self.view.bounds.width / 2, y:self.view.bounds.height / 2)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LoadingOverlay.shared.displayOverlay()
        if !likesLoaded {
            os_log("MyLikes - View wil appear likes not loaded", log: OSLog.default, type: .debug)
            getLikes()
        } else {
            self.updateUserInterface()
            DispatchQueue.main.async {
                LoadingOverlay.shared.removeOverlay()
            }
        }
    }
    
    func updateUserInterface() {
        self.displayMainView()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func displayMainView() {
        DispatchQueue.main.async {
            var like = Like()
            if let selected = self.selectedLike {
                like = selected
            } else if myLikes.count > 0 {
                like = myLikes[0]
            }
            
            self.mainViewTitle.text = like.title
            if let url = like.imgUrl {
                if let image = like.img {
                    self.mainViewImage.image = image
                } else {
                    DispatchQueue.global(qos: .default).async {
                        let imageData = NSData(contentsOf: url)
                        if let imageDat = imageData {
                            let image = UIImage(data: imageDat as Data)
                            like.img = image
                            DispatchQueue.main.async(execute: {() -> Void in
                                // Main thread stuff.
                                self.mainViewImage.image = image
                            })
                        }
                        
                    }
                }
            }
        }
    }
    
    func getLikes() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                    print("\(errorMessage)")
                }
            }
            else {
                let group = DispatchGroup()
                os_log("MyLikesViewController - getLikes() group start", log: OSLog.default, type: .debug)

                
                group.enter()
                if myLikes.count == 0 {
                    let response = response?.items as! [MyLikes]
                    myLikes = DynamoDbMyLikes.shared.formatLikes(response)
                }
                group.leave()
                
                group.enter()
                    self.loadS3WorkoutContents()
                group.leave()
                
                group.enter()
                    self.loadS3FoodContents()
                group.leave()
                group.wait()
                likesLoaded = true
                if self.selectedLike == nil {
                    self.selectedLike = myLikes[0]
                    self.displayMainView()
                }
            }
            
            DispatchQueue.main.async(execute: {
                LoadingOverlay.shared.removeOverlay()
            })
            self.updateUserInterface()
            
            
        }
        
        DynamoDbMyLikes.shared.getMyLikes(completionHandler)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myLikes.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedLike = myLikes[indexPath.row]
        self.displayMainView()
    }
    
    func setupViewDetailButton() {
        let tapViewDetailButton = UITapGestureRecognizer(target: self, action: #selector(self.goToDetail))
        tapViewDetailButton.numberOfTapsRequired = 1
        viewDetailButton.isUserInteractionEnabled = true
        viewDetailButton.addGestureRecognizer(tapViewDetailButton)

    }
    
    func goToDetail() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                    print("\(errorMessage)")
                }
            }
            else {
                os_log("Getting mvpFitObjects", log: OSLog.default, type: .debug)
                let response = response?.items as! [MVPFitObjects]
                mvpFitObjects = response
                DynamoDbMVPFitObjects.shared.mapObjects()
                
                self.addS3RecipeContent{() -> () in
                    self.addS3WorkoutContent{() -> () in
                        self.sendToDetailStoryboard()
                    }
                }
            }
            
        }

        activityIndicator.startAnimating()
        
        if mvpFitObjects.count == 0 {
            DynamoDbMVPFitObjects.shared.getMvpFitObjects(refresh, completionHandler)
        } else {
            sendToDetailStoryboard()
        }
    }
    
    func addS3RecipeContent(completion: @escaping () -> ()) {
        if !foodS3Loaded {
            os_log("RECIPES - adding S3 content", log: OSLog.default, type: .debug)
            if recipes.count > 0 {
                if recipeAWSContent.count > 0 {
                    for recipe in recipes {
                        let vidKey = FoodS3DirectoryName + recipe.name + ".mp4"
                        let imageKey = FoodS3DirectoryName + recipe.name + ".jpg"
                        if let i = recipeAWSContent.index(where: { $0.key == vidKey }) {
                            recipe.videoContent = recipeAWSContent[i]
                        }
                        if let i = recipeAWSContent.index(where: { $0.key == imageKey }) {
                            recipe.imageContent = recipeAWSContent[i]
                        }
                    }
                }
            }
            foodS3Loaded = true
        }
        completion()
    }
    
    func addS3WorkoutContent(completion: @escaping () -> ()) {
        os_log("WORKOUT - adding S3 content", log: OSLog.default, type: .debug)
        if !workoutS3Loaded {
            if workouts.count > 0 {
                if workoutAWSContent.count > 0 {
                    for workout in workouts {
                        if let name = workout.name {
                            let vidKey = WorkoutS3DirectoryName + name + ".mp4"
                            let imageKey = WorkoutS3DirectoryName + name + ".jpg"
                            if let i = workoutAWSContent.index(where: { $0.key == vidKey }) {
                                workout.vidContent = workoutAWSContent[i]
                            }
                            if let i = workoutAWSContent.index(where: { $0.key == imageKey }) {
                                workout.imageContent = workoutAWSContent[i]
                            }
                        }
                    }
                }
            }
            workoutS3Loaded = true
        }
        completion()
    }

    
    func sendToDetailStoryboard() {
        if let like = selectedLike {
            if like.type == "workout" {
                var workout = WorkoutVids()
                if let i = workouts.index(where: { $0.name == like.title}) {
                    workout = workouts[i]
                    workout.previewImage = like.img
                }
                os_log("Sending to Workout Details storyboard", log: OSLog.default, type: .debug)
                let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
                let detailController = storyboard.instantiateViewController(withIdentifier: "workoutDetail") as! WorkoutDetailViewController
                detailController.workout = workout
                activityIndicator.stopAnimating()
                print("vidurl - \(workout.vidUrl)")
                self.navigationController!.pushViewController(detailController, animated: true)
            } else if like.type == "recipe" {
                var recipe = Recipe()
                if let i = recipes.index(where: { $0.name == like.title}) {
                    recipe = recipes[i]
                    recipe.image = like.img
                }
                
                os_log("Sending to Food Details storyboard", log: OSLog.default, type: .debug)
                let storyboard = UIStoryboard(name: "Food", bundle: nil)
                let detailController = storyboard.instantiateViewController(withIdentifier: "recipeDetailView") as! RecipeDetailViewController
                detailController.recipe = recipe
                detailController.isVideo = recipe.isVideo
                activityIndicator.stopAnimating()
                self.navigationController!.pushViewController(detailController, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MyLikesCell = tableView.dequeueReusableCell(withIdentifier: "myLikesCell") as! MyLikesCell
        
        let myLike = myLikes[indexPath.row]
        cell.Title.text = myLike.title
        cell.cellImage.layer.cornerRadius = 10
        
        if let url = myLike.imgUrl {
            if let image = myLike.img {
                cell.cellImage.image = image
            } else {
                DispatchQueue.global(qos: .default).async {
                    let imageData = NSData(contentsOf: url)
                    if let imageDat = imageData {
                        let image = UIImage(data: imageDat as Data)
                        myLike.img = image
                        DispatchQueue.main.async(execute: {() -> Void in
                            // Main thread stuff.
                            cell.cellImage.image = image
                        })
                    }
                    
                }
            }
        }
        return cell
    }
    
    func loadS3FoodContents() {
        if recipeAWSContent.count == 0 {
            print("loading S3Content food")
            if let manager = awsManager {
                    manager.listAvailableContents(withPrefix: FoodS3DirectoryName, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            print("Failed to load the list of contents. \(error)")
                        }
                        if let contents = contents, contents.count > 0 {
                            if let nextMarker = nextMarker, !nextMarker.isEmpty {
                                strongSelf.didLoadAllFoodImages = false
                            } else {
                                strongSelf.didLoadAllFoodImages = true
                            }
                            strongSelf.marker = nextMarker
                            if strongSelf.didLoadAllFoodImages! {
                                print("DynamoDb food image content count - \(contents.count)")
                                recipeAWSContent = contents
                                DynamoDbMyLikes.shared.formatLikesWithImage("food")
                            }
                        }
                        
                        strongSelf.updateUserInterface()
                    }
            } else {
                print("ERROR with manager")
            }
        } else {
            DynamoDbMyLikes.shared.formatLikesWithImage("food")
        }
    }
    
    func loadS3WorkoutContents() {
        if workoutAWSContent.count == 0 {
            if let manager = awsManager {
                manager.listAvailableContents(withPrefix: WorkoutS3DirectoryName, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
                    guard let strongSelf = self else { return }
                    if let error = error {
                        print("Failed to load the list of contents. \(error)")
                    }
                    if let contents = contents, contents.count > 0 {
                        if let nextMarker = nextMarker, !nextMarker.isEmpty {
                            strongSelf.didLoadAllWorkoutImages = false
                        } else {
                            strongSelf.didLoadAllWorkoutImages = true
                        }
                        strongSelf.marker = nextMarker
                        if strongSelf.didLoadAllWorkoutImages! {
                            print("DynamoDb workout image content count - \(contents.count)")
                            workoutAWSContent = contents
                            DynamoDbMyLikes.shared.formatLikesWithImage("workout")
                        }
                    }
                    
                    strongSelf.updateUserInterface()
                }
            } else {
                print("ERROR with manager")
            }
        } else {
            DynamoDbMyLikes.shared.formatLikesWithImage("workout")
        }
    }

    
}

class MyLikesCell: UITableViewCell {
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var Title: UILabel!
    
}
