//
//  RateLimiter.swift
//  RateLimiter
//
//  Created by Erik Little on 11/16/14.
//  Open Source
//

import Dispatch
import Foundation

public class RateLimiter {
    let bucket: TokenBucket
    let queue: DispatchQueue
    
    var intervalStart = Date().timeIntervalSince1970
    var tokensThisInterval = 0.0
    var firesImmediatly = false
    
    public init(tokensPerInterval: Double, interval: String, firesImmediatly: Bool = false, queue: DispatchQueue = .main) {
        self.bucket = TokenBucket(sizeOfBucket: tokensPerInterval,
            tokensPerInterval: tokensPerInterval, interval: interval)
        self.bucket.contains = tokensPerInterval
        self.firesImmediatly = firesImmediatly
        self.queue = queue
    }
    
    public func removeTokens(_ count: Double, callback: @escaping ((String?, Double?) -> Void)) {
        
        if count > bucket.sizeOfBucket {
            callback("Requested more tokens than the bucket can contain", nil)
            
            return
        }
        
        let now = Date().timeIntervalSince1970
        
        if now - intervalStart >= bucket.interval {
            self.intervalStart = now
            self.tokensThisInterval = 0
        }
        
        guard count <= bucket.tokensPerInterval - tokensThisInterval else {
            
            if firesImmediatly {
                return callback(nil, -1)
            }
            
            
            let time = ceil(intervalStart + bucket.interval - now) * Double(1000000000)
            let waitInterval = DispatchTime(uptimeNanoseconds: UInt64(time))
            
            queue.asyncAfter(deadline: waitInterval) {
                func afterBucketRemove(_ err: String?, tokensRemaining: Double?) {
                    if err != nil {
                        callback(err, nil)
                        
                        return
                    }
                    
                    self.tokensThisInterval += count
                    
                    callback(nil, tokensRemaining)
                }
                
                self.bucket.removeTokens(count, callback: afterBucketRemove)
            }
            
            return
        }
        
        func afterBucketRemove(_ err:String?, tokensRemaining:Double?) {
            if err != nil {
                callback(err, nil)
                return
            }
            
            self.tokensThisInterval += count
            callback(nil, tokensRemaining)
        }
        
        return bucket.removeTokens(count, callback: afterBucketRemove)
    }
    
    public func getTokens() -> Double {
        self.bucket.drip()
        return bucket.contains
    }
}
