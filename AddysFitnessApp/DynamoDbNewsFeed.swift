//
//  DynamoDbNewsFeed.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/31/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation

class DynamoDbNewsFeed {
    var test:String!
    
    class var shared: DynamoDbNewsFeed {
        struct Static {
            static let instance: DynamoDbNewsFeed = DynamoDbNewsFeed()
        }
        return Static.instance
    }
    
    func formatNewsFeedList(_ objects: [MVPFitObjects]) {
        var newsFeedList = [NewsFeed]()
        for object in objects {
            if object._objectType == "article" {
                let newsFeed = formatNewsFeed(object)
                newsFeedList.append(newsFeed)
            }
        }
        
        newsFeeds = newsFeedList
    }
    
    func formatNewsFeed(_ object: MVPFitObjects) -> NewsFeed {
        let feed = NewsFeed()
            for (key, value) in object._objectInfo! {
                switch key {
                case "articleUrl":
                    feed.url = value as? String
                case "imageUrl":
                    feed.imageUrl = value as? String
                case "title":
                    feed.title = value as? String
                case "description":
                    feed.description = value as? String
                case "canonicalUrl":
                    feed.canonicalUrl = value as? String
                default:
                    break
                }
        }
        return feed
    }

}
