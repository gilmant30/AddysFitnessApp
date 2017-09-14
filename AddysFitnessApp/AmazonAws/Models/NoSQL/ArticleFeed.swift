//
//  ArticleFeed.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.19
//

import Foundation
import UIKit
import AWSDynamoDB

class ArticleFeed: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _articleUrl: String?
    var _articleInfo: [String: String]?
    var _articleType: String?
    var _createdBy: String?
    var _createdDate: String?
    
    class func dynamoDBTableName() -> String {

        return "addysfitnessapp-mobilehub-805122985-ArticleFeed"
    }
    
    class func hashKeyAttribute() -> String {

        return "_articleUrl"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_articleUrl" : "articleUrl",
               "_articleInfo" : "articleInfo",
               "_articleType" : "articleType",
               "_createdBy" : "createdBy",
               "_createdDate" : "createdDate",
        ]
    }
}
