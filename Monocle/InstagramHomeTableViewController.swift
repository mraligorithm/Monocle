//
//  InstagramHomeTableViewController.swift
//  Monocle
//
//  Created by Alisher Abdukarimov on 6/4/17.
//  Copyright © 2017 MrAliGorithm. All rights reserved.
//

import UIKit


protocol InstagramHomeFriendsTableViewControllerDelegate: class {
    func instagramHomeFriendsTableViewController(_ viewController: InstagramHomeTableViewController, didUpdateFriendsList lists: ([MonocleUser], String))
}

class InstagramHomeTableViewController: UITableViewController {
    
    let userDefaults = UserDefaults.standard
    weak var delegate: InstagramHomeFriendsTableViewControllerDelegate?
    var homeTableViewDelegate: HomeTableViewController?
    var monocleFriends: [MonocleUser]?
    var listOfUser:[InstagramUser] = []
    var twitterID: String!
    
    var accessToken: String! {
        didSet {
        fetchUsersFollowed()
        }
    }
    
    var indexNum = 0
    var selectedUsersRegular: [String : InstagramUser] = [:]
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if accessToken == nil {
            authInstagram()
        }else if accessToken != nil {
            fetchUsersFollowed()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if accessToken != nil {
            save()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1 
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return listOfUser.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendsList", for: indexPath) as! InstagramHomeCell
         cell.user = listOfUser[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexNum = indexPath.row
        let cell = tableView.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        let user = listOfUser[indexPath.row]
        if cell?.accessoryType == .checkmark{
            self.selectedUsersRegular.removeValue(forKey: user.userName)
            cell?.accessoryType = .none
        } else {
            cell?.accessoryType = .checkmark
            self.selectedUsersRegular[user.userName] = user
        }

    }
    
    
    func save() {
        
        OperationQueue.main.addOperation {[weak self] in
            
            guard let strongSelf = self else { return }
            var selectedFriends: [NSDictionary] = []
            var sUsers: InstagramUser!
            for (_ , value) in strongSelf.selectedUsersRegular {
                
                sUsers = value
                let dictioanry: NSDictionary = [
                    "name" : value.fullName,
                    "userName" : value.userName,
                    "uid"  : value.uid,
                    "image": value.image,
                    "accountType" : value.accountType
                ]
                
                selectedFriends.append(dictioanry)
            }
            
            for friend in strongSelf.monocleFriends! {
                if friend.twitterID == strongSelf.twitterID {
                friend.accounts?.append(MonocolAccount.instagram(sUsers))
                    friend.instagramID = sUsers.uid
                    strongSelf.homeTableViewDelegate?.instagramAccessToken = strongSelf.accessToken
                    strongSelf.homeTableViewDelegate?.selectedFriend = friend
                }
            }
            strongSelf.homeTableViewDelegate?.monocleFriends = strongSelf.monocleFriends!
            strongSelf.userDefaults.set(selectedFriends, forKey: "savedInstagramFriends")
            strongSelf.userDefaults.synchronize()
            strongSelf.delegate?.instagramHomeFriendsTableViewController(strongSelf, didUpdateFriendsList: (strongSelf.monocleFriends!, strongSelf.accessToken))
            
        }
        
    }

    
    
    func authInstagram() {
        
        //SaveChanges
        if let token = userDefaults.object(forKey: "accessTokenForInstagram") as? String {
            self.accessToken = token
            print("Already logged in\(accessToken)")
            
        } else {
            
            SimpleAuth.authorize("instagram", options: ["scope": ["follower_list public_content"]]) { (oResult: Any?, error: Error?) -> Void in
                
                // Getting data and also accessing to Token
                if let result = oResult as? [String:Any] {
                    let credentials = result["credentials"] as! [String:Any]
                    let accessToken = credentials["token"] as! String
                    self.accessToken = accessToken
                    self.userDefaults.set(self.accessToken, forKey: "accessTokenForInstagram")
                    self.userDefaults.synchronize()
                }
            }
        }
    }
    
    
    func fetchUsersFollowed() {
        
        Instagram().fetchUserFriends(accessToken) { (oUsers) in
            self.listOfUser = oUsers
            OperationQueue.main.addOperation {
                self.tableView?.reloadData()
            }
        }
    }
    
    
/*
    func cellTapped() {
              let tappedUser = listOfUser[indexNum] 
              let id = tappedUser.uid
              let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let controller = storyboard.instantiateViewController(withIdentifier: "Feed") as! InstaPostsTableViewController
              controller.uID = id
              controller.accessToken = accessToken
              controller.title = tappedUser.name
              self.navigationController?.pushViewController(controller, animated: true)
        
    }
*/
    
}

