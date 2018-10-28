//
//  DetailViewController.swift
//  FaBook
//
//  Created by yonekan on 2018/10/29.
//  Copyright © 2018年 yonekan. All rights reserved.
//

import UIKit
import TextFieldEffects
import AlamofireImage

class DetailViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var reasonLabel: UILabel!
    
    
    @IBOutlet var bookImageView: UIImageView!
    
    var book = Book()
    
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = book.title
        reasonLabel.text = book.reason
        reasonLabel.sizeToFit()
        bookImageView.af_setImage(
            withURL: URL(string: book.imageUrl)!,
            placeholderImage: UIImage(named: "Placeholder")!,
            imageTransition: .curlUp(0.2)
        )
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeDown(_:)))
        view.addGestureRecognizer(panGesture)
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
