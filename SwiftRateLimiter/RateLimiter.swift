//
//  RateLimiter.swift
//  RateLimiter
//
//  Created by Erik Little on 11/16/14.
//  Open Source
//

import Foundation

class RateLimiter: NSObject {
    let bucket:TokenBucket!
    var intervalStart = NSDate().timeIntervalSince1970
    var tokensThisInterval = 0.0
    var firesImmediatly = false
    
    init(tokensPerInterval:Double, interval:AnyObject, firesImmediatly:Bool = false) {
        super.init()
        self.bucket = TokenBucket(sizeOfBucket: tokensPerInterval,
            tokensPerInterval: tokensPerInterval, interval: interval)
        self.bucket.contains = tokensPerInterval
        
        self.firesImmediatly = firesImmediatly
    }
    
    func removeTokens(#count:Double, callback:((err:String?, remainingTokens:Double?) -> Void)) {
        
        if (count > self.bucket.sizeOfBucket) {
            callback(err: "Requested more tokens than the bucket"
                + " can contain", remainingTokens: nil)
            return
        }
        
        let now = NSDate().timeIntervalSince1970
        if (now - self.intervalStart >= Double(self.bucket.interval)) {
            self.intervalStart = now
            self.tokensThisInterval = 0
        }
        
        if (count > (self.bucket.tokensPerInterval - self.tokensThisInterval)) {
            if (self.firesImmediatly) {
                return callback(err: nil, remainingTokens: -1)
            }
            var waitInterval = dispatch_time_t(ceil(self.intervalStart + Double(self.bucket.interval) - now) * 1000000000)
            dispatch_after(waitInterval, dispatch_get_main_queue()) {
                func afterBucketRemove(err:String?, tokensRemaining:Double?) {
                    if (err != nil) {
                        callback(err: err, remainingTokens: nil)
                        return
                    }
                    self.tokensThisInterval += count
                    callback(err: nil, remainingTokens: tokensRemaining)
                }
                
                self.bucket.removeToken(count: count, callback: afterBucketRemove)
            }
            return
        }
        
        func afterBucketRemove(err:String?, tokensRemaining:Double?) {
            if (err != nil) {
                callback(err: err, remainingTokens: nil)
                return
            }
            self.tokensThisInterval += count
            callback(err: nil, remainingTokens: tokensRemaining)
        }
        
        return self.bucket.removeToken(count: count, callback: afterBucketRemove)
    }
    
    func getTokens() -> Double {
        self.bucket.drip()
        return self.bucket.contains
    }
}