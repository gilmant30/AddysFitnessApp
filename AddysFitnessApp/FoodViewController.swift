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
var recipes = [Recipe]()
var recipesLoaded = false

let FoodImagesDirectoryName = "public/recipeImages/"

class FoodViewController: UITableViewController, UISearchResultsUpdating {
    var prefix: String!
    var filteredRecipes: [Recipe]?
    let consumableTypes: [String] = ["all", "bfast", "lunch", "dinner", "snacks"]
    var selected: String = "snacks"
    var loadedDetails: Bool = false
    fileprivate var manager: AWSUserFileManager!
    fileprivate var marker: String?
    fileprivate var contents: [AWSContent]?
    fileprivate var didLoadAllImages: Bool!
    var refresh = false
    fileprivate var identityManager: AWSIdentityManager!
    
    var searchController: UISearchController!
    let myActivityIndicator = UIActivityIndicatorView()
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("recipes count is - \(recipes.count)")
        self.tableView.delegate = self
        self.tableView.estimatedSectionHeaderHeight = 80
        manager = AWSUserFileManager.defaultUserFileManager()
        identityManager = AWSIdentityManager.default()
        
        // Sets up the UIs.
        navigationItem.title = "MVPFit"
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = "\(FoodImagesDirectoryName)"
        }
        
        checkIfAdmin()
        
        getRecipes()
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
        
        myActivityIndicator.center = self.view.center
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = .gray
        self.view.addSubview(myActivityIndicator)
        if (!recipesLoaded) {
            myActivityIndicator.startAnimating()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myActivityIndicator.stopAnimating()
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
    
    func checkIfAdmin() {
        if let username = identityManager.identityProfile?.userName {
            print("Username is - \(username)")
            if admin.contains(username) {
                os_log("is an admin", log: OSLog.default, type: .debug)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(FoodViewController.addRecipe(_:)))
            }
        } else {
            os_log("not an admin", log: OSLog.default, type: .debug)
            
        }
    }
    
    func canDelete() -> Bool{
        if let username = identityManager.identityProfile?.userName {
            if admin.contains(username) {
               return true
            }
        }
        return false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.filteredRecipes = recipes.filter {
                $0.name.range(of: searchText, options: .caseInsensitive) != nil
            }
        }
        updateUserInterface()
    }

    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        os_log("Handling Refresh", log: OSLog.default, type: .debug)
        refresh = true
        self.getRecipes()
        refreshControl.endRefreshing()
    }
    
    fileprivate func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func addRecipe(_ sender: AnyObject) {
        os_log("Sending to add Food storyboard", log: OSLog.default, type: .debug)
        myActivityIndicator.startAnimating()
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String, kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func addImages() {
        os_log("Adding images to recipes", log: OSLog.default, type: .debug)
        if recipes.count > 0 {
            if let contents = self.contents, contents.count > 0 {
                for recipe in recipes {
                    let key = FoodImagesDirectoryName + recipe.name + ".jpg"
                    let keyVid = FoodImagesDirectoryName + recipe.name + ".mp4"
                    if let i = contents.index(where: { $0.key == key }) {
                        recipe.content = contents[i]
                    } else if let i = contents.index(where: { $0.key == keyVid }) {
                        recipe.content = contents[i]
                    }
                }
            }
        }

    }
    
    func loadImages() {
        manager.listAvailableContents(withPrefix: prefix, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents, contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllImages = false
                } else {
                    strongSelf.didLoadAllImages = true
                }
                print("contents count - \(contents.count)")
                strongSelf.marker = nextMarker
                strongSelf.addImages()
            }
            
            if strongSelf.loadedDetails {
                strongSelf.updateUserInterface()
            }
            strongSelf.myActivityIndicator.stopAnimating()
        }

    }
    
    func getRecipes() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                print("\(errorMessage)")
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            }
            else if response!.items.count == 0 {
                self.showSimpleAlertWithTitle("We're Sorry!", message: "Our favorite recipes have not been added in yet.", cancelButtonTitle: "OK")
                self.myActivityIndicator.stopAnimating()
            }
            else {
                DispatchQueue.main.async {
                    self.loadImages()
                    recipesLoaded = true
                }
                DispatchQueue.main.async {
                   self.convertToRecipes(response)
                }
            }
            
            self.updateUserInterface()
        }
        
        if(!recipesLoaded || refresh) {
            os_log("loading recipes content", log: OSLog.default, type: .debug)
            self.getRecipesWithCompletionHandler(completionHandler)
            os_log("after loading recipes content", log: OSLog.default, type: .debug)
        } else {
            os_log("don't need to load recipes", log: OSLog.default, type: .debug)
            myActivityIndicator.stopAnimating()
            filteredRecipes = recipes
            updateUserInterface()
            
        }
    }
    
    // MARK: - Databse Retrieve
    
    func getRecipesWithCompletionHandler(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        
        queryExpression.indexName = "typeIndex"
        queryExpression.keyConditionExpression = "#type = :type"
        queryExpression.expressionAttributeNames = ["#type": "type",]
        queryExpression.expressionAttributeValues = [":type": "recipe",]
        
        objectMapper.query(Food.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    func convertToRecipes(_ response: AWSDynamoDBPaginatedOutput?) {
        let foodArr = response?.items as! [Food]
        var recipeArr: [Recipe] = []
        for item in foodArr {
            let tempRecipe: Recipe = Recipe()
            tempRecipe.name = item._foodName!
            tempRecipe.description = item._description!
            tempRecipe.category = item._category!
            if let steps = item._listSteps {
                tempRecipe.steps = steps
            } else if let steps2 = item._steps {
                tempRecipe.steps = Array(steps2)
            }
            
            tempRecipe.ingredients = formatIngredients(item._ingredients!)
            recipeArr.append(tempRecipe)
        }
        
        recipes = recipeArr
        filteredRecipes = recipeArr
        self.loadedDetails = true
        self.updateUserInterface()
    }
    
    func formatSteps(_ steps: Set<String>) -> [String] {
        var arr: [String] = []
        for step in steps {
            arr.append(step)
        }
        return arr
    }
    
    func formatIngredients(_ ingredients: [String: String]) -> [Ingredients] {
        var listIngredients: [Ingredients] = []
        for (name, amount) in ingredients {
            let ingredient: Ingredients = Ingredients()
            ingredient.ingredientName = name
            ingredient.amount = amount
            listIngredients.append(ingredient)
        }
        
        return listIngredients
    }

    
    func valueChanged(segmentedControl: UISegmentedControl) {
        if(segmentedControl.selectedSegmentIndex == 0){
            self.filteredRecipes = recipes
        } else if(segmentedControl.selectedSegmentIndex == 1){
            self.filteredRecipes = recipes.filter {
                $0.category == "bfast"
            }
        } else if(segmentedControl.selectedSegmentIndex == 2){
            self.filteredRecipes = recipes.filter {
                $0.category == "lunch"
            }
        } else if(segmentedControl.selectedSegmentIndex == 3){
            self.filteredRecipes = recipes.filter {
                $0.category == "dinner"
            }
        } else if(segmentedControl.selectedSegmentIndex == 4){
            self.filteredRecipes = recipes.filter {
                $0.category == "snack"
            }
        } else {
            self.filteredRecipes = recipes
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
        guard let consumableArray = filteredRecipes else {
            return 0
        }
        return consumableArray.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FoodCell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath) as! FoodCell
        
        if let recipeArray = filteredRecipes {
            let recipe = recipeArray[indexPath.row]
            cell.cellDescription.lineBreakMode = .byWordWrapping
            cell.cellDescription.numberOfLines = 0
            cell.cellName.text = recipe.name
            cell.cellDescription.text = recipe.description
            cell.playButtonOverlay.isHidden = true
            
            if let url = recipe.url {
                cell.playButtonOverlay.isHidden = !recipe.isVideo
                if let image = recipe.image {
                    cell.cellImage.image = image
                } else {
                    DispatchQueue.global(qos: .default).async {
                        //os_log("recipe url is set", log: OSLog.default, type: .debug)
                        let imageData = NSData(contentsOf: url)
                        if let imageDat = imageData {
                            let image = UIImage(data: imageDat as Data)
                            recipe.image = image
                            DispatchQueue.main.async(execute: {() -> Void in
                                // Main thread stuff.
                                cell.cellImage.image = image
                            })
                        }

                    }
                }
                
                // cell.cellImage.image(url, recipe)
            }
            
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 350
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        os_log("Clicked on a recipe", log: OSLog.default, type: .debug)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canDelete()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            os_log("deleting recipe", log: OSLog.default, type: .debug)
            presentDeleteVerification((filteredRecipes?[indexPath.row])!, tableView, indexPath)
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        removeContent(recipe.content)
        deleteRecipeDetails(recipe, {(errors: [NSError]?) -> Void in
            os_log("deleting sql", log: OSLog.default, type: .debug)
            if errors != nil {
                self.showSimpleAlertWithTitle("Error", message: "Error deleting recipe", cancelButtonTitle: "OK")
            }
            self.updateUserInterface()
        })
    }
    
    func presentDeleteVerification(_ recipe: Recipe, _ tableView: UITableView, _ indexPath: IndexPath) {
        let deleteAlert = UIAlertController(title: "Delete", message: "Are you sure you want to delete this recipe?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.deleteRecipe(recipe)
            self.filteredRecipes?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            
            os_log("actually deleting recipe", log: OSLog.default, type: .debug)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            os_log("Cancelled request for delete", log: OSLog.default, type: .debug)
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteRecipeDetails(_ recipe: Recipe, _ completionHandler: @escaping (_ errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        var errors: [NSError] = []
        let group: DispatchGroup = DispatchGroup()
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        let result = formatter.string(from: date)
        
        
        let deleteRecipe: Food! = Food()
        
        deleteRecipe._foodName = recipe.name
        deleteRecipe._type = "recipe"
        deleteRecipe._category = recipe.category
        deleteRecipe._createdBy = AWSIdentityManager.default().identityId!
        deleteRecipe._createdDate = result
        deleteRecipe._description = recipe.description
        
        group.enter()
        
        objectMapper.remove(deleteRecipe, completionHandler: {(error: Error?) -> Void in
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
    
    fileprivate func removeContent(_ content: AWSContent) {
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "showDetailRecipe",
            let destination = segue.destination as? RecipeDetailViewController,
            let recipeIndex = tableView.indexPathForSelectedRow?.row
        {
            let clickedRecipe: Recipe = (filteredRecipes?[recipeIndex])!
            destination.recipe = clickedRecipe
            if clickedRecipe.content.key.contains(".mp4") {
                destination.isVideo = true
            }
        }
    }
    
    @IBAction func unwindFromUploadToMain(segue: UIStoryboardSegue) {
        os_log("Unwinding from upload to main", log: OSLog.default, type: .debug)
        recipesLoaded = false
        getRecipes()
    }
}

class FoodCell: UITableViewCell {
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellDescription: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var playButtonOverlay: UIImageView!
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
            uploadFoodViewController.isVideo = false
            uploadFoodViewController.manager = self.manager
            self.navigationController!.pushViewController(uploadFoodViewController, animated: true)
        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            let storyboard = UIStoryboard(name: "Food", bundle: nil)
            let uploadFoodViewController = storyboard.instantiateViewController(withIdentifier: "UploadFood") as! UploadFoodViewController
            uploadFoodViewController.manager = self.manager
            uploadFoodViewController.data = try! Data(contentsOf: videoURL)
            uploadFoodViewController.url = videoURL
            uploadFoodViewController.isVideo = true
            self.navigationController!.pushViewController(uploadFoodViewController, animated: true)
        }
        
    }
}

extension UIImage {
    
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            break
        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi/2))
            break
        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi/2))
            break
        case UIImageOrientation.up, UIImageOrientation.upMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}

extension UIImageView {
    func image(_ url: URL?, _ recipe: Recipe?) {
        guard let url = url else {
            print("Couldn't create URL")
            return
        }
        let theTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
            if let response = data {
                DispatchQueue.main.async {
                    self.image = UIImage(data: response)
                    recipe?.image = recipe?.image
                }
            }
        }
        theTask.resume()
    }
}

