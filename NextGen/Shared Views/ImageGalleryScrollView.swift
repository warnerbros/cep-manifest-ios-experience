//
//  ImageGalleryScrollView.swift
//

import UIKit
import NextGenDataManager

struct ImageGalleryNotification {
    static let DidScrollToPage = "kImageGalleryNotificationDidScrollToPage"
    static let DidToggleFullScreen = "kImageGalleryNotificationDidToggleFullScreen"
}

class ImageGalleryScrollView: UIScrollView, UIScrollViewDelegate {
    
    private struct Constants {
        static let ToolbarHeight: CGFloat = 44
        static let CloseButtonSize: CGFloat = 44
        static let CloseButtonPadding: CGFloat = 15
    }
    
    private var toolbar: UIToolbar?
    private var isFullScreen = false
    private var originalFrame: CGRect?
    private var originalContainerFrame: CGRect?
    private var closeButton: UIButton!
    
    private var sessionDataTasks = [NSURLSessionDataTask]()
    
    private var scrollViewPageWidth: CGFloat = 0
    var currentPage = 0 {
        didSet {
            sessionDataTasks.forEach({ $0.cancel() })
            sessionDataTasks.removeAll()
            
            loadGalleryImageForPage(currentPage)
            loadGalleryImageForPage(currentPage + 1)
            NSNotificationCenter.defaultCenter().postNotificationName(ImageGalleryNotification.DidScrollToPage, object: nil, userInfo: ["page": currentPage])
        }
    }
    
    var imageURLs = [NSURL]()
    private var gallerySubType = GallerySubType.Gallery
    
    var currentImageURL: NSURL? {
        set {
            
        }
        
        get {
            return imageURLForPage(currentPage)
        }
    }
    
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.delegate = self
        
        toolbar = UIToolbar()
        toolbar!.barStyle = .Black
        toolbar!.translucent = true
        
        closeButton = UIButton()
        closeButton.tintColor = UIColor.whiteColor()
        closeButton.alpha = 0.75
        closeButton.hidden = true
        closeButton.setImage(UIImage(named: "Close"), forState: .Normal)
        closeButton.addTarget(self, action: #selector(self.toggleFullScreen), forControlEvents: .TouchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let toolbar = toolbar where !toolbar.hidden {
            var toolbarFrame = toolbar.frame
            toolbarFrame.origin.x = self.contentOffset.x
            toolbarFrame.origin.y = self.contentOffset.y + (CGRectGetHeight(self.frame) - Constants.ToolbarHeight) + 1
            toolbar.frame = toolbarFrame
            self.bringSubviewToFront(toolbar)
            
            if let toolbarItems = toolbar.items, turntableSlider = toolbarItems.first?.customView as? UISlider {
                turntableSlider.frame.size.width = CGRectGetWidth(toolbarFrame) - 35 - (isFullScreen || toolbarItems.count == 1 ? 0 : Constants.ToolbarHeight)
            }
        }
        
        if !closeButton.hidden {
            var closeButtonFrame = closeButton.frame
            closeButtonFrame.origin.x = self.contentOffset.x + CGRectGetWidth(self.frame) - Constants.CloseButtonSize - Constants.CloseButtonPadding
            closeButton.frame = closeButtonFrame
            self.bringSubviewToFront(closeButton)
        }
    }
    
    func loadGallery(gallery: NGDMGallery) {
        gallerySubType = gallery.isSubType(.Turntable) ? .Turntable : .Gallery
        imageURLs = [NSURL]()
        
        if let pictures = gallery.pictures {
            for i in 0.stride(to: pictures.count, by: max((self.gallerySubType == .Turntable ? Int(ceil(Double(pictures.count) / 50)) : 1), 1)) {
                if let url = pictures[i].imageURL {
                    self.imageURLs.append(url)
                }
            }
        }
        
        resetScrollView()
        
        if gallerySubType == .Turntable {
            for i in 0 ..< imageURLs.count {
                loadGalleryImageForPage(i)
            }
        }
    }
    
    func loadImageURLs(imageURLs: [NSURL]) {
        gallerySubType = .Gallery
        self.imageURLs = imageURLs
        resetScrollView()
    }
    
    func destroyGallery() {
        imageURLs = [NSURL]()
        resetScrollView()
    }
    
    func removeToolbar() {
        toolbar?.removeFromSuperview()
        toolbar = nil
    }
    
    func removeFullScreenButton() {
        if let toolbar = toolbar, var items = toolbar.items where items.count > 0 {
            items.removeLast()
            toolbar.items = items
        }
    }
    
    private func resetScrollView() {
        for subview in self.subviews {
            if let subview = subview as? UIScrollView {
                subview.removeFromSuperview()
            }
        }
        
        if let frame = originalContainerFrame {
            self.superview?.frame = frame
        }
        
        if let frame = originalFrame {
            self.frame = frame
        }
        
        if let toolbar = toolbar {
            toolbar.items = nil
            
            var toolbarItems = [UIBarButtonItem]()
            if gallerySubType == .Turntable {
                let turntableSlider = UISlider(frame: CGRectMake(0, 0, CGRectGetWidth(self.frame) - Constants.ToolbarHeight - 35, Constants.ToolbarHeight))
                turntableSlider.minimumValue = 0
                turntableSlider.maximumValue = max(Float(imageURLs.count - 1), 0)
                turntableSlider.value = 0
                turntableSlider.addTarget(self, action: #selector(self.turntableSliderValueChanged), forControlEvents: .ValueChanged)
                toolbarItems.append(UIBarButtonItem(customView: turntableSlider))
            } else {
                toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
            }
            
            let fullScreenButton = UIButton(frame: CGRectMake(0, 0, Constants.ToolbarHeight, Constants.ToolbarHeight))
            fullScreenButton.tintColor = UIColor.whiteColor()
            fullScreenButton.setImage(UIImage(named: "Maximize"), forState: .Normal)
            fullScreenButton.setImage(UIImage(named: "Maximize Highlighted"), forState: .Highlighted)
            fullScreenButton.addTarget(self, action: #selector(self.toggleFullScreen), forControlEvents: .TouchUpInside)
            toolbarItems.append(UIBarButtonItem(customView: fullScreenButton))
            
            toolbar.items = toolbarItems
        }
        
        self.scrollEnabled = gallerySubType != .Turntable
        isFullScreen = false
        toolbar?.hidden = false
        closeButton.hidden = true
        currentPage = 0
        layoutPages()
    }
    
    func layoutPages() {
        scrollViewPageWidth = CGRectGetWidth(self.bounds)
        for i in 0 ..< imageURLs.count {
            var pageView = self.viewWithTag(i + 1) as? UIScrollView
            var imageView = pageView?.subviews.first as? UIImageView
            if pageView == nil {
                pageView = UIScrollView()
                pageView!.delegate = self
                pageView!.clipsToBounds = true
                pageView!.minimumZoomScale = 1
                pageView!.maximumZoomScale = 3
                pageView!.bounces = false
                pageView!.bouncesZoom = false
                pageView!.showsVerticalScrollIndicator = false
                pageView!.showsHorizontalScrollIndicator = false
                pageView!.tag = i + 1
                
                imageView = UIImageView()
                imageView!.contentMode = UIViewContentMode.ScaleAspectFit
                pageView!.addSubview(imageView!)
                
                self.addSubview(pageView!)
            }
            
            pageView!.zoomScale = 1
            pageView!.frame = CGRectMake(CGFloat(i) * scrollViewPageWidth, 0, scrollViewPageWidth, CGRectGetHeight(self.frame))
            imageView!.frame = pageView!.bounds
        }
        
        self.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * CGFloat(imageURLs.count), CGRectGetHeight(self.frame))
        self.contentOffset.x = scrollViewPageWidth * CGFloat(currentPage)
        
        if let toolbar = toolbar {
            toolbar.frame = CGRectMake(self.contentOffset.x, CGRectGetHeight(self.frame) - Constants.ToolbarHeight, CGRectGetWidth(self.frame), Constants.ToolbarHeight)
            self.addSubview(toolbar)
        }
        
        closeButton.frame = CGRectMake(self.contentOffset.x + CGRectGetWidth(self.frame) - Constants.CloseButtonSize - Constants.CloseButtonPadding, Constants.CloseButtonPadding, Constants.CloseButtonSize, Constants.CloseButtonSize)
        self.addSubview(closeButton)
        
        loadGalleryImageForPage(currentPage)
    }
    
    // MARK: Actions
    func toggleFullScreen() {
        isFullScreen = !isFullScreen
        toolbar?.hidden = isFullScreen && gallerySubType != .Turntable
        closeButton.hidden = !isFullScreen
        
        if isFullScreen {
            if let superview = self.superview {
                originalContainerFrame = superview.frame
                superview.frame = UIScreen.mainScreen().bounds
            }
            
            originalFrame = self.frame
            
            // FIXME: I have no idea why this hack works
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self.frame = UIScreen.mainScreen().bounds
                self.layoutPages()
            }
        } else {
            if let frame = originalContainerFrame {
                self.superview?.frame = frame
                originalContainerFrame = nil
            }
            
            if let frame = originalFrame {
                self.frame = frame
                originalFrame = nil
            }
            
            layoutPages()
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(ImageGalleryNotification.DidToggleFullScreen, object: nil, userInfo: ["isFullScreen": isFullScreen])
    }
    
    func turntableSliderValueChanged(slider: UISlider!) {
        gotoPage(Int(floor(slider.value)), animated: false)
    }
    
    // MARK: Image Gallery
    private func imageURLForPage(page: Int) -> NSURL? {
        if imageURLs.count > page {
            return imageURLs[page]
        }
        
        return nil
    }
    
    private func loadGalleryImageForPage(page: Int) {
        if let url = imageURLForPage(page), imageView = (self.viewWithTag(page + 1) as? UIScrollView)?.subviews.first as? UIImageView where imageView.image == nil {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { [weak self] in
                if let strongSelf = self, sessionDataTask = imageView.setImageWithURL(url, completion: nil) {
                    strongSelf.sessionDataTasks.append(sessionDataTask)
                }
            }
        }
    }
    
    private func imageViewForPage(page: Int) -> UIImageView? {
        if let pageView = self.viewWithTag(page + 1) as? UIScrollView {
            return pageView.subviews.first as? UIImageView
        }
        
        return nil
    }
    
    func cleanInvisibleImages() {
        let page = Int(self.contentOffset.x / scrollViewPageWidth)
        for subview in self.subviews {
            if subview.tag != page + 1, let imageView = subview.subviews.first as? UIImageView {
                imageView.image = nil
            }
        }
    }
    
    func gotoPage(page: Int, animated: Bool) {
        self.setContentOffset(CGPointMake(CGFloat(page) * scrollViewPageWidth, 0), animated: animated)
        if gallerySubType != .Turntable {
            currentPage = page
        }
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == self {
            currentPage = Int(targetContentOffset.memory.x / scrollViewPageWidth)
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageViewForPage(currentPage)
    }
 
}