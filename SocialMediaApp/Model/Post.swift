//
//  Post.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 13/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import Foundation
import Firebase
// node user-posts I've created by hands in firebase

class Post {
    var caption: String!
    var likes: Int!
    var postImageUrl: String!
    var ownerUid: String!
    var creationDate: Date!
    var postId: String!
    var user: User?
    var didLike = false
    
    // AnyObject is all rest parametrs whitch I do not specify in intializer
    init(postId: String!, user: User, dictionary: Dictionary<String, AnyObject>) {
        
        self.postId = postId
        
        self.user = user
        
        if let caption = dictionary["caption"] as? String {
            self.caption = caption
        }
        
        if let likes = dictionary["likes"] as? Int {
            self.likes = likes
        }
        
        if let postImageUrl = dictionary["postImageUrl"] as? String {
            self.postImageUrl = postImageUrl
        }
        
        if let ownerUid = dictionary["ownerUid"] as? String {
            self.ownerUid = ownerUid
        }
        
        if let creationDate = dictionary["creationDate"] as? Double {
            self.creationDate = Date(timeIntervalSince1970: creationDate)
        }
    }
    
    func adjustLikes(addLike: Bool, completion: @escaping(Int) -> ()) {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let postId = self.postId else { return }
        
        if addLike {
            
            // updates user-likes structure
            USER_LIKES_REF.child(currentUid).updateChildValues([postId: 1]) { (err, ref) in
                
                // send notification to server
                self.sendLikeNotificationToServer()
                
            // updates post-likes structure
                POST_LIKES_REF.child(self.postId).updateChildValues([currentUid: 1]) { (err, ref) in
                    self.likes = self.likes + 1
                    self.didLike = true
                    completion(self.likes)
                    POSTS_REF.child(self.postId).child("likes").setValue(self.likes)
                }
            }
        } else {
            
            //observe database for notifications id to remove
            USER_LIKES_REF.child(currentUid).child(postId).observeSingleEvent(of: .value) { (snapshot) in
                
                //get notifications id to remove from server
                guard let notificationID = snapshot.value as? String else {return}
                
                // remove notification from server
                NOTIFICATIONS_REF.child(self.ownerUid).child(notificationID).removeValue(completionBlock: { (err, ref) in
                    
                    // remove like from user-likes structure
                    USER_LIKES_REF.child(currentUid).child(postId).removeValue { (err, ref) in
                        
                        // remove post like from post-likes structure
                        POST_LIKES_REF.child(self.postId).child(currentUid).removeValue { (err, ref) in
                            guard self.likes > 0 else {return}
                            self.likes = self.likes - 1
                            self.didLike = false
                            completion(self.likes)
                            POSTS_REF.child(self.postId).child("likes").setValue(self.likes)
                        }
                    }
                })
            }
        }
    }
    
    func deletePost() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        
        // delete post img from the database storage
        Storage.storage().reference(forURL: self.postImageUrl).delete(completion: nil)
        
        // delete the post from followrs structure
        USER_FOLLOWER_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let followerUid = snapshot.key
            USER_FEED_REF.child(followerUid).child(self.postId).removeValue()
        }
        
        // delete the post from current user structure
        USER_FEED_REF.child(currentUid).child(postId).removeValue()
        
        // delete the post from user post srtructure
        USER_POSTS_REF.child(currentUid).child(postId).removeValue()
        
        // delete likes from structure
        POST_LIKES_REF.child(postId).observe(.childAdded) { (snapshot) in
            let uid = snapshot.key
            
            USER_LIKES_REF.child(uid).child(self.postId).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let notificationId = snapshot.value as? String else {return}
                
                NOTIFICATIONS_REF.child(self.ownerUid).child(notificationId).removeValue(completionBlock: { (err, ref) in
                    
                    POST_LIKES_REF.child(self.postId).removeValue()
                    
                    USER_LIKES_REF.child(uid).child(self.postId).removeValue()
                    
                })
            })
        }
        
        let words = caption.components(separatedBy: .whitespacesAndNewlines)
        for var word in words {
            if word.hasPrefix("#") {
                
                word = word.trimmingCharacters(in: .punctuationCharacters)
                word = word.trimmingCharacters(in: .symbols)
                
                HASHTAG_POST_REF.child(word).child(postId).removeValue()
            }
        }
        
        COMMENT_REF.child(postId).removeValue()
        POSTS_REF.child(postId).removeValue()
    }
    
    func sendLikeNotificationToServer() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let postId = self.postId else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        // send like only for not current user
        if currentUid != self.ownerUid {
            //notifications values
            let values = ["checked": 0,
                          "creationDate": creationDate,
                          "uid": currentUid,
                          "type": LIKE_INT_VALUE,
                          "postId": postId] as [String : Any]
            //notification database reference
            let notificationRef = NOTIFICATIONS_REF.child(self.ownerUid).childByAutoId()
            
            //upload notifications values to server
            notificationRef.updateChildValues(values) { (err, ref) in
                
                USER_LIKES_REF.child(currentUid).child(self.postId).setValue(notificationRef.key)
                
            }
        }
    }
}
