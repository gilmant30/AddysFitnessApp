//
//  DynamoDbFoods.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 9/9/17.
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

class DynamoDbFoods {
    
    class var shared: DynamoDbFoods {
        struct Static {
            static let instance: DynamoDbFoods = DynamoDbFoods()
        }
        return Static.instance
    }
    
    func formatRecipeList(_ objects: [MVPFitObjects]) {
        os_log("formatRecipeList", log: OSLog.default, type: .debug)
        var recipeList = [Recipe]()
        for object in objects {
            if object._objectType == "recipe" {
                let recipe = formatRecipe(object)
                recipeList.append(recipe)
            }
        }
        
        recipes = recipeList
    }
    
    func formatRecipe(_ object: MVPFitObjects) -> Recipe {
        let recipe = Recipe()
        for (key, value) in object._objectInfo! {
            switch key {
            case "foodName":
                recipe.name = value as! String
                if myLikes.contains(where: { $0.title == recipe.name }) {
                    recipe.liked = true
                }
            case "category":
                 recipe.category = value as! String
            case "description":
                recipe.description = value as! String
            case "ingredients":
                recipe.ingredients = formatIngredients(value as! [String: String])
            case "listSteps":
                recipe.steps = value as! [String]
            default:
                break
            }
        }
        return recipe
    }
    
    func formatIngredients(_ list: [String: String]) -> [Ingredients] {
        var ingredientList = [Ingredients]()
        
        for (name, amount) in list {
            let ingredient = Ingredients()
            ingredient.ingredientName = name
            ingredient.amount = amount
            ingredientList.append(ingredient)
        }
        
        return ingredientList
    }

}
