//
//  TokenBucket.swift
//  RateLimiter
//
//  Created by Erik Little on 11/16/14.
//  Open Source
//

import Foundation

class TokenBucket: NSObject {
    let sizeOfBucket:Double!
    let tokensPerInterval:Double!
    let interval:Double!
    var contains = 0.0
    var lastDrip = NSDate().timeIntervalSince1970
    
    init(sizeOfBucket:Double, tokensPerInterval:Double!, interval:AnyObject) {
        self.sizeOfBucket = sizeOfBucket
        self.tokensPerInterval = tokensPerInterval
        self.contains = sizeOfBucket
        
        if let interval = interval as? String {
            switch (interval) {
            case "second":
                self.interval = 1
            case "minute":
                self.interval = 60
            case "hour":
                self.interval = 3600
            case "day":
                self.interval = 86400
            default:
                self.interval = 1
            }
        } else if let interval = interval as? Double {
            self.interval = interval
        } else {
            self.interval = 1
        }
        
        super.init()
    }
    
    func drip() {
        if self.tokensPerInterval == 0 {
            self.contains = self.sizeOfBucket
        }
        
        let now = NSDate().timeIntervalSince1970
        let delta = max(now - self.lastDrip, 0)
        self.lastDrip = now
        let dripAmount = delta * (self.tokensPerInterval / self.interval)
        let newContains = dripAmount + self.contains
        self.contains = min(newContains, self.sizeOfBucket)
    }
    
    func removeToken(#count:Double, callback:((err:String?, remainingTokens:Double?) -> Void)) {
        // Used if we have to wait for more tokens
        func createDispatchLater() {
            var waitInterval = ceil((count - self.contains) *
                (self.interval / self.tokensPerInterval)) * 1000000000
            
            var waitTime = dispatch_time(DISPATCH_TIME_NOW, Int64(waitInterval))
            dispatch_after(waitTime, dispatch_get_main_queue()) {
                self.removeToken(count: count, callback: callback)
            }
        }
        
        // Infinite bucket
        if self.sizeOfBucket == 0 {
            callback(err: nil, remainingTokens: nil)
            return
        }
        
        if count > self.sizeOfBucket {
            callback(err: "Requested more tokens than the bucket"
                + " can contain", remainingTokens: nil)
            return
        }
        
        self.drip()
        
        if count > self.contains {
            return createDispatchLater()
        }
        
        self.contains -= count
        callback(err: nil, remainingTokens: self.contains)
        return
    }
}
