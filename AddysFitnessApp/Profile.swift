//
//  Profile.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 8/31/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import Foundation
import UIKit
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import AWSCognitoUserPoolsSignIn
import os.log
import WebKit
import AVKit
import MobileCoreServices
import os.log

import ObjectiveC
class Profile {
    var givenName: String! = ""
    var familyName: String! = ""
    var profileImg: UIImage?
    var profileImgUrl: URL?
    var email: String! = ""
    var gender: String! = ""
    var birthday: String! = ""

    func createUserProfile(_ attributeMap: [AWSCognitoIdentityProviderAttributeType]) {
        for map in attributeMap {
            if let mapName = map.name, let mapValue = map.value {
                print("name - \(mapName), value - \(mapValue)")
                switch mapName {
                    case "given_name":
                        self.givenName = mapValue
                    case "family_name":
                        self.familyName = mapValue
                    case "email":
                        self.email = mapValue
                    case "gender":
                        self.gender = mapValue
                    case "birthdate":
                        self.birthday = mapValue
                    default:
                        break
                    
                }
            }
        }
    }
    
    func addAttributesToList() -> [AWSCognitoIdentityUserAttributeType] {
        var attributeList = [AWSCognitoIdentityUserAttributeType]()
        
        if self.givenName != nil {
            attributeList.append(self.addGivenName())
        }
        if self.familyName != nil {
            attributeList.append(self.addFamilyName())
        }
        if self.gender != nil {
            attributeList.append(self.addGender())
        }
        if self.birthday != nil {
            attributeList.append(self.addBirthday())
        }
        
        
        return attributeList
    }
    
    func addGivenName() -> AWSCognitoIdentityUserAttributeType {
        let att = AWSCognitoIdentityUserAttributeType()
        att?.name = "given_name"
        att?.value = self.givenName
        return att!
    }
    
    func addFamilyName() -> AWSCognitoIdentityUserAttributeType {
        let att = AWSCognitoIdentityUserAttributeType()
        att?.name = "family_name"
        att?.value = self.familyName
        return att!
    }
    
    func addGender() -> AWSCognitoIdentityUserAttributeType {
        let att = AWSCognitoIdentityUserAttributeType()
        att?.name = "gender"
        att?.value = self.gender
        return att!
    }
    
    func addBirthday() -> AWSCognitoIdentityUserAttributeType {
        let att = AWSCognitoIdentityUserAttributeType()
        att?.name = "birthdate"
        att?.value = self.birthday
        return att!
    }
    
    
}


