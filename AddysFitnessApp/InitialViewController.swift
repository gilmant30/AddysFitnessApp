//
//  ViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper

class InitialViewController: UIViewController {
    
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var willEnterForegroundObserver: AnyObject!
    fileprivate let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("InitialViewController viewDidLoad start")
        presentSignInViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    func presentSignInViewController() {
        print("start - PresentSingInViewController()")
        if !AWSIdentityManager.default().isLoggedIn {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            self.present(viewController, animated: true, completion: nil)
        }
    }

}

