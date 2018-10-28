//
//  AddViewController.swift
//  FaBook
//
//  Created by yonekan on 2018/10/28.
//  Copyright © 2018年 yonekan. All rights reserved.
//

import UIKit
import TextFieldEffects
import Firebase
import AlamofireImage

class AddViewController: UIViewController {

    @IBOutlet var titleTextField: HoshiTextField!
    
    @IBOutlet var reasonTextField: UITextView!
    
    @IBOutlet var bookImageView: UIImageView!
    
    @IBOutlet var addButton: UIButton!
    
    var book = Book()
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        reasonTextField.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeDown(_:)))
        view.addGestureRecognizer(panGesture)
        
        if !book.key.isEmpty {
            bookImageView.af_setImage(
                withURL: URL(string: book.imageUrl)!,
                placeholderImage: UIImage(named: "Placeholder")!,
                imageTransition: .curlUp(0.2)
            )
            
            titleTextField.text = book.title
            reasonTextField.text = book.reason
            addButton.setTitle("保存", for: [])
        }
    }
    
    @IBAction func setImage(_ sender: UIButton) {
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle:  UIAlertController.Style.actionSheet)
    
        let runCamera: UIAlertAction = UIAlertAction(title: "カメラで撮影", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.startCamera()
        })
        
        let openGallery: UIAlertAction = UIAlertAction(title: "写真を選択", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.showAlbum()
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(runCamera)
        alert.addAction(openGallery)
        
        
        present(alert, animated: true, completion: nil)
    }

    // カメラの撮影開始
    func startCamera() {
        
        let sourceType:UIImagePickerController.SourceType =
            UIImagePickerController.SourceType.camera
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerController.SourceType.camera){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
            
        }
    }
    
    func imagePickerController(_ imagePicker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        
        if let pickedImage = info[.originalImage]
            as? UIImage {
            
            bookImageView.contentMode = .scaleAspectFit
            bookImageView.image = pickedImage
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func showAlbum() {
        let sourceType:UIImagePickerController.SourceType =
            UIImagePickerController.SourceType.photoLibrary
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerController.SourceType.photoLibrary){

            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
            
        }
        
    }
    
    
    @IBAction func add(_ sender: UIButton) {
        let image:UIImage! = bookImageView.image
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        let fileName = getNowMillisecond()
        
        // UIImagePNGRepresentationでUIImageをNSDataに変換
        if let data = image.jpegData(compressionQuality: 0.1) {
            // Firestorageの保存先パスの作成
            let reference = storageRef.child("images/" + fileName + ".jpg")
            
            // 画像をFirestorageに保存
            reference.putData(data, metadata: meta, completion: { metaData, error in
                if let error = error {
                    print("エラーが発生しました")
                    print("\(error)")
                    return
                }
                
                // Firestorageに保存した画像のダウンロードURLを作成
                reference.downloadURL { url, error in
                    if let error = error {
                        // ダウンロードURL作成に失敗した場合
                        print("\(error)")
                    } else {
                        let db = Firestore.firestore()
                        
                        var ref = db.collection("books").document()
                        
                        if !self.book.key.isEmpty {
                            ref = db.collection("books").document(self.book.key)
                        }
                        
                        ref.setData([
                            "title": self.titleTextField.text,
                            "reason": self.reasonTextField.text,
                            "imageUrl": url?.absoluteString as Any,
                        ]) { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            } else {
                                print("Document added")
                            }
                        }
                    }
                }

            })
            dismiss(animated: true, completion: nil)
        }
    }
    
    // 現在時刻をミリ秒まで取得する
    // ファイル名に使用する
    func getNowMillisecond() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyyMMddHHmmssSSS"
        return format.string(from: Date())
    }

    
    @objc func swipeDown(_ sender: UISwipeGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}

extension AddViewController : UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddViewController : UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            
            reasonTextField.resignFirstResponder()
            return false
        }
        return true
    }
    
}

extension AddViewController: UIImagePickerControllerDelegate {
    
}

extension AddViewController: UINavigationControllerDelegate {
    
}
