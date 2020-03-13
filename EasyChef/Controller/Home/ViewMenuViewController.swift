//
//  ViewMenuViewController.swift
//  EasyChef
//
//  Created by Kasidid Wachirachai on 9/2/2563 BE.
//  Copyright © 2563 Kasidid Wachirachai. All rights reserved.
//

import UIKit
import Firebase

class ViewMenuViewController: UIViewController {
    
    var foodId:String?
    
    var currentMenu: Menu!
    
    @IBOutlet weak var menuTableView: UITableView!
    
    let tableHeaderViewHeight: CGFloat = UIScreen.main.bounds.height / 4
    
    var headerView: MenuHeaderView!
    var headerMaskLayer: CAShapeLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchMenu()
        setupHeaderView()
    }
    
    func setupTableView() {
        menuTableView.dataSource = self
        menuTableView.delegate = self
        menuTableView.rowHeight = UITableView.automaticDimension
        menuTableView.estimatedRowHeight = menuTableView.rowHeight
        menuTableView.separatorColor = UIColor.clear
        menuTableView.allowsSelection = false
    }
    
    func fetchMenu() {
        let menu = FirestoreReferenceManager.menusDB.document(foodId!)
        menu.getDocument { (document, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let menu = document!.data() else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            let name = menu["name"] as! String
            let ownerName = menu["ownerName"] as! String
            let imageUrlString = menu["imageUrl"] as! String
            let estimatedTime = menu["estimatedTime"] as! Int
            let rating = menu["rating"] as! [String:Int]
            let served = menu["served"] as! String
            let createdTimeTimestamp = menu["createdTime"] as! Timestamp
            let createdTime = TimeInterval(createdTimeTimestamp.seconds)
            let ingredients = menu["ingredients"] as! [String:[String:String]]
            let method = menu["method"] as! [String:String]
            self.currentMenu = Menu(forView: name, id: self.foodId!, ownerName: ownerName, imageUrl: imageUrlString, estimatedTime: estimatedTime, rating: rating, served: served, createdTime: createdTime, ingredients: ingredients, method: method)
            self.menuTableView.reloadData()
            self.headerView.foodImageView.kf.setImage(with: self.currentMenu?.imageUrl)
        }
    }
    
    func setupHeaderView() {
        headerView = menuTableView.tableHeaderView as? MenuHeaderView
        
        menuTableView.tableHeaderView = nil
        menuTableView.addSubview(headerView)
        
        menuTableView.contentInset = UIEdgeInsets(top: tableHeaderViewHeight, left: 0, bottom: 0, right: 0)
        menuTableView.contentOffset = CGPoint(x: 0, y: -tableHeaderViewHeight + 64)
        
        let effectiveHeight = tableHeaderViewHeight
        
        menuTableView.contentInset = UIEdgeInsets(top: effectiveHeight, left: 0, bottom: 0, right: 0)
        menuTableView.contentOffset = CGPoint(x: 0, y: -effectiveHeight)
        
        updateHeaderView()
    }
    
    func updateHeaderView() {
        let effectiveHeight = tableHeaderViewHeight
        var headerRect = CGRect(x: 0, y: -effectiveHeight, width: menuTableView.bounds.width, height: tableHeaderViewHeight)
        
        if menuTableView.contentOffset.y < -effectiveHeight {
            headerRect.origin.y = menuTableView.contentOffset.y
            headerRect.size.height = -menuTableView.contentOffset.y
        }
        
        headerView.frame = headerRect
    }
    
    func setRatingStar(averageRating: Double?, starImage:[UIImageView]) {
        let filledStar = #imageLiteral(resourceName: "filled-star")
        let blankStar = #imageLiteral(resourceName: "blank-star")
        var counter = 1
        if averageRating == nil {
            for star in starImage {
                star.image = nil
            }
            return
        }
        let intRating = Int(averageRating!)
        for star in starImage {
            if counter <= intRating {
                star.image = filledStar
            } else {
                star.image = blankStar
            }
            counter += 1
        }
    }
}

extension ViewMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentMenu == nil {
            return 0
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DescriptionCell", for: indexPath) as! FoodDescriptionTableViewCell
            
            cell.nameLabel.text = currentMenu?.name
            setRatingStar(averageRating: currentMenu?.averageRating, starImage: cell.starImageView)
            cell.ratingLabel.text = String(format:"%.1f(\(currentMenu!.numberOfUserRated!))", currentMenu!.averageRating!)
            cell.estimatedTimeLabel.text = "\(currentMenu!.estimatedTime!) minutes"
            cell.servedLabel.text = currentMenu!.served!
            configureRoundProfileImage(imageView: cell.profileImage)
            cell.profileButton.setTitle(currentMenu!.ownerName!, for: .normal)
            
            return cell
            
        } else if indexPath.row == 1 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientsCell", for: indexPath) as! IngredientsTableViewCell
            
            let ingredients = currentMenu!.ingredients
            var ingredientsText = ""
            
            for index in 1...ingredients.count {
                let name = ingredients["\(index)"]!["name"]!
                let amount = ingredients["\(index)"]!["amount"]!
                var text = ""
                
                if index == ingredients.count {
                    text = "\(name) - \(amount)"
                } else {
                    text = "\(name) - \(amount)\n\n"
                }
                
                ingredientsText += text
            }
            
            cell.ingredientsLabel.text = ingredientsText
            cell.ingredientsLabel.numberOfLines = 0
            
            return cell

        } else if indexPath.row == 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DirectionCell", for: indexPath) as! DirectionTableViewCell
            
            let direction = currentMenu!.method
            var directionText = ""
            var text = ""
            
            for index in 1...direction.count {
                let tempText = direction["\(index)"]
                if index == direction.count {
                    text = "\(index). \(tempText!)"
                } else {
                    text = "\(index). \(tempText!) \n\n"
                }
                directionText += text
            }
            
            cell.directionLabel.text = directionText
            cell.directionLabel.numberOfLines = 0
            
            return cell
        }
        return UITableViewCell()
    }
}

extension ViewMenuViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
}