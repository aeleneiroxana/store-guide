//
//  ViewController.swift
//  live-supplier
//
//  Created by Andreea Grigore on 10/05/2020.
//  Copyright © 2020 Andreea Grigore. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController {

    @IBOutlet weak var fb_login_Status: UILabel!
    @IBOutlet weak var btn_sign_out: UIButton!
    var userName = ""
    var email = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUser = Auth.auth().currentUser {
            self.btn_sign_out.isHidden = false
            fb_login_Status.text = "You are logged in as - " + ( currentUser.displayName ?? "Display name not found")
            self.userName = currentUser.displayName ?? "Unknown user name"
            self.email = currentUser.email ?? "Unknown user email"
        } else {
            self.btn_sign_out.isHidden = true
        }
        
        currentUserName()
    }
    
    
    @IBAction func btnSignOutAction(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.fb_login_Status.text = "Please login now"
            self.btn_sign_out.isHidden = true
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func fbAction(_ sender: Any) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            
            guard let accessToken = AccessToken.current else {
                print("Failed to get access token")
                return
            }

            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            // Perform login by calling Firebase APIs
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    return
                } else {
                    self.currentUserName()
                    
                    let ref = Database.database().reference()
                    
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"

                    let formattedDate = formatter.string(from: date)
                    
                    ref.childByAutoId().setValue(["name": self.userName, "role": "User", "email": self.email, "date": formattedDate])
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "MyTabBarController")
                    self.present(vc, animated: true)
                    
                }
            
            })

        }
    }
    
    func currentUserName() {
        if let currentUser = Auth.auth().currentUser {
            self.btn_sign_out.isHidden = false
            fb_login_Status.text = "You are logged in as - " + ( currentUser.displayName ?? "Display name not found")
            self.userName = currentUser.displayName ?? "Unknown user name"
            self.email = currentUser.email ?? "Unknown user email"
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {

    }
}

