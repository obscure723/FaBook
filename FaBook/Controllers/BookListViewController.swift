//
//  BookListViewController.swift
//  FaBook
//
//  Created by yonekan on 2018/10/28.
//  Copyright © 2018年 yonekan. All rights reserved.
//

import UIKit
import Firebase
import FontAwesome_swift
import AlamofireImage
import PopMenu

class BookListViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var addButton: UIButton!
    
    var books = [Book]()
    
    let margin:CGFloat = 10.0
    
    let refreshControl = UIRefreshControl()
    
    var selectedItem = Book()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // 下スワイプによるリフレッシュ処理追加
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        
        self.collectionView.register(UINib(nibName: "BookCell", bundle: nil),forCellWithReuseIdentifier: "BookCell")
        
        let addImage = UIImage.fontAwesomeIcon(name: .plusCircle, style: .solid, textColor: .orange, size: CGSize(width: 80, height: 80))
        addButton.setBackgroundImage(addImage, for: [])
        
        // ロングプレスジェスチャー設定
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.5
        self.collectionView.addGestureRecognizer(longPressRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        getBooks()
        observe()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditBook" {
            let addVc = segue.destination as! AddViewController
            addVc.book = sender as! Book
            
        } else if segue.identifier == "Detail" {
            let detailVC = segue.destination as! DetailViewController
            detailVC.book = sender as! Book
        }
    }
    
    // リフレッシュ処理
    @objc func refresh(sender: UIRefreshControl) {
        getBooks()
    }
    
    // firestoreから本を取得する
    func getBooks() {
        let db = Firestore.firestore()

        db.collection("books").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました")
                print("\(err)")
            } else {
                
                self.books = []
                for document in querySnapshot!.documents {
                    let book = Book()
                    book.key = document.documentID
                    book.title = document.get("title") as! String
                    book.reason = document.get("reason") as! String
                    book.imageUrl = document.get("imageUrl") as! String
                    
                    self.books.append(book)
                }
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    // サーバーのおすすめ本一覧の変更を監視する
    func observe() {
        let db = Firestore.firestore()
        
        db.collection("books")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                self.books = []
                for document in documents {
                    let book = Book()
                    book.key = document.documentID
                    book.title = document.get("title") as! String
                    book.reason = document.get("reason") as! String
                    book.imageUrl = document.get("imageUrl") as! String
                    
                    self.books.append(book)
                }
                self.collectionView.reloadData()
        }
    }
    
    // ロングプレスジェスチャー処理
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.collectionView)
        
        // ロングプレスジェスチャーされたセルのindex取得
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        if let indexPath = indexPath {
            switch sender.state {
            case .began:
                // ポップアップルメニュー表示
                openPopUpMenu(indexPath: indexPath)
            default:
                break
            }
        }
    }
    
    // ポップアップを表示する
    func openPopUpMenu(indexPath: IndexPath) {
        let manager = PopMenuManager.default
        
        let book = books[indexPath.row]
        
        self.selectedItem = book
        
        let editIcon = UIImage.fontAwesomeIcon(name: .edit, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20))
        
        let trashIcon = UIImage.fontAwesomeIcon(name: .trash, style: .solid, textColor: .black, size: CGSize(width: 20, height: 20))
        let editAction = PopMenuDefaultAction(title: "編集", image: editIcon, didSelect: { action in
            self.editBook()
        })
        
        let deleteAction = PopMenuDefaultAction(title: "削除", image: trashIcon, color: .red, didSelect: { action in
            self.deleteBook(selectedItem: self.selectedItem)
        })
        
        
        manager.addAction(editAction)
        manager.addAction(deleteAction)
        
        manager.present(on: self)
    }
}

extension BookListViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCell", for: indexPath) as! BookCell
        
        let book = books[indexPath.row]
        cell.imageView.af_setImage(
            withURL: URL(string: book.imageUrl)!,
            placeholderImage: UIImage(named: "Placeholder")!,
            imageTransition: .curlUp(0.2)
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = view.frame.width
        
        let cellNum: CGFloat = 2
        
        let cellSize = (width - margin * (cellNum + 1)) / cellNum
        
        return CGSize(width: cellSize, height: cellSize * 1.5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return margin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let book = books[indexPath.row]
        performSegue(withIdentifier: "Detail", sender: book)
    }
    
    func deleteBook(selectedItem: Book) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let db = Firestore.firestore()
            db.collection("books").document(selectedItem.key).delete()
            self.getBooks()
        }
    }
    
    func editBook() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.performSegue(withIdentifier: "EditBook", sender: self.selectedItem)
        }
    }
}
