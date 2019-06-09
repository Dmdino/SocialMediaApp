//
//  CustomImageView.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 13/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit

class CustomImageView: UIImageView {
    
    var imageCache = [String: UIImage]()
    
    var lastImageUrlUsedToLoadImage: String?

    
    func loadImage(with urlString: String) {
        
        // set image to nil. That I've done fore stop flickering
        self.image = nil
        
        // set lastImageUrlUsedToLoadImage
        lastImageUrlUsedToLoadImage = urlString
        
        // check if image exist in cashe
        if let cacheddImage = imageCache[urlString] {
            self.image = cacheddImage
            return
        }
        
        // url for image location
        guard let url = URL(string: urlString) else {return}
        
        // fetch content of url
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            
            if let err = err {
                print("Faild to load image with error ", err.localizedDescription)
            }
            
            if self.lastImageUrlUsedToLoadImage != url.absoluteString {
                return
            }
            
            // get image data
            guard let imageData = data else {return}
            // create image using image data
            let photoImage = UIImage(data: imageData)
            // set key and value for image cache
            self.imageCache[url.absoluteString] = photoImage
            // set our image
            DispatchQueue.main.async {
                self.image = photoImage
            }
            }.resume()
        
    }
    
}
