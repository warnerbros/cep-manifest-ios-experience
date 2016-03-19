//
//  NSTimeInterval+Utils.swift
//  NextGen
//
//  Created by Alec Ananian on 3/19/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import Foundation

extension NSTimeInterval {
    
    func formattedTime() -> String {
        let seconds = Int(self % 60)
        let minutes = Int((self / 60) % 60)
        let hours = Int(self / 3600)
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func timeString() -> String {
        let seconds = Int(self % 60)
        let minutes = Int((self / 60) % 60)
        let hours = Int(self / 3600)
        
        var timeStrings = [String]()
        if hours > 0 {
            timeStrings.append(String(hours) + " hr")
        }
        
        if minutes > 0 {
            timeStrings.append(String(minutes) + " min")
        }
        
        if seconds > 0 {
            timeStrings.append(String(seconds) + " sec")
        }
        
        return timeStrings.joinWithSeparator(" ")
    }
    
}