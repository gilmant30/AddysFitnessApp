//
//  WorkoutsViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/21/17.
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

var workouts = [WorkoutVids]()
var workoutAWSContent: [AWSContent] = [AWSContent]()
var workoutS3Loaded = false
let WorkoutS3DirectoryName = "public/workoutS3/"
let workoutObjectType = "workout"

class WorkoutsViewController: UITableViewController, UISearchResultsUpdating {
    var s3Prefix: String!
    
    //var vidDetails: [Workouts] = [Workouts]()
    var workoutsSearchResults: [WorkoutVids]?
    var selected: String!
    var loadedDetails: Bool = false
    var searchController: UISearchController!
    var workoutTypes: [UIImage] = []
    var refresh = false
    var overlay: UIImageView?

    
    fileprivate var manager: AWSUserFileManager!
    fileprivate var identityManager: AWSIdentityManager!
    fileprivate var user: AWSCognitoCredentialsProvider!
    fileprivate var videoContents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var marker: String?
    fileprivate var didLoadAllVideos: Bool!
    fileprivate var didLoadAllImages: Bool!
    let screenSize = UIScreen.main.bounds
    let upper = UIImageView()
    let lower = UIImageView()
    let total = UIImageView()
    let fit = UIImageView()
    
    
    let myActivityIndicator = UIActivityIndicatorView()
    
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        print("workouts count is - \(workouts.count)")
        super.viewDidLoad()
        self.tableView.delegate = self
        manager = AWSUserFileManager.defaultUserFileManager()
        identityManager = AWSIdentityManager.default()
        configureSearchController()
        self.tableView.estimatedSectionHeaderHeight = 75
        self.tableView.sectionHeaderHeight = 75
        
        // Sets up the UIs.
        checkIfAdmin()
        navigationItem.title = "MVPFit Workouts"
        // Sets up the date formatter.
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        didLoadAllVideos = false
        didLoadAllImages = false
        refresh = false
        
        self.loadWorkouts()
    
        selected = "workoutVideo"
        
        self.refreshControl?.addTarget(self, action: #selector(WorkoutsViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.backgroundColor = UIColor.white
        
         // no lines where there aren't cells
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
    
    func checkIfAdmin() {
        if let username = identityManager.identityProfile?.userName {
            print("Username is - \(username)")
            if admin.contains(username) {
                os_log("is an admin", log: OSLog.default, type: .debug)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(WorkoutsViewController.showContentManagerActionOptions(_:)))
            }
        } else {
            os_log("not an admin", log: OSLog.default, type: .debug)
           
        }
    }
    
    // MARK - Search Bar
    
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search workouts here..."
        searchController.searchBar.sizeToFit()
        
        // Place the search bar view to the tableview headerview.
        tableView.tableHeaderView = searchController.searchBar
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            workoutsSearchResults = workouts.filter {
                $0.name?.range(of: searchText, options: .caseInsensitive) != nil
            }
        } else {
            workoutsSearchResults = workouts
        }
        updateUserInterface()
    }
    
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        refresh = true

        os_log("handleRefresh", log: OSLog.default, type: .debug)
        
        self.loadWorkouts()
        
        refreshControl.endRefreshing()
    }
    
    func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK:- Content Manager user action methods
    func showContentManagerActionOptions(_ sender: AnyObject) {
        self.myActivityIndicator.startAnimating()
        self.showImagePicker()
    }
    
    func loadWorkouts() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            } else {
                if mvpFitObjects.count > 0 || response != nil {
                    if mvpFitObjects.count == 0 {
                        let response = response?.items as! [MVPFitObjects]
                        mvpFitObjects = response
                        DynamoDbMVPFitObjects.shared.mapObjects()
                    }
                    
                    os_log("workout s3 content started", log: OSLog.default, type: .debug)
                    self.loadS3Content{() -> () in
                        os_log("workout s3 content finished", log: OSLog.default, type: .debug)
                        
                        print("WorkoutAWSContent count - \(workoutAWSContent.count)")
                        for aws in workoutAWSContent {
                            print("key = \(aws.key)")
                        }
                        self.workoutsSearchResults = workouts
                        DispatchQueue.main.async {
                            LoadingOverlay.shared.removeOverlay()
                        }
                        self.updateUserInterface()
                    }
                }
            }
            self.refresh = false
            self.updateUserInterface()
        }
        
        if !refresh {
            LoadingOverlay.shared.displayOverlay()
        }
        

        if workouts.count == 0 || workoutAWSContent.count == 0 || refresh || !workoutS3Loaded {
            os_log("loading S3 and dynamo content", log: OSLog.default, type: .debug)
            DynamoDbMVPFitObjects.shared.getMvpFitObjects(refresh, completionHandler)
        } else {
            os_log("workouts already loaded", log: OSLog.default, type: .debug)
            DispatchQueue.main.async {
                LoadingOverlay.shared.removeOverlay()
            }
            self.workoutsSearchResults = workouts
            updateUserInterface()
        }
    }
    
    func loadS3Content(completion: @escaping () -> ()) {
        if workoutAWSContent.count == 0 || refresh {
            manager.listAvailableContents(withPrefix: WorkoutS3DirectoryName, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
                guard let strongSelf = self else { return }
                if let error = error {
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                    print("Failed to load the list of contents. \(error)")
                    completion()
                }
                if let contents = contents, contents.count > 0 {
                    print("S3 size - \(contents.count)")
                    if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    } else {
                        workoutAWSContent = contents
                        strongSelf.addS3Content{() -> () in
                            completion()
                        }
                    }
                    strongSelf.marker = nextMarker
                }
            }
        } else {
            addS3Content{() -> () in
                completion()
            }
        }
    }
    
    func addS3Content(completion: @escaping () -> ()) {
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
    
    // MARK:- Content uploads
    
    fileprivate func showImagePicker() {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if(section == 0){
            return createTableHeader()
        }
        return nil;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let workoutsArray = workoutsSearchResults else {
            return 0
        }
        return workoutsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WorkoutVideoCell = tableView.dequeueReusableCell(withIdentifier: "WorkoutVideoCell", for: indexPath) as! WorkoutVideoCell
        
        if let workoutsArray = workoutsSearchResults {
            let workout = workoutsArray[indexPath.row]
            cell.prefix = s3Prefix
            cell.content = workout
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 110
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        os_log("Clicked on a workout video", log: OSLog.default, type: .debug)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            os_log("deleting workout", log: OSLog.default, type: .debug)
            presentDeleteVerification((workoutsSearchResults?[indexPath.row])!, tableView, indexPath)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "workoutDetailShow",
            let destination = segue.destination as? WorkoutDetailViewController,
            let workoutIndex = tableView.indexPathForSelectedRow?.row
        {
            destination.workout = (workoutsSearchResults?[workoutIndex])!
        }
    }
    
    func removeContent(_ content: AWSContent) {
        content.removeRemoteContent {[weak self] (content: AWSContent?, error: Error?) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to delete an object from the remote server. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to delete an object from the remote server.", cancelButtonTitle: "OK")
                } else {
                    os_log("Deleted image/video for recipe", log: OSLog.default, type: .debug)
                }
            }
        }
    }
    
    func deleteWorkout(_ workout: WorkoutVids) {
        removeContent(workout.imageContent)
        removeContent(workout.vidContent)
        deleteWorkoutDetails(workout, {(errors: [NSError]?) -> Void in
            os_log("deleting sql", log: OSLog.default, type: .debug)
            if errors != nil {
                self.showSimpleAlertWithTitle("Error", message: "Error deleting recipe", cancelButtonTitle: "OK")
            }
            self.updateUserInterface()
        })
    }
    
    func presentDeleteVerification(_ workout: WorkoutVids, _ tableView: UITableView, _ indexPath: IndexPath) {
        let deleteAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this workout?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.deleteWorkout(workout)
            self.workoutsSearchResults?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            
            os_log("actually deleting workout", log: OSLog.default, type: .debug)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            os_log("Cancelled request for delete", log: OSLog.default, type: .debug)
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteWorkoutDetails(_ workout: WorkoutVids, _ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        os_log("deleting workout sql", log: OSLog.default, type: .debug)
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        
        let deleteWorkout: MVPFitObjects! = MVPFitObjects()
        
        deleteWorkout._objectApp = mvpApp
        deleteWorkout._objectName = workout.name
        deleteWorkout._objectType = workoutObjectType
        
        group.enter()
        
        objectMapper.remove(deleteWorkout, completionHandler: {(error: Error?) -> Void in
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

    deinit {
        self.searchController.view.removeFromSuperview()
    }

}

// MARK:- UIImagePickerControllerDelegate

extension WorkoutsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle Video Uploads
        if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            
            
            let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
            let uploadWorkoutsViewController = storyboard.instantiateViewController(withIdentifier: "UploadWorkouts") as! UploadWorkoutsViewController
            uploadWorkoutsViewController.data = try! Data(contentsOf: videoURL)
            uploadWorkoutsViewController.url = videoURL
            uploadWorkoutsViewController.manager = self.manager
            self.myActivityIndicator.stopAnimating()
            self.navigationController!.pushViewController(uploadWorkoutsViewController, animated: true)
            
            //askForFilename(try! Data(contentsOf: videoURL))
            
        }
    }
}

// MARK: - Utility

extension WorkoutsViewController {
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AWSContent {
    fileprivate func isAudioVideo() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".mov")
            || lowerCaseKey.hasSuffix(".mp4")
            || lowerCaseKey.hasSuffix(".mpv")
            || lowerCaseKey.hasSuffix(".3gp")
            || lowerCaseKey.hasSuffix(".mpeg")
            || lowerCaseKey.hasSuffix(".aac")
            || lowerCaseKey.hasSuffix(".mp3")
    }
    
    fileprivate func isImage() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".jpg")
            || lowerCaseKey.hasSuffix(".png")
            || lowerCaseKey.hasSuffix(".jpeg")
    }
}

extension UInt {
    fileprivate func aws_stringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension String {
    fileprivate func getLastPathComponent() -> String {
        let nsstringValue: NSString = self as NSString
        return nsstringValue.lastPathComponent
    }
}
