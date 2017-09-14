//
//  HomeNewsFeedViewControllerExtension.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/8/17.
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

extension HomeNewsFeedViewController {
    
    func addNewsFeedArticle(_ sender: AnyObject) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "URL", message: "Enter Article URL", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields![0] {// Force unwrapping because we know it exists.
                self.newsFeed.url = textField.text
                LoadingOverlay.shared.displayOverlay("Grabbing Article Info...")
                self.slPreview()
            }
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func slPreview() {
        let slp = SwiftLinkPreview()
        
        if let url = newsFeed.url {
            slp.preview(url, onSuccess: { result in
                if let title = result[SwiftLinkResponseKey.title] as? String {
                    self.newsFeed.title = title
                }
                if let imageUrl = result[SwiftLinkResponseKey.image] as? String {
                    self.newsFeed.imageUrl = imageUrl
                }
                if let description = result[SwiftLinkResponseKey.description] as? String {
                    self.newsFeed.description = description
                }
                if let canonicalUrl = result[SwiftLinkResponseKey.canonicalUrl] as? String {
                    self.newsFeed.canonicalUrl = canonicalUrl
                }
                print("title = \(self.newsFeed.title!)")
                print("imageUrl = \(self.newsFeed.imageUrl!)")
                print("description = \(self.newsFeed.description!)")
                print("canonicalUrl = \(self.newsFeed.canonicalUrl!)")
                LoadingOverlay.shared.removeOverlay()
                let storyboard = UIStoryboard(name: "NewsFeed", bundle: nil)
                let uploadNewsFeedViewController = storyboard.instantiateViewController(withIdentifier: "UploadNewsFeed") as! UploadNewsFeedViewController
                uploadNewsFeedViewController.uploadNewsFeed = self.newsFeed
                self.navigationController!.pushViewController(uploadNewsFeedViewController, animated: true)
            },
                        onError: {error in
                            LoadingOverlay.shared.removeOverlay()
                            self.showSimpleAlertWithTitle("Error", message: "Error Loading Url", cancelButtonTitle: "Ok")
                            print("\(error)")
                            
            })
        }
    }
    
    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    
    func getArticleFeed(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        
        queryExpression.indexName = "articleTypeIndex"
        queryExpression.keyConditionExpression = "#articleType = :articleType"
        queryExpression.expressionAttributeNames = ["#articleType": "articleType",]
        queryExpression.expressionAttributeValues = [":articleType": "articleFeed",]
        
        objectMapper.query(ArticleFeed.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as? NSError)
            })
        }
    }
}
