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
var workoutsLoaded = false
let WorkoutVideosDirectoryName = "public/workoutVideos/"
private var cellAssociationKey: UInt8 = 0


class WorkoutsViewController: UITableViewController, UISearchResultsUpdating {
    var prefix: String!
    
    var vidContent: [AWSContent]?
    var vidDetails: [Workouts] = [Workouts]()
    var workoutsSearchResults: [WorkoutVids]?
    var selected: String!
    var loadedDetails: Bool = false
    var searchController: UISearchController!
    var workoutTypes: [UIImage] = []
    var refresh = false

    
    fileprivate var manager: AWSUserFileManager!
    fileprivate var identityManager: AWSIdentityManager!
    fileprivate var user: AWSCognitoCredentialsProvider!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var marker: String?
    fileprivate var didLoadAllVideos: Bool!
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
        refresh = false
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = "\(WorkoutVideosDirectoryName)"
        }
    
        selected = "workoutVideo"
        loadVideoDetails()
        
        self.refreshControl?.addTarget(self, action: #selector(WorkoutsViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add a background view to the table view
        //let backgroundImage = UIImage(named: "backgroundImage3")
        //let imageView = UIImageView(image: backgroundImage)
        //self.tableView.backgroundView = imageView
        self.tableView.backgroundColor = UIColor.lightGray
        
         // no lines where there aren't cells
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // center and scale background image
        //imageView.contentMode = .scaleToFill
        
        // blur it
        //let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        //let blurView = UIVisualEffectView(effect: blurEffect)
        //blurView.frame = imageView.bounds
        //imageView.addSubview(blurView)
        
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        
        if(!workoutsLoaded) {
            myActivityIndicator.startAnimating()
        }
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
        
        self.loadVideoDetails()
        
        refreshControl.endRefreshing()
    }
    
    func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK:- Content Manager user action methods
    func showContentManagerActionOptions(_ sender: AnyObject) {
        self.showImagePicker()
    }
    
    fileprivate func refreshContents() {
        marker = nil
        loadMoreContents()
    }
    
    fileprivate func addVideos() {
        if workouts.count > 0 {
            if let contents = self.contents, contents.count > 0 {
                for workout in workouts {
                    let key = self.prefix + workout.name! + ".mp4"
                    if let i = contents.index(where: { $0.key == key }) {
                        workout.content = contents[i]
                    }
                }
            }
        }
    }
    
    fileprivate func loadMoreContents() {
        manager.listAvailableContents(withPrefix: prefix, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents, contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllVideos = false
                } else {
                    strongSelf.didLoadAllVideos = true
                }
                strongSelf.marker = nextMarker
                strongSelf.addVideos()
                strongSelf.myActivityIndicator.stopAnimating()
            }
            
            if strongSelf.loadedDetails {
                strongSelf.updateUserInterface()
            }
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
                self.showSimpleAlertWithTitle("We're Sorry!", message: "Videos are being created for this category still.", cancelButtonTitle: "OK")
            }
            else {
                print("items count - \(response!.items.count)")
                DispatchQueue.main.async {
                    self.loadMoreContents()
                    self.refresh = false
                }
                DispatchQueue.main.async {
                    self.formatVideoDetails(response)
                }
            }
            
            self.updateUserInterface()
        }
        
        if(!workoutsLoaded || refresh) {
            os_log("loading videoDetails content", log: OSLog.default, type: .debug)
            self.getVideoDetailsByType(completionHandler)
            workoutsLoaded = true
            os_log("after loading videoDetails content", log: OSLog.default, type: .debug)
        } else {
            os_log("workouts already loaded", log: OSLog.default, type: .debug)
            self.myActivityIndicator.stopAnimating()
            self.workoutsSearchResults = workouts
            updateUserInterface()
        }
    }
    
    func formatVideoDetails(_ response: AWSDynamoDBPaginatedOutput?) {
        // put data into correct spot
        let response = response?.items as! [Workouts]
        var vidArray = [WorkoutVids]()
        var key: String?
        for item in response {
            key = self.prefix + item._workoutName! + ".mp4"
            let workoutVid = WorkoutVids()
            workoutVid.name = item._workoutName
            workoutVid.description = item._videoDescription
            workoutVid.length = item._videoLength
            workoutVid.workoutType = item._workoutType
            if let awsContents = self.contents {
                if let i = awsContents.index(where: { $0.key == key }) {
                    workoutVid.content = awsContents[i]
                }
            }
            vidArray.append(workoutVid)
        }
        workouts = vidArray
        self.workoutsSearchResults = vidArray
        self.loadedDetails = true
        self.updateUserInterface()
    }
    
    
    
    func getVideoDetailsByType(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
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
            cell.prefix = prefix
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "workoutDetailShow",
            let destination = segue.destination as? WorkoutDetailViewController,
            let workoutIndex = tableView.indexPathForSelectedRow?.row
        {
            destination.workout = (workoutsSearchResults?[workoutIndex])!
        }
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
            self.navigationController!.pushViewController(uploadWorkoutsViewController, animated: true)
            
            //askForFilename(try! Data(contentsOf: videoURL))
            
        }
    }
}

class WorkoutVideoCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var videoLength: UILabel!
    
    var prefix: String?
    
    var content: WorkoutVids! {
        didSet {
            fileNameLabel.text = content.name
            detailLabel.text = content.description
            previewImage.image = content.previewImage
            videoLength.text = content.length
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
