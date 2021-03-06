//
//  LoginViewController.swift
//  EasyChef
//
//  Created by Kasidid Wachirachai on 23/1/2563 BE.
//  Copyright © 2563 Kasidid Wachirachai. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Firebase


class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet var button: [UIButton]!
    
    let firebaseAuth = Auth.auth()
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if AccessToken.current != nil {
            print("Facebook still logged in")
        }
        errorLabel.isHidden = true
        
        for button in button {
            button.layer.cornerRadius = 5
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        errorLabel.isHidden = true
        guard let userEmail = emailTextField.text, let userPassword = passwordTextField.text else {
            print("email/password is nil")
            return
        }
        if userEmail == "" || userPassword == "" {
            errorLabel.isHidden = false
            errorLabel.text = "Please fill in email and password."
        } else if !userEmail.isEmailFormat() {
            errorLabel.isHidden = false
            errorLabel.text = "Wrong formatted email."
        } else {
            emailLogin(userEmail: userEmail, userPassword: userPassword)
        }
    }
    
    @IBAction func facebookLoginButtonPressed(_ sender: Any) {
        facebookLogin()
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        segueWithoutSender(destination: "goToRegisterScreen")
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func emailLogin(userEmail:String, userPassword:String) {
        firebaseAuth.signIn(withEmail: userEmail, password: userPassword) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                self.errorLabel.isHidden = false
                self.errorLabel.text = ("Your email or password was incorrect. Please try again.")
                return
            }
            self.goBackWelcomeIfAuthSuccess()
        }
    }
    
    func facebookLogin() {
        let loginManager = LoginManager()
        loginManager.logIn(
            permissions: [.publicProfile, .email, .userFriends],
            viewController: self
        ) { result in
            self.facebookLoginResultChecker(result: result)
        }
    }
    
    func goBackWelcomeIfAuthSuccess() {
        if checkLoginStatatus() {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func facebookLoginResultChecker(result: LoginResult) {
        switch result {
        case.cancelled:
            print("Facebook Login Cancelled")
        case.failed(let error):
            print("Facebook Login Error \(error)")
        case.success(granted: _, declined: _, token: _):
            
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)

            firebaseAuth.signIn(with: credential) {(authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                let user = self.firebaseAuth.currentUser!
                self.createDB(uid: user.uid, email: user.email!, name: user.displayName!, imgUrl: user.photoURL!.absoluteString)
                print("Facebook Login Successful")
            }
        }
    }

    
    func createDB(uid:String, email:String, name:String, imgUrl:String) {
        
        let userDB = FirestoreReferenceManager.usersDB.document(uid)
        
        userDB.getDocument{ (document, error) in
            if let document = document, document.exists {
                print("database exist go to login")
            } else {
                userDB.setData([
                    "style": "",
                    "about": "",
                    "myList": ["Favorite":[]],
                    "ownedMenu": [],
                    "email": email,
                    "name": name,
                    "imageUrl": imgUrl
                ])
                { error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    self.adjustImageSize()
                    print("create database success")
                }
            }
            self.goBackWelcomeIfAuthSuccess()
        }
    }
    
    func adjustImageSize() {
        let userImage = firebaseAuth.currentUser?.photoURL
        let urlString = userImage!.absoluteString + "?type=square&redirect=true&width=500&height=500"
        let newImage = URL(string: urlString)
        let changeRequest = firebaseAuth.currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = newImage
        changeRequest?.commitChanges { (error) in
            if let error = error {
                print(error)
                return
            }
            print("Facebook Photo Updated")
        }
    }

}
