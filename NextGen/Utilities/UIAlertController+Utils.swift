//
//  UIAlertController+Utils.swift
//

import UIKit

extension UIAlertController {
    
    func show() {
        show(true)
    }
    
    func show(animated: Bool) {
        var topViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        while topViewController!.presentedViewController != nil {
            topViewController = topViewController!.presentedViewController
        }
        
        topViewController?.presentViewController(self, animated: animated, completion: nil)
    }
    
}
