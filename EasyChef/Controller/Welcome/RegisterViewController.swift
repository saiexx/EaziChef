//
//  RegisterViewController.swift
//  EasyChef
//
//  Created by Kasidid Wachirachai on 23/1/2563 BE.
//  Copyright © 2563 Kasidid Wachirachai. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {
    
    var db: Firestore!
    
    var firebaseAuth = Auth.auth()

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repasswordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet var errorLabel: [UILabel]!
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 5
        
        for label in errorLabel {
            label.isHidden = true
        }
    }
    
    @IBAction func textFieldDidEndOnExit(_ sender: UITextField) {
        
    }
    
    @IBAction func textFieldDidEditingChanged(_ sender: UITextField) {
        switch sender.tag {
        case 0:
            break
        case 1:
            if !(sender.text?.isEmailFormat())! {
                errorLabel[1].isHidden = false
                errorLabel[1].text = "Invalid email format."
            } else {
                errorLabel[1].isHidden = true
            }
        case 2:
            if sender.text!.count < 6 {
                errorLabel[2].isHidden = false
                errorLabel[2].text = "Password must longer than 6 characters."
            } else {
                errorLabel[2].isHidden = true
            }
        case 3:
            if sender.text! != passwordTextField.text {
                errorLabel[3].isHidden = false
                errorLabel[3].text = "Confirm password must match with password."
            } else {
                errorLabel[3].isHidden = true
            }
        default:
            break
        }
    }
    
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        guard let name = nameTextField.text,
            !nameTextField.text!.isEmpty else {
                print("name is empty")
                return
            }
        guard let email = emailTextField.text,
            !emailTextField.text!.isEmpty else {
                print("email is empty")
                return
            }
        guard let password = passwordTextField.text,
            !passwordTextField.text!.isEmpty else {
                print("password is empty")
                return
            }
        guard let repassword = repasswordTextField.text,
            !repasswordTextField.text!.isEmpty else {
                print("repassword is nil")
                return
            }
        
        if password != repassword {
            print("password is not same")
            return
        }
        
        emailRegister(name: name, email: email, password: password)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func emailRegister(name:String, email:String, password:String) {
        firebaseAuth.createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            self.setDisplayName(name: name)
            let user = self.firebaseAuth.currentUser!
            self.createDB(uid: user.uid, email: email, name: name, imgUrl: "")
            self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
            
        }
    }
    
    func setDisplayName(name:String) {
        let changeRequest = self.firebaseAuth.currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.commitChanges { (error) in
            if let error = error {
                print(error)
                return
            }
        }
    }
    
    func createDB(uid:String, email:String, name:String, imgUrl:String) {
        FirestoreReferenceManager.usersDB.document(uid).setData([
            "style": "",
            "about": "",
            "myList": ["Favorite":[]],
            "ownedMenu" : [],
            "email": email,
            "name": name,
            "imageUrl": imgUrl
        ]) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            print("create database success")
        }
    }
}
