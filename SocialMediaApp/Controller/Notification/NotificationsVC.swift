//
//  NotificationsVC.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 06/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifer = "NotificationCell"

class NotificationsVC: UITableViewController, NotificationCellDelegate {
    
    //MARK: - Properties
    
    var timer: Timer?
    
    var currentKey: String?
    
    var notifications = [Notification]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // clear separator lines
        tableView.separatorColor = .clear
        
        navigationItem.title = "Notifications"
        
        // register cell class
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifer)
        
        fetchNotifications()

    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if notifications.count > 4 {
            if indexPath.item == notifications.count - 1 {
                fetchNotifications()
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifer, for: indexPath) as! NotificationCell
        
        cell.notification = notifications[indexPath.row]
        
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let notification = notifications[indexPath.row]
        
        let userProfileVc = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileVc.user = notification.user
        navigationController?.pushViewController(userProfileVc, animated: true)
    }
    
    //MARK: - NotificationCellDelegate Protocol
    func handleFollowTapped(for cell: NotificationCell) {
        
        guard let user = cell.notification?.user else {return}
        
        if user.isFollowed {
            
            //handle unfollow
            user.unfollow()
            cell.followButton.configure(didFollow: false)
        } else {
            
            //handle follow user
            user.follow()
            cell.followButton.configure(didFollow: true)
        }
    }
    
    func handlePostTapped(for cell: NotificationCell) {
        guard let post = cell.notification?.post else  {return}
        
        let feedController = FeedVC(collectionViewLayout: UICollectionViewFlowLayout())
        feedController.viewSinglePost = true
        feedController.post = post
        navigationController?.pushViewController(feedController, animated: true)
        
    }
    
    //MARK: - Handlers
    
    func handleReloadTable() {
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleSortNotifications), userInfo: nil, repeats: false)
    }
    
    @objc func handleSortNotifications () {
        
        self.notifications.sort { (notification1, notification2) -> Bool in
            return notification1.creationDate > notification2.creationDate
        }
        self.tableView.reloadData()
    }
    
    //MARK: - API
    
    func fetchNotifications() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        //cast API call as a dictionary for ability to read an information
        //dictionary going thrugh all of the snapshots
        
        if currentKey == nil {
            
            NOTIFICATIONS_REF.child(currentUid).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                allObjects.forEach({ (snapshot) in
                    
                    let notificationId = snapshot.key
                    guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else {return}
                    guard let uid = dictionary["uid"] as? String else {return}
                    
                    Database.fetchUser(with: uid, completion: { (user) in
                        
                        if let postId = dictionary["postId"] as? String {
                            //if notification is for post
                            Database.fetchPost(with: postId, completion: { (post) in
                                let notification = Notification(user: user, post: post, dictionary: dictionary)
                                self.notifications.append(notification)
                                self.handleReloadTable()
                            })
                            
                        } else {
                            // if notification for user
                            let notification = Notification(user: user, dictionary: dictionary)
                            self.notifications.append(notification)
                            self.handleReloadTable()
                        }
                    })
                    NOTIFICATIONS_REF.child(currentUid).child(notificationId).child("checked").setValue(1)
                })
                self.currentKey = first.key
            }
            
        } else {
            
            NOTIFICATIONS_REF.child(currentUid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 6).observeSingleEvent(of: .value) { (snapshot) in
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else {return}
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {return}
                
                allObjects.forEach({ (snapshot) in
                    let notificationId = snapshot.key
                    
                    if notificationId != self.currentKey {
                        
                        guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else {return}
                        guard let uid = dictionary["uid"] as? String else {return}
                        
                        Database.fetchUser(with: uid, completion: { (user) in
                            
                            if let postId = dictionary["postId"] as? String {
                                //if notification is for post
                                Database.fetchPost(with: postId, completion: { (post) in
                                    let notification = Notification(user: user, post: post, dictionary: dictionary)
                                    self.notifications.append(notification)
                                    self.handleReloadTable()
                                })
                                
                            } else {
                                // if notification for user
                                let notification = Notification(user: user, dictionary: dictionary)
                                self.notifications.append(notification)
                                self.handleReloadTable()
                            }
                        })
                        NOTIFICATIONS_REF.child(currentUid).child(notificationId).child("checked").setValue(1)
                    }
                })
                self.currentKey = first.key
            }
        }
    }
}
