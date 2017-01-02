//
//  TokenBucket.swift
//  RateLimiter
//
//  Created by Erik Little on 11/16/14.
//  Open Source
//

import Dispatch
import Foundation

class TokenBucket {
    let queue: DispatchQueue
    let sizeOfBucket: Double
    let tokensPerInterval: Double
    let interval: Double
    
    var contains = 0.0
    var lastDrip = Date().timeIntervalSince1970
    
    init(sizeOfBucket:Double, tokensPerInterval: Double, interval: String, queue: DispatchQueue = .main) {
        self.sizeOfBucket = sizeOfBucket
        self.tokensPerInterval = tokensPerInterval
        self.contains = sizeOfBucket
        self.queue = queue
        
        switch interval {
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
    }
    
    func drip() {
        if self.tokensPerInterval == 0 {
            self.contains = self.sizeOfBucket
        }
        
        let now = Date().timeIntervalSince1970
        let delta = max(now - self.lastDrip, 0)
        self.lastDrip = now
        let dripAmount = delta * (self.tokensPerInterval / self.interval)
        let newContains = dripAmount + self.contains
        self.contains = min(newContains, self.sizeOfBucket)
    }
    
    func removeTokens(_ count: Double, callback: @escaping ((String?, Double?) -> Void)) {
        // Used if we have to wait for more tokens
        func createDispatchLater() {
            let waitInterval = ceil((count - contains) * (interval / tokensPerInterval)) * 1000000000
            
            let waitTime = DispatchTime.now() + Double(Int64(waitInterval)) / Double(NSEC_PER_SEC)
            
            queue.asyncAfter(deadline: waitTime) {
                self.removeTokens(count, callback: callback)
            }
        }
        
        // Infinite bucket
        guard sizeOfBucket != 0 else {
            return callback(nil, nil)
        }
        
        guard count <= sizeOfBucket else {
            return callback("Requested more tokens than the bucket can contain", nil)
        }
        
        drip()
        
        guard count <= contains else {
            return createDispatchLater()
        }
        
        contains -= count
        callback(nil, contains)
        
        return
    }
}
