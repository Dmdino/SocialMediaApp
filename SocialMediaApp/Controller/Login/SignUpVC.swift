//
//  SignUpVC.swift
//  SocialMediaApp
//
//  Created by Дмитрий Папушин on 06/04/2019.
//  Copyright © 2019 Дмитрий Папушин. All rights reserved.
//

import UIKit
import Firebase

class SignUpVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageSelected = false
    
    let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleSelectProfilePhoto), for: .touchUpInside)
        return button
    }()
    
    @objc func handleSelectProfilePhoto() {
    // настраиваем подхват фото
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    // презентую пикер контроллер
        self.present(imagePicker, animated: true, completion: nil)
    }
    // функция которая обрабатывает работу с камерарол
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let profileImage = info[.editedImage] as? UIImage else {
            imageSelected = false
            return
        }
        
        imageSelected = true
        
    //настаеваем plusPhotoButton с выбранным фото
        plusPhotoButton.layer.cornerRadius = plusPhotoButton.frame.width / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.black.cgColor
        plusPhotoButton.layer.borderWidth = 2
        plusPhotoButton.setImage(profileImage.withRenderingMode(.alwaysOriginal), for: .normal)
        self.dismiss(animated: true, completion: nil)
    }
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()

    let passowrdTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tf.borderStyle = .roundedRect
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    // обработка текста для почты и пароля
    @objc func formValidation() {
        guard
            emailTextField.hasText,
            passowrdTextField.hasText,
            fullNameTextField.hasText,
            userNamelTextField.hasText,
            imageSelected == true else {
                signUpButton.isEnabled = false
                signUpButton.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
                return
        }
        signUpButton.isEnabled = true
        signUpButton.backgroundColor = UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)
    }
    
    let fullNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Full name"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        return tf
    }()
    
    let userNamelTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.05)
        tf.borderStyle = .roundedRect
        tf.addTarget(self, action: #selector(formValidation), for: .editingChanged)
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    @objc func handleSignUp() {
        // properties
        guard let email = emailTextField.text else {return}
        guard let password = passowrdTextField.text else {return}
        guard let fullName = fullNameTextField.text else {return}
        guard let userName = userNamelTextField.text?.lowercased() else {return}
        // create user
        Auth.auth().createUser(withEmail: email, password: password) { (user, err) in
            if let err = err {
                print("Faild to create user with err: ", err.localizedDescription)
                return
            }
            
            // set profile image
            guard let profileImage = self.plusPhotoButton.imageView?.image else {return}
        // загрузить фото
            guard let uploadData = profileImage.jpegData(compressionQuality: 0.3) else {return}
        // поместить фото в хранилище
            let filename = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child(filename)
            
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                
                if let err = err {
                    print("Faild to upload image to Firebase storage ", err.localizedDescription)
                }
                // create profile image URL
                storageRef.downloadURL(completion: { (downloadURL, err) in
                    guard let profileImageUrl = downloadURL?.absoluteString else {
                        print("DEBUG: Profile image url is nil")
                        return
                    }
                    
                    guard let uid = user?.user.uid else { return }
                    
                    let dictionaryValues = ["name": fullName, "username": userName, "profileImageUrl": profileImageUrl]
                    
                    let values = [uid: dictionaryValues]
                    
                // сохраняем user info to database
                    Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
                        // For updating user data base before the user 
                        guard let mainTabVC = UIApplication.shared.keyWindow?.rootViewController as? MainTabVC else {return}
                        mainTabVC.configureViewControllers()
                        self.dismiss(animated: true, completion: nil)
                        // тоже самое что я делал в логин контроллере
                        
                    })
                })
                
            })
        }
    }
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?   ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShoLogin), for: .touchUpInside)
        return button
    }()
    // для возврвтв на прошлый вью
    @objc func handleShoLogin() {
        _ = navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140)
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        configureViewComponents()
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 50)

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func configureViewComponents() {
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, fullNameTextField, userNamelTextField, passowrdTextField, signUpButton])
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 240)
        
    }
    
}
