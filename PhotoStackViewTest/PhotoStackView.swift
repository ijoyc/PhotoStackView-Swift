//
//  PhotoStackView.swift
//  PhotoStackViewTest
//
//  Created by Chen Yizhuo on 15/6/1.
//  Copyright (c) 2015年 Chen Yizhuo. All rights reserved.
//

import UIKit

@objc protocol PhotoStackViewDataSource: NSObjectProtocol {
    func numberOfPhotosInStackView(stackView: PhotoStackView) -> Int
    func stackView(stackView: PhotoStackView, imageAtIndex index: Int) -> UIImage
    
    optional func stackView(stackView: PhotoStackView, sizeOfPhotoAtIndex index: Int) -> CGSize
}

@objc protocol PhotoStackViewDelegate: NSObjectProtocol {
    optional func stackView(stackView: PhotoStackView, didSelectPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, willBeginDraggingPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, didRevealPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, willFlickAwayPhotoFromIndex from: Int, toIndex to: Int)
}

enum PhotoStackViewFlipDirection: Int {
    case Left = 1, Right, Up, Down
}

/**
*  Supporting events: TouchDown, TouchCancel, TouchDragInside, TouchUpInside
*/
class PhotoStackView: UIControl {
    
    //MARK: computed property
    
    var s_borderImage: UIImage?
    /// the border image of every photo
    var borderImage: UIImage? {
        set {
            if s_borderImage == newValue {
                return
            }
            
            s_borderImage = newValue
            reloadData()
        }
        get {
            if s_borderImage == nil {
                return UIImage(named: "PhotoBorder.png")
            } else {
                return s_borderImage
            }
        }
    }
    
    var s_borderWidth: CGFloat = 0.0
    /// the width of border image view, default is 5.0
    var borderWidth: CGFloat {
        set {
            if s_borderWidth == newValue {
                return
            }
            
            s_borderWidth = newValue
            reloadData()
        }
        get {
            if showBorder {
                return s_borderWidth
            } else {
                return 0
            }
        }
    }
    
    var s_showBorder = false
    /// decide whether show border image view or not, default is true
    var showBorder: Bool {
        set {
            if s_showBorder == newValue {
                return
            }
            
            s_showBorder = newValue
            reloadData()
        }
        get {
            return s_showBorder
        }
    }
    
    var s_rotationOffset: CGFloat = 0.0
    /// the scope of offset of rotation on every photo except the first one. default is 4.0.
    /// ie, 4.0 means rotate iamge with degree between (-4.0, 4.0)
    var rotationOffset: CGFloat {
        set {
            if s_rotationOffset == newValue {
                return
            }
            
            s_rotationOffset = newValue
            reloadData()
        }
        get {
            return s_rotationOffset
        }
    }
    
    var s_highlightColor: UIColor?
    var highlightColor: UIColor? {
        set {
            s_highlightColor = newValue
        }
        get {
            if s_highlightColor == nil {
                return UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
            } else {
                return s_highlightColor
            }
        }
    }
    
    var delegate: PhotoStackViewDelegate?
    
    var s_dataSource: PhotoStackViewDataSource?
    var dataSource: PhotoStackViewDataSource? {
        set {
            s_dataSource = newValue
            reloadData()
        }
        get {
            return s_dataSource
        }
    }
    
    var s_photoImages: [UIView]?
    var photoImages: [UIView]? {
        set {
            //remove all subview and prepare to re-add all images from data source
            for view in subviews {
                view.removeFromSuperview()
            }
            
            if let images = newValue {
                for view in images {
                    //keep the original transfrom for the existing images
                    if let index = find(images, view), count = s_photoImages?.count where index < count {
                        let existingView = s_photoImages![index]
                        view.transform = existingView.transform
                    } else {
                        makeCrooked(view, animated: false)
                    }
                    
                    insertSubview(view, atIndex: 0)
                }
            }
            
            s_photoImages = newValue
        }
        get {
            return s_photoImages
        }
    }
    
    override var highlighted: Bool {
        didSet {
            let photo = self.topPhoto()?.subviews.last as! UIImageView
            if highlighted {
                let view = UIView(frame: self.bounds)
                view.backgroundColor = self.highlightColor
                photo.addSubview(view)
                photo.bringSubviewToFront(view)
            } else {
                photo.subviews.last?.removeFromSuperview()
            }
        }
    }
    
    override var bounds: CGRect {
        didSet {
            if CGRectEqualToRect(oldValue, self.bounds) {
                return
            }
            
            reloadData()
        }
    }
    
    override var frame: CGRect {
        didSet {
            if CGRectEqualToRect(oldValue, self.frame) {
                return
            }
            
            reloadData()
        }
    }
    
    //MARK: Set up
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        //default value
        borderWidth = 5.0
        showBorder = true
        rotationOffset = 4.0
        
        let panGR = UIPanGestureRecognizer(target: self, action: Selector("handlePan:"))
        addGestureRecognizer(panGR)
        
        let tapGR = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        addGestureRecognizer(tapGR)
        
        reloadData()
    }
    
    override func sendActionsForControlEvents(controlEvents: UIControlEvents) {
        super.sendActionsForControlEvents(controlEvents)
        highlighted = (controlEvents == .TouchDown)
    }
    
    //MARK: Public Methods
    
    /**
    use this method to reload photo stack view when data has changed
    */
    func reloadData() {
        if dataSource == nil {
            photoImages = nil
            return
        }
        
        if let number = dataSource?.numberOfPhotosInStackView(self) {
            var images = [UIView]()
            let border = borderImage?.resizableImageWithCapInsets(UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth))
            let topIndex = indexOfTopPhoto()
            
            for i in 0..<number {
                if let image = dataSource?.stackView(self, imageAtIndex: i) {
                
                    //add image view for every image
                    let imageView = UIImageView(image: image)
                    var viewFrame = CGRectMake(0, 0, image.size.width, image.size.height)
                    
                    if let ds = dataSource where ds.respondsToSelector(Selector("stackView:sizeOfPhotoAtIndex:")) {
                        let size = ds.stackView!(self, sizeOfPhotoAtIndex: i)
                        viewFrame.size = size
                    }

                    imageView.frame = viewFrame
                    
                    let view = UIView(frame: viewFrame)
                    
                    //add border for view
                    if showBorder {
                        if let b = border {
                            viewFrame.origin = CGPoint(x: borderWidth, y: borderWidth)
                            imageView.frame = viewFrame
                            view.frame = CGRect(x: 0, y: 0, width: imageView.frame.width + 2 * borderWidth, height: imageView.frame.height + 2 * borderWidth)
                            
                            let backgroundImage = UIImageView(image: b)
                            backgroundImage.frame = view.frame
                            view.addSubview(backgroundImage)
                        } else {
                            view.layer.borderWidth = borderWidth
                            view.layer.borderColor = UIColor.whiteColor().CGColor
                        }
                        
                    }
                    view.addSubview(imageView)
                    
                    //add view to array
                    images.append(view)
                    view.tag = i
                    view.center = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
                }
            }
            
            photoImages = images
            goToImageAtIndex(topIndex)
        }
        
    }
    
    /**
    find the index of top photo
    
    :returns: index of top photo
    */
    func indexOfTopPhoto() -> Int {
        if let images = photoImages, let photo = topPhoto() {
            if let index = find(images, photo) {
                return index
            }
        }
        return 0
    }
    
    /**
    automatically flip to next photo with a given direction
    
    :param: direction the direction of flipping
    */
    func flipToNextPhotoWithDirection(direction: PhotoStackViewFlipDirection) {
        var xVelocity: CGFloat = 0
        var yVelocity: CGFloat = 0
        switch direction {
        case .Up:
            yVelocity = 400
        case .Down:
            yVelocity = -400
        case .Left:
            xVelocity = 400
        case .Right:
            xVelocity = -400
        }
        
        if let photo = topPhoto() {
            flickAway(photo, withVelocity: CGPoint(x: xVelocity, y: yVelocity))
        }
    }
    
    /**
    get the top photo on photo stack
    
    :returns: current first photo
    */
    func topPhoto() -> UIView? {
        if subviews.count == 0 {
            return nil
        }
        return subviews[subviews.count - 1] as? UIView
    }
    
    /**
    jump to photo at index
    */
    func goToImageAtIndex(index: Int) {
        if let photos = photoImages {
            for view in photos {
                if let idx = find(photos, view) where idx < index {
                    sendSubviewToBack(view)
                }
            }
        }
        makeStraight(topPhoto()!, animated: false)
    }
    
    func showAllPhotos() {
        let screenBounds = UIScreen.mainScreen().bounds
        let maskView = UIView(frame: screenBounds)
        maskView.backgroundColor = UIColor.blackColor()
        maskView.alpha = 0
        UIApplication.sharedApplication().keyWindow?.addSubview(maskView)
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: nil, animations: { () -> Void in
            maskView.alpha = 1.0
        }) { (_) -> Void in
            
        }
        
        
        let column = 3
        let imageWidth = 80
        let padding = (Int(screenBounds.width) - column * imageWidth) / (column + 1)
        
        if let photos = photoImages {
            for view in photos {
                
                //set the initial location
                view.removeFromSuperview()
                maskView.addSubview(view)
                view.frame = frame
                
                if let index = find(photos, view) {
                    UIView.animateWithDuration(0.1, delay: NSTimeInterval(Double(index) * 0.1), options: nil, animations: { () -> Void in
                        view.frame = CGRect(x: padding + (index % column) * (imageWidth + padding), y: padding + (index / column) * (padding + imageWidth), width: imageWidth, height: imageWidth)
                    }, completion: { (finished) -> Void in
                        
                    })
                }
            }
        }
        
        let tapGR = UITapGestureRecognizer(target: self, action: Selector("removeMaskView:"))
        maskView.addGestureRecognizer(tapGR)
        
    }
    
    //MARK: Animations
    
    func returnToCenter(view: UIView) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            view.center = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMidY(self.bounds))
        })
    }
    
    func flickAway(view: UIView, withVelocity velocity: CGPoint) {
        if let del = delegate where del.respondsToSelector(Selector("stackView:willFlickAwayPhotoFromIndex:toIndex:")) {
            let from = indexOfTopPhoto()
            var to = from + 1
            if let number = dataSource?.numberOfPhotosInStackView(self) where to >= number {
                to = 0
            }
            
            del.stackView!(self, willFlickAwayPhotoFromIndex: from, toIndex: to)
        }
        
        let width = CGRectGetWidth(bounds)
        let height = CGRectGetHeight(bounds)
        
        var xPosition: CGFloat = CGRectGetMidX(bounds)
        var yPosition: CGFloat = CGRectGetMidY(bounds)
        
        if velocity.x > 0 {
            xPosition = CGRectGetMidX(bounds) + width
        } else if velocity.x < 0 {
            xPosition = CGRectGetMidX(bounds) - width
        }
        if velocity.y > 0 {
            yPosition = CGRectGetMidY(bounds) + height
        } else if velocity.y < 0 {
            yPosition = CGRectGetMidY(bounds) - height
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            view.center = CGPoint(x: xPosition, y: yPosition)
        }) { (finished) -> Void in
            self.makeCrooked(view, animated: true)
            self.sendSubviewToBack(view)
            self.makeStraight(self.topPhoto()!, animated: true)
            self .returnToCenter(view)
            
            if let del = self.delegate where del.respondsToSelector("stackView:didRevealPhotoAtIndex:") {
                del.stackView!(self, didRevealPhotoAtIndex:self.indexOfTopPhoto())
            }
        }
    }
    
    func rotate(degree: Int, onView view: UIView, animated: Bool) {
        let radian = CGFloat(degree) * CGFloat(M_PI) / 180
        
        if animated {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                view.transform = CGAffineTransformMakeRotation(radian)
            })
        } else {
            view.transform = CGAffineTransformMakeRotation(radian)
        }
    }
    
    func makeCrooked(view: UIView, animated: Bool) {
        let min = Int(-rotationOffset)
        let max = Int(rotationOffset)
        
        let scope = UInt32(max - min - 1)
        let randomDegree = Int(arc4random_uniform(scope))
        let degree: Int = min + randomDegree
        
        rotate(degree, onView: view, animated: animated)
    }
    
    func makeStraight(view: UIView, animated: Bool) {
        rotate(0, onView: view, animated: animated)
    }
    
    //MARK: Gesture Recognizer
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if let topPhoto = self.topPhoto() {
            let velocity = recognizer.velocityInView(recognizer.view)
            let translation = recognizer.translationInView(recognizer.view!)
            
            if recognizer.state == .Began {
                sendActionsForControlEvents(.TouchCancel)
                
                if let del = delegate where del.respondsToSelector(Selector("stackView:willBeginDraggingPhotoAtIndex")) {
                    del.stackView!(self, willBeginDraggingPhotoAtIndex: self.indexOfTopPhoto())
                }
            } else if recognizer.state == .Changed {
                topPhoto.center = CGPoint(x: topPhoto.center.x + translation.x, y: topPhoto.center.y + translation.y)
                recognizer.setTranslation(CGPoint.zeroPoint, inView: recognizer.view)
            } else if recognizer.state == .Ended || recognizer.state == .Cancelled {
                if abs(velocity.x) > 200 {
                    flickAway(topPhoto, withVelocity: velocity)
                } else {
                    returnToCenter(topPhoto)
                }
            }
    
        }
        
    }
    
    func handleTap(recognizer: UIGestureRecognizer) {
        sendActionsForControlEvents(.TouchUpInside)
        
        if let del = delegate where del.respondsToSelector(Selector("stackView:didSelectPhotoAtIndex:")) {
            del.stackView!(self, didSelectPhotoAtIndex: self.indexOfTopPhoto())
        }
    }
    
    func removeMaskView(recognizer: UITapGestureRecognizer) {
        let maskView = recognizer.view!
        for i in stride(from: maskView.subviews.count - 1, through: 0, by: -1) {
            let photo = maskView.subviews[i] as? UIView
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                photo?.frame = self.frame
            }, completion: { (_) -> Void in
                
            })
        }
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            maskView.alpha = 0.0
        }) { (_) -> Void in
            maskView.removeFromSuperview()
            self.reloadData()
        }
    }
    
    //MARK: Touch Methods
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        sendActionsForControlEvents(.TouchDown)
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        sendActionsForControlEvents(.TouchDragInside)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        sendActionsForControlEvents(.TouchCancel)
    }
}

