#PhotoStackView with swift
==============

###Statement

I studied from an open-sourced code whose name is also "PhotoStackView". But I can't find it now. It is written by Objective-C. Here I rewrite it with swift and fix some small bugs. Also I add some function on it.

###Usage

Just like UITableViewDelegate, you can init PhotoStackView and set the delegate and dataSource of it. Then you must implement the dataSource method `func numberOfPhotosInStackView(stackView: PhotoStackView) -> Int` and `func stackView(stackView: PhotoStackView, imageAtIndex index: Int) -> UIImage` to provide data for this view. Alternatively, you can implement `optional func stackView(stackView: PhotoStackView, sizeOfPhotoAtIndex index: Int) -> CGSize` to specify the size for each image.

To response to some event on this control, you can either implement these optional delegate method:
```swift
@objc protocol PhotoStackViewDelegate: NSObjectProtocol {
    optional func stackView(stackView: PhotoStackView, didSelectPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, willBeginDraggingPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, didRevealPhotoAtIndex index: Int)
    optional func stackView(stackView: PhotoStackView, willFlickAwayPhotoFromIndex from: Int, toIndex to: Int)
}
```
or use `addTarget:action:forControlEvents:` to add action listener. All control events it support are TouchDown, TouchCancel, TouchDragInside and TouchUpInside.

###Example

```swift
//declare some properties
var photos = [UIImage(named: "github_1.jpeg"), UIImage(named: "github_2.jpeg"), UIImage(named: "github_3.jpeg")]

let ps = PhotoStackView()

//viewDidLoad()
ps.delegate = self
ps.dataSource = self
ps.frame = CGRect(x: 120, y: 50, width: 80, height: 80)
view.addSubview(ps)

ps.addTarget(self, action: Selector("touchDown"), forControlEvents: .TouchDown)

//touchDown action listener
func touchDown() {
    println("touchDown")
}

//data source
func numberOfPhotosInStackView(stackView: PhotoStackView) -> Int {
    return photos.count
}

func stackView(stackView: PhotoStackView, imageAtIndex index: Int) -> UIImage {
    return photos[index]!
}

func stackView(stackView: PhotoStackView, sizeOfPhotoAtIndex index: Int) -> CGSize {
    return CGSizeMake(80, 80)
}

//delegate
func stackView(stackView: PhotoStackView, willFlickAwayPhotoFromIndex from: Int, toIndex to: Int) {
    println("from \(from) to \(to)")
}
```

###Images

Move, add and delete.
![stackView1](http://img.blog.csdn.net/20150602220650277)

Show next page
![stackView2](http://img.blog.csdn.net/20150602220720978)

Show all photos
![stackView3](http://img.blog.csdn.net/20150602221021702)
