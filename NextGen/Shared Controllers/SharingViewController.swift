//
//  SharingViewController.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 3/1/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class SharingViewController: SceneDetailViewController {
    
    @IBOutlet weak var player: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var clipDurationLabel: UILabel!
    @IBOutlet weak var clipNameLabel: UILabel!
    @IBOutlet weak var clipThumbnailImageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    
    private var _durationDidLoadObserver: NSObjectProtocol!
    
    var timedEvent: NGDMTimedEvent!
    
    private var _shareableURL: NSURL?
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(_durationDidLoadObserver)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Localizations
        shareButton.setTitle(String.localize("clipshare.send_button").uppercaseString, forState: UIControlState.Normal)
        
        clipNameLabel.text = timedEvent.getDescriptionText(self.experience!)
        if let imageURL = timedEvent.getImageURL(self.experience!) {
            clipThumbnailImageView.setImageWithURL(imageURL)
        } else {
            clipThumbnailImageView.image = UIImage.themeDefaultImage16By9()
        }
        
        if let audioVisual = timedEvent.getAudioVisual(self.experience!), videoURL = audioVisual.videoURL {
            _shareableURL = videoURL
        }
        
        _durationDidLoadObserver = NSNotificationCenter.defaultCenter().addObserverForName(kWBVideoPlayerItemDurationDidLoadNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] (notification) -> Void in
            if let strongSelf = self, userInfo = notification.userInfo, duration = userInfo["duration"] as? NSTimeInterval {
                strongSelf.clipDurationLabel.text = duration.timeString()
            }
        }
    }

    func videoPlayerViewController() -> VideoPlayerViewController? {
        for viewController in self.childViewControllers {
            if viewController is VideoPlayerViewController {
                return viewController as? VideoPlayerViewController
            }
        }
        
        return nil
    }
    
    // MARK: Actions
    @IBAction func playClip(sender: AnyObject) {
        clipThumbnailImageView.hidden = true
        playButton.hidden = true
        
        if let videoPlayerViewController = videoPlayerViewController() {
            videoPlayerViewController.curIndex = 0
            videoPlayerViewController.indexMax = 1
            videoPlayerViewController.mode = VideoPlayerMode.SupplementalInMovie
            videoPlayerViewController.playVideoWithURL(_shareableURL)
        }
    }
    
    @IBAction func shareClip(sender: AnyObject) {
        if let url = _shareableURL {
            let activityViewController = UIActivityViewController(activityItems: [String.localize("clipshare.message", variables: ["movie_name": "Man of Steel", "clip_link": url.absoluteString])], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = sender as? UIView
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }
    
}