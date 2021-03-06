//
//  UIViewControllerUtils.swift
//

import UIKit

extension UIViewController {

    static var top: UIViewController? {
        var topViewController = UIApplication.shared.keyWindow?.rootViewController
        while topViewController!.presentedViewController != nil {
            topViewController = topViewController!.presentedViewController
        }

        return topViewController
    }

}
