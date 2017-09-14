//
//  ViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
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

var admin = ["mvpfitadmin2", "addysonwilgus15", "gilmant30"]
var insertedNewLikes: Bool = false
var mvpFitObjects = [MVPFitObjects]()
let mvpApp = "MVPFit"
var loadMvpFitObject: Bool = false

class InitialViewController: UIViewController {
    
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var willEnterForegroundObserver: AnyObject!
    fileprivate let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    fileprivate let profileButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    var activityIndicator = UIActivityIndicatorView()
    
    
    @IBOutlet weak var foodIcon: UIImageView!
    @IBOutlet weak var workoutIcon: UIImageView!
    @IBOutlet weak var equipmentIcon: UIImageView!
    @IBOutlet weak var newsFeedIcon: UIImageView!
    @IBOutlet weak var myLikesIcon: UIImageView!
    @IBOutlet weak var shoppingIcon: UIImageView!
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textAttributes = [NSForegroundColorAttributeName:UIColor.red]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        activityIndicator.frame = CGRect(x:0, y:0, width:40, height:40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: self.view.bounds.width / 2, y:self.view.bounds.height / 2)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        os_log("Going to Sign in viewController", log: OSLog.default, type: .debug)
        presentSignInViewController()
        
        // create tapGestureRecognizer for images
        let tapWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleWorkoutIconTapped))
        let tapFoodsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleFoodIconTapped))
        let tapEquipmentGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleEquipmentIconTapped))
        let tapNewsFeedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleNewsFeedIconTapped))
        let tapMyLikesGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleMyLikesIconTapped))
        let tapShoppingGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleShoppingIconTapped))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapFoodsGestureRecognizer.numberOfTapsRequired = 1
        tapEquipmentGestureRecognizer.numberOfTapsRequired = 1
        tapNewsFeedGestureRecognizer.numberOfTapsRequired = 1
        tapMyLikesGestureRecognizer.numberOfTapsRequired = 1
        tapShoppingGestureRecognizer.numberOfTapsRequired = 1
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
        workoutIcon.isUserInteractionEnabled = true
        workoutIcon.addGestureRecognizer(tapWorkoutsGestureRecognizer)
        foodIcon.isUserInteractionEnabled = true
        foodIcon.addGestureRecognizer(tapFoodsGestureRecognizer)
        equipmentIcon.isUserInteractionEnabled = true
        equipmentIcon.addGestureRecognizer(tapEquipmentGestureRecognizer)
        newsFeedIcon.isUserInteractionEnabled = true
        newsFeedIcon.addGestureRecognizer(tapNewsFeedGestureRecognizer)
        myLikesIcon.isUserInteractionEnabled = true
        myLikesIcon.addGestureRecognizer(tapMyLikesGestureRecognizer)
        shoppingIcon.isUserInteractionEnabled = true
        shoppingIcon.addGestureRecognizer(tapShoppingGestureRecognizer)
        
        setupRightBarButtonItem()
        setupProfileBarButtonItem()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(signInObserver)
        NotificationCenter.default.removeObserver(signOutObserver)
        NotificationCenter.default.removeObserver(willEnterForegroundObserver)
    }
    
    func handleWorkoutIconTapped() {
        os_log("Sending to workouts storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WorkoutsView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func handleFoodIconTapped() {
        os_log("Sending to Food storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "Food", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FoodView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func handleEquipmentIconTapped() {
        self.showSimpleAlertWithTitle("Equipment!", message: "Equipment Info Coming Soon", cancelButtonTitle: "OK")
    }
    
    func handleNewsFeedIconTapped() {
        os_log("Sending to NewsFeed storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "NewsFeed", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NewsFeedView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func handleMyLikesIconTapped() {
        os_log("Sending to MyLikes storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "MyLikes", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MyLikesView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func handleShoppingIconTapped() {
        self.showSimpleAlertWithTitle("Shopping!", message: "Shopping Info Coming Soon", cancelButtonTitle: "OK")
    }
    
    func setupProfileBarButtonItem() {
        navigationItem.leftBarButtonItem = profileButton
        navigationItem.leftBarButtonItem!.target = self
        
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            let image = UIImage(named: "profile")
            let imageView = UIImageView(image: image!)
            let bannerWidth = (navigationController?.navigationBar.frame.size.width)! / 6
            let bannerHeight = navigationController?.navigationBar.frame.size.height
            let bannerx = bannerWidth / 2 - image!.size.width / 2
            let bannery = bannerHeight! / 2 - image!.size.height / 2
            imageView.frame = CGRect(x: bannerx, y: bannery, width: bannerWidth, height: bannerHeight!)
            imageView.contentMode = UIViewContentMode.scaleAspectFit
            let leftBarButton = UIBarButtonItem(customView: imageView)
            leftBarButton.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(InitialViewController.sendtoProfile)))
            navigationItem.leftBarButtonItem = leftBarButton
        }
    }
    
    func setupRightBarButtonItem() {
        navigationItem.rightBarButtonItem = loginButton
        navigationItem.rightBarButtonItem!.target = self
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            navigationItem.rightBarButtonItem!.action = #selector(InitialViewController.handleLogout)
        }

    }
    
    func presentSignInViewController() {
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            self.present(viewController, animated: true, completion: nil)
        } else {
            activityIndicator.startAnimating()
            getMyLikes()
        }
    }
    
    func getMyLikes() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                    print("\(errorMessage)")
                }
            }
            else {
                if myLikes.count > 0 || response != nil {
                    let response = response?.items as! [MyLikes]
                    myLikes = DynamoDbMyLikes.shared.formatLikes(response)
                }
                
            }
            self.activityIndicator.stopAnimating()
        }
        
        DynamoDbMyLikes.shared.getMyLikes(completionHandler)
    }

    
    
    
    func handleLogout() {
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, authState: AWSIdentityManagerAuthState, error: Error?) in
                self.navigationController!.popToRootViewController(animated: false)
                self.setupRightBarButtonItem()
                self.presentSignInViewController()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
        } else {
            assert(false)
        }
    }
    
    func sendtoProfile() {
        os_log("Sending to Profile storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "profileView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

}
