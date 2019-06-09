//
//  CommentVC.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 20/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit
import Firebase

private let commentCell = "CommentCell"


class CommentVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    
    var comments = [Comment]()
    var post: Post?
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        
        containerView.addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: 50, height: 0)
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        containerView.addSubview(commentTextField)
        commentTextField.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: sendButton.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 0)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        containerView.addSubview(separatorView)
        separatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        
        containerView.backgroundColor = .white
        
        return containerView
    }()
    
    let commentTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter comment..."
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleUploadComment), for: .touchUpInside)
        
        return button
    }()
    
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -50, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: -50, right: 0)
        
        
        navigationItem.title = "Comments"
        
        // register cell class
        collectionView.register(CommentCell.self, forCellWithReuseIdentifier: commentCell)
        
        fetchComments()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return containerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let dummyCell = CommentCell(frame: frame)
        dummyCell.comment = comments[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width, height: 1000)
        let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
        
        let height = max(40 + 8 + 8, estimatedSize.height)
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: commentCell, for: indexPath) as! CommentCell
        
        handleHashtagTapped(forCell: cell)
        
        handleMentionTapped(forCell: cell)
        
        cell.comment = comments[indexPath.item]
        
        return cell
    }
    
    //MARK: - Handlers
    @objc func handleUploadComment () {
        
        guard let postId = self.post?.postId else {return}
        guard let commentText = commentTextField.text else {return}
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let values = ["commentText": commentText, "creationDate": creationDate, "uid": uid] as [String : Any]
        
        COMMENT_REF.child(postId).childByAutoId().updateChildValues(values) { (err, ref) in
            self.uploadCommentNotificationToServer()
            
            if commentText.contains("@") {
               self.uploadMentionNotification(forPosId: postId, withText: commentText, isForComment: true)
            }
            
            self.commentTextField.text = nil
        }
    }
    
    // MARK: - API
    
    func handleHashtagTapped(forCell cell: CommentCell) {
        cell.commentLabel.handleHashtagTap { (hashtag) in
            let hashTagController = HashtagController(collectionViewLayout: UICollectionViewFlowLayout())
            hashTagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashTagController, animated: true)
        }
    }
    
    func handleMentionTapped(forCell cell: CommentCell) {
        cell.commentLabel.handleMentionTap { (username) in
            self.getMentionedUser(withUsername: username)
        }
    }
    
    func fetchComments() {

        guard let postId = self.post?.postId else {return}
        
        COMMENT_REF.child(postId).observe(.childAdded) { (snapshot) in
            
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else {return}
            guard let uid = dictionary["uid"] as? String else {return}
            
            Database.fetchUser(with: uid, completion: { (user) in
                let comment = Comment(user: user, dictionary: dictionary)
                self.comments.append(comment)
                self.collectionView.reloadData()
                
            })
        }
    }
    
    func uploadCommentNotificationToServer() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        guard let postId = self.post?.postId else {return}
        guard let uid = post?.user?.uid else {return}
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        //notifications values
        let values = ["checked": 0,
                      "creationDate": creationDate,
                      "uid": currentUid,
                      "type": COMMENT_INT_VALUE,
                      "postId": postId] as [String : Any]
        
        // upload notification to server
        if uid != currentUid {
            NOTIFICATIONS_REF.child(uid).childByAutoId().updateChildValues(values)
        }
        
    }
}
