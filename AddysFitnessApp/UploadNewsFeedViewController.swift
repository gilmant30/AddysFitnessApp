//
//  UploadNewsFeedViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/5/17.
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

class UploadNewsFeedViewController: UIViewController {
    

    @IBOutlet weak var articleImage: UIImageView!
    @IBOutlet weak var articleTitle: UILabel!
    @IBOutlet weak var articleUrl: UILabel!
    @IBOutlet weak var articleUploadButton: UIButton!
    var uploadNewsFeed: NewsFeed!
    let myActivityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setButton()
        articleTitle.text = uploadNewsFeed.title
        articleUrl.text = uploadNewsFeed.canonicalUrl
        
        if let imageUrl = uploadNewsFeed.imageUrl {
            let urlImage = URL(string: imageUrl)
            let data = try? Data(contentsOf: urlImage!)
            
            if let imageData = data {
                articleImage.image = UIImage(data: imageData)
            }
        }
        
    }
    
    func setButton() {
        articleUploadButton.layer.borderColor = UIColor.blue.cgColor
        articleUploadButton.layer.borderWidth = 0.5
        articleUploadButton.addTarget(self, action: #selector(UploadNewsFeedViewController.updateArticle(_:)), for: .touchUpInside)
        articleUploadButton.addTarget(self, action: #selector(UploadNewsFeedViewController.holdDown(_:)), for: .touchDown)
        articleUploadButton.addTarget(self, action: #selector(UploadNewsFeedViewController.release(_:)), for: .touchDragOutside)
        
        myActivityIndicator.frame = CGRect(x:0, y:0, width:40, height:40)
        myActivityIndicator.activityIndicatorViewStyle = .whiteLarge
        myActivityIndicator.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2)
        myActivityIndicator.hidesWhenStopped = true
        self.view.addSubview(myActivityIndicator)
    }
    
    func release(_ button: UIButton) {
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.blue, for: .normal)
    }
    
    func updateArticle(_ button: UIButton) {
        myActivityIndicator.startAnimating()
        saveArticle(completionHandler: ({(error: NSError?) -> Void in
            os_log("Inserted into sql", log: OSLog.default, type: .debug)
            self.myActivityIndicator.stopAnimating()
            if error != nil {
                self.showSimpleAlertWithTitle("Error", message: "Error saving sql data", cancelButtonTitle: "OK")
            } else {
                newsFeeds.append(self.uploadNewsFeed)
                self.showSimpleAlertWithTitle("Complete!", message: "Upload Completed Succesfully", cancelButtonTitle: "OK")
                self.navigationController?.popViewController(animated: true)
            }
        }))
    }
    
    func holdDown(_ button: UIButton) {
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: .normal)
    }
    
    func setLabelHeights() {
        let titleSize = articleTitle.rectForText(text: uploadNewsFeed.title!, font: articleTitle.font, maxSize: CGSize(width: articleTitle.frame.width, height: 999))
        let titleHeight = titleSize.height
        print("title height = \(titleHeight)")
        articleTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        DispatchQueue.main.async {
            self.articleTitle.frame = CGRect(x: self.articleTitle.frame.origin.x, y: self.articleTitle.frame.origin.y, width: self.articleTitle.frame.width, height: titleHeight)
        }
        
        articleTitle.sizeToFit()
        articleTitle.setNeedsLayout()
        articleTitle.layoutIfNeeded()
    }
    
    func saveArticle(completionHandler: @escaping (_ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        
        let mvpFitObject: MVPFitObjects = MVPFitObjects()
        
        mvpFitObject._createdBy = AWSIdentityManager.default().identityId!
        mvpFitObject._createdDate = result
        mvpFitObject._objectApp = mvpApp
        mvpFitObject._objectName = uploadNewsFeed.url!
        mvpFitObject._objectType = feedObjectType
        mvpFitObject._objectInfo = createArticleMap()
        
        objectMapper.save(mvpFitObject, completionHandler: {(error: Error?) -> Void in
            if error != nil {
                completionHandler(error! as NSError)
            } else {
                completionHandler(nil)
            }
        })

    }
    
    func createArticleMap() -> [String: String] {
        var articleMap = [String: String]()
        
        articleMap["articleUrl"] = uploadNewsFeed.url!
        articleMap["imageUrl"] = uploadNewsFeed.imageUrl!
        articleMap["title"] = uploadNewsFeed.title!
        articleMap["description"] = uploadNewsFeed.description!
        if uploadNewsFeed.canonicalUrl != nil {
            articleMap["canonicalUrl"] = uploadNewsFeed.canonicalUrl!
        }
        return articleMap
    }
    
    func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }


}
