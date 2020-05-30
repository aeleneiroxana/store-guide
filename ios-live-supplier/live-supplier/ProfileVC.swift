//
//  ProfileVC.swift
//  live-supplier
//
//  Created by Andreea Grigore on 13/05/2020.
//  Copyright © 2020 Andreea Grigore. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileVC: UIViewController {
    
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    override func viewDidLoad() {
        // nothing
        currentUserName();
    }
    
    func currentUserName() {
        if let currentUser = Auth.auth().currentUser {
            nameLabel.text = (currentUser.displayName ?? "Display name not found")
            emailLabel.text = (currentUser.email ?? "Email not found")
            do {
                let data = try Data(contentsOf: currentUser.photoURL!)
                self.profilePicture.image = UIImage(data: data)
            } catch _ {
                print("error at picture");
            }
            
            
        }
    }
    
    @IBAction func signOutAction(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.performSegue(withIdentifier: "unwindToViewController", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}
