//
//  SelectImageVC.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 08/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "SelectPhotoCell"
private let headerIdentifier = "SelectPhotoHeader"

class SelectImageVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    var images = [UIImage]()
    var assets = [PHAsset]()
    var selectedImage: UIImage?
    // use it in viewForSupplementaryElementOfKind
    var header: SelectPhotoHeader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register cell classes
        collectionView?.register(SelectPhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(SelectPhotoHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        
        collectionView.backgroundColor = .white
        
        configureNavigationButtons()
        
        fetchPhotos()
    }
    
    //MARK: - UICollectionViewFlowLayout
    // set size fore header - main image
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width, height: width)
    }
    //
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3) / 4 // did it for create 4 cells in a row
        return CGSize(width: width, height: width)
    }
    // give a spacin between cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    // give a spacin between cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    //MARK: - UICollectionViewDataSourse
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! SelectPhotoHeader
        
        self.header = header
        
        if let selectedImage = self.selectedImage {
            //get index of selectes image
            if let index = self.images.firstIndex(of: selectedImage) {
                // get asset associated with that image
                let selectesAsset = self.assets[index]
                
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 600, height: 600) // size fore header
                // request an image
                imageManager.requestImage(for: selectesAsset, targetSize: targetSize, contentMode: .default, options: nil) { (image, info) in
                    header.photoImageView.image = image // showing first image
                }
            }
        }
        
        
        return header
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SelectPhotoCell
        // showing rest images
        cell.photoImageView.image = images[indexPath.row]
        
        return cell
    }
    // gives an ability to selext imagen in a row and put into photo header
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.selectedImage = images[indexPath.row]
        self.collectionView.reloadData()
        // bringing back to the top when image slecting
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    //MARK: - Handlers
    
    @objc func handleCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func handleNext() {
        let uploadPostVC = UploadPostVC()
        uploadPostVC.selectedImage = header?.photoImageView.image
        navigationController?.pushViewController(uploadPostVC, animated: true)
    }
    
    func configureNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
    }
    // how we want to fetch the photos
    func getAssetFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        // fetch limit
        options.fetchLimit = 60
        // sort photos by date
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        
        // set sort descriptor
        options.sortDescriptors = [sortDescriptor]
        return options
    }
    
    func fetchPhotos() {

        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: getAssetFetchOptions())
        
        // fetch images on background thread - очередь на отправку
        DispatchQueue.global(qos: .background).async {
            
            allPhotos.enumerateObjects({ (asset, count, stop) in
                
                let imageManager = PHImageManager.default()
                let targetSize = CGSize(width: 200, height: 200)
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                
                // request image representation for specified asset
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (image, info) in
                    
                    if let image = image {
                        
                        // append image to data source
                        self.images.append(image)
                        // append asset to data source
                        self.assets.append(asset)
                        // set selected image with first image
                        if self.selectedImage == nil {
                            self.selectedImage = image
                        }
                        
                        // reload collection view whith images once count has completed
                        if count == allPhotos.count - 1 {
                            // reload collection view on main thread
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                    }
                })
                
            })
        }
        
    }
}
