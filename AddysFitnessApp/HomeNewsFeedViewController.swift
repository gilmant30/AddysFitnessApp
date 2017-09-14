//
//  HomeNewsFeedViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/31/17.
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

var newsFeeds = [NewsFeed]()
let feedObjectType = "article"

class HomeNewsFeedViewController: UITableViewController {
    
    var newsFeed = NewsFeed()
    let slp = SwiftLinkPreview()
    var identityManager: AWSIdentityManager!
    var refresh: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("entering HomeNewsFeedViewController")
        identityManager = AWSIdentityManager.default()
        checkIfAdmin()
        loadNewsFeedDetails()
        navigationItem.title = "News Feed"
        
        let refreshControl: UIRefreshControl = {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action:
                #selector(HomeNewsFeedViewController.handleRefresh(_:)),
                                     for: UIControlEvents.valueChanged)
            refreshControl.tintColor = UIColor.red
            
            return refreshControl
        }()
        
        self.tableView.addSubview(refreshControl)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if newsFeeds.count > 0 {
            DispatchQueue.main.async {
                LoadingOverlay.shared.removeOverlay()
            }
        }
    }
    
    func checkIfAdmin() {
        if let username = identityManager.identityProfile?.userName {
            print("Username is - \(username)")
            if admin.contains(username) {
                os_log("is an admin", log: OSLog.default, type: .debug)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(HomeNewsFeedViewController.addNewsFeedArticle(_:)))
            }
        } else {
            os_log("not an admin", log: OSLog.default, type: .debug)
            
        }
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        os_log("Handling Refresh", log: OSLog.default, type: .debug)
        refresh = true
        self.updateUserInterface()
        refreshControl.endRefreshing()
        refresh = false
    }
    
    func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func loadNewsFeedDetails() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            } else {
                if mvpFitObjects.count > 0 || response != nil {
                    print("items count - \(response!.items.count)")
                    if mvpFitObjects.count == 0 {
                        let response = response?.items as! [MVPFitObjects]
                        mvpFitObjects = response
                        DynamoDbMVPFitObjects.shared.mapObjects()
                    }
                    os_log("removing overlay", log: OSLog.default, type: .debug)
                    DispatchQueue.main.async {
                        LoadingOverlay.shared.removeOverlay()
                    }
                }
            }
            self.updateUserInterface()
        }
        
        LoadingOverlay.shared.displayOverlay()
        
        if newsFeeds.count == 0 {
            os_log("newsFeeds is empty retrieving data", log: OSLog.default, type: .debug)
            DynamoDbMVPFitObjects.shared.getMvpFitObjects(refresh, completionHandler)
        } else {
            DispatchQueue.main.async {
                LoadingOverlay.shared.removeOverlay()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsFeeds.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        os_log("Clicked on a article", log: OSLog.default, type: .debug)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell: NewsFeedCell = tableView.dequeueReusableCell(withIdentifier: "NewsFeedCell", for: indexPath) as! NewsFeedCell
        
        let article = newsFeeds[indexPath.row]
        cell.article = article
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "newsFeedWebViewSegue",
            let destination = segue.destination as? NewsFeedWebViewController,
            let articleIndex = tableView.indexPathForSelectedRow?.row
        {
            let clickedArticle: NewsFeed = (newsFeeds[articleIndex])
            destination.urlString = clickedArticle.url!
        }
    }
    
}


