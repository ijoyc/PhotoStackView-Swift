//
//  ViewController.swift
//  PhotoStackViewTest
//
//  Created by Chen Yizhuo on 15/6/1.
//  Copyright (c) 2015年 Chen Yizhuo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PhotoStackViewDataSource {
    
    var photos = [UIImage(named: "github_1.jpeg"), UIImage(named: "github_2.jpeg"), UIImage(named: "github_3.jpeg")]
    
    let ps = PhotoStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btn: UIButton = UIButton.buttonWithType(.System) as! UIButton
        btn.frame = CGRect(x: 100, y: 200, width: 100, height: 40)
        btn.setTitle("添加图片", forState: .Normal)
        btn.addTarget(self, action: Selector("addImage"), forControlEvents: .TouchUpInside)
        view.addSubview(btn)
        
        let deleteBtn = UIButton.buttonWithType(.System) as! UIButton
        deleteBtn.frame = CGRect(x: 100, y: 250, width: 100, height: 40)
        deleteBtn.setTitle("删除图片", forState: .Normal)
        deleteBtn.addTarget(self, action: Selector("deleteImage"), forControlEvents: .TouchUpInside)
        view.addSubview(deleteBtn)
        
        let moveBtn = UIButton.buttonWithType(.System) as! UIButton
        moveBtn.frame = CGRect(x: 100, y: 300, width: 100, height: 40)
        moveBtn.setTitle("下一张", forState: .Normal)
        moveBtn.addTarget(self, action: Selector("nextPhoto"), forControlEvents: .TouchUpInside)
        view.addSubview(moveBtn)
        
        let showBtn = UIButton.buttonWithType(.System) as! UIButton
        showBtn.frame = CGRect(x: 100, y: 350, width: 100, height: 40)
        showBtn.setTitle("显示全部", forState: .Normal)
        showBtn.addTarget(self, action: Selector("showAll"), forControlEvents: .TouchUpInside)
        view.addSubview(showBtn)
        
        ps.delegate = self
        ps.dataSource = self
        ps.frame = CGRect(x: 120, y: 50, width: 80, height: 80)
        view.addSubview(ps)

        ps.addTarget(self, action: Selector("touchDown"), forControlEvents: .TouchDown)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

/**
*  actions
*/
extension ViewController {
    func touchDown() {
        println("touchDown")
    }
    
    func addImage() {
        let num = arc4random() % 5 + 1
        photos.append(UIImage(named: "github_\(num).jpeg"))
        ps.reloadData()
    }
    
    func deleteImage() {
        if photos.count == 1 {
            let alert = UIAlertView(title: "Tips", message: "Only one photo left. Failed to delete image", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
            alert.show()
            return
        }
        
        photos.removeLast()
        ps.reloadData()
    }
    
    func nextPhoto() {
        let random = Int(arc4random() % 4 + 1)
        let direction = PhotoStackViewFlipDirection(rawValue: random)
        ps.flipToNextPhotoWithDirection(direction!)
    }
    
    func showAll() {
        ps.showAllPhotos()
    }
}

/**
*  delegate & dataSource
*/
extension ViewController: PhotoStackViewDataSource, PhotoStackViewDelegate {
    func numberOfPhotosInStackView(stackView: PhotoStackView) -> Int {
        return photos.count
    }
    
    func stackView(stackView: PhotoStackView, imageAtIndex index: Int) -> UIImage {
        return photos[index]!
    }
    
    func stackView(stackView: PhotoStackView, sizeOfPhotoAtIndex index: Int) -> CGSize {
        return CGSizeMake(80, 80)
    }
    
    func stackView(stackView: PhotoStackView, willFlickAwayPhotoFromIndex from: Int, toIndex to: Int) {
        println("from \(from) to \(to)")
    }
}

