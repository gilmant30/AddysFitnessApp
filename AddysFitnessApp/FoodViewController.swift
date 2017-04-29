//
//  FoodViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/11/17.
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

let FoodImagesDirectoryName = "public/foodImages/"

class FoodViewController: UITableViewController, UISearchResultsUpdating {
    
    var testConsumables = [String: [Consumable]]()
    var consumables = [Consumable]()
    var filteredConsumables: [Consumable]?
    let consumableTypes: [String] = ["all", "bfast", "lunch", "dinner", "snacks"]
    var selected: String = "snacks"
    fileprivate var manager: AWSUserFileManager!
    
    var searchController: UISearchController!
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.estimatedSectionHeaderHeight = 80
        
        // Sets up the UIs.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(FoodViewController.addConsumable(_:)))
        navigationItem.title = "MVPFit"
        
        var consum = [Consumable]()
        
        for i in 1...3 {
            let snack = Consumable()
            snack?._name = "Snack" + String(i)
            snack?._consumableType = "snack"
            consum.append(snack!)
            
            let bfast = Consumable()
            bfast?._name = "bfast" + String(i)
            bfast?._consumableType = "bfast"
            consum.append(bfast!)
            
            let lunch = Consumable()
            lunch?._name = "Lunch" + String(i)
            lunch?._consumableType = "lunch"
            consum.append(lunch!)
            
            let dinner = Consumable()
            dinner?._name = "Dinner" + String(i)
            dinner?._consumableType = "dinner"
            consum.append(dinner!)
        }
        consumables = consum
        filteredConsumables = consum
        
       /* DispatchQueue.main.async {
            self.getConsumables()
        }*/
        configureSearchController()
        self.updateUserInterface()
        
        self.refreshControl?.addTarget(self, action: #selector(FoodViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Add a background view to the table view
        let backgroundImage = UIImage(named: "backgroundImage3")
        let imageView = UIImageView(image: backgroundImage)
        self.tableView.backgroundView = imageView
        
        // no lines where there aren't cells
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // center and scale background image
        imageView.contentMode = .scaleToFill
        
        // blur it
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = imageView.bounds
        imageView.addSubview(blurView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
    
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search food here..."
        searchController.searchBar.sizeToFit()
        
        // Place the search bar view to the tableview headerview.
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.filteredConsumables = self.filteredConsumables?.filter {
                $0._name?.range(of: searchText, options: .caseInsensitive) != nil
            }
        }
        updateUserInterface()
    }

    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        os_log("Handling Refresh", log: OSLog.default, type: .debug)
        
        DispatchQueue.main.sync {
            self.getConsumables()
        }
        
        refreshControl.endRefreshing()
    }
    
    fileprivate func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func addConsumable(_ sender: AnyObject) {
        os_log("Sending to add Food storyboard", log: OSLog.default, type: .debug)
        /*
        let storyboard = UIStoryboard(name: "Food", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "UploadFood")
        self.navigationController!.pushViewController(viewController, animated: true)
        */
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func getConsumables() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                print("\(errorMessage)")
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            }
            else if response!.items.count == 0 {
                self.showSimpleAlertWithTitle("We're Sorry!", message: "Our favorite snacks have not been added in yet.", cancelButtonTitle: "OK")
            }
            else {
                if let items = response!.items as? [Consumable] {
                    self.consumables = items
                }
            }
            
            self.updateUserInterface()
        }
        
        os_log("loading consumables content", log: OSLog.default, type: .debug)
        self.getConsumableDetailsByType(completionHandler)
        os_log("after loading consumables content", log: OSLog.default, type: .debug)
    }
    
    // MARK: - Databse Retrieve
    
    func getConsumableDetailsByType(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "consumableTypeIndex"
        queryExpression.keyConditionExpression = "#consumableType = :consumableType"
        queryExpression.expressionAttributeNames = ["#consumableType": "ConsumableType",]
        queryExpression.expressionAttributeValues = [":consumableType": selected,]
        
        objectMapper.query(Consumable.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func valueChanged(segmentedControl: UISegmentedControl) {
        if(segmentedControl.selectedSegmentIndex == 0){
            self.filteredConsumables = consumables
        } else if(segmentedControl.selectedSegmentIndex == 1){
            self.filteredConsumables = consumables.filter {
                $0._consumableType == "bfast"
            }
        } else if(segmentedControl.selectedSegmentIndex == 2){
            self.filteredConsumables = consumables.filter {
                $0._consumableType == "lunch"
            }
        } else if(segmentedControl.selectedSegmentIndex == 3){
            self.filteredConsumables = consumables.filter {
                $0._consumableType == "dinner"
            }
        } else if(segmentedControl.selectedSegmentIndex == 4){
            self.filteredConsumables = consumables.filter {
                $0._consumableType == "snack"
            }
        } else {
            self.filteredConsumables = consumables
        }
        self.updateUserInterface()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let control = UISegmentedControl(items: self.consumableTypes)
        control.addTarget(self, action: #selector(self.valueChanged), for: UIControlEvents.valueChanged)
        if(section == 0){
            return control;
        }
        return nil;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80.0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let consumableArray = filteredConsumables else {
            return 0
        }
        return consumableArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FoodCell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath) as! FoodCell
        
        if let consumableArray = filteredConsumables {
            let consumable = consumableArray[indexPath.row]
            cell.cellName.text = consumable._name
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50
    }

    
}

class FoodCell: UITableViewCell {
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellDescription: UILabel!

}

// MARK: - Utility

extension FoodViewController {
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK:- UIImagePickerControllerDelegate

extension FoodViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle image uploads
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let storyboard = UIStoryboard(name: "Food", bundle: nil)
            let uploadFoodViewController = storyboard.instantiateViewController(withIdentifier: "UploadFood") as! UploadFoodViewController
            uploadFoodViewController.image = image
            uploadFoodViewController.manager = self.manager
            self.navigationController!.pushViewController(uploadFoodViewController, animated: true)
        }
        
    }
}

