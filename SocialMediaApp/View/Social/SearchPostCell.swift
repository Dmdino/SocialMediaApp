//
//  SearchPostCell.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 05/05/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit

class SearchPostCell: UICollectionViewCell {
    
    var post: Post? {
        
        didSet {
            // next go to user profile VC and set in cell for item at
            guard let imageUrl = post?.postImageUrl else {return}
            postImageView.loadImage(with: imageUrl)
            
        }
    }
    
    let postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(postImageView)
        postImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
