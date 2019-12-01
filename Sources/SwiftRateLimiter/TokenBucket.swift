//
//  TokenBucket.swift
//  RateLimiter
//
//  Created by Erik Little on 11/16/14.
//  Open Source
//

import Dispatch
import Foundation

public class TokenBucket {
    public let sizeOfBucket: Double
    public let tokensPerInterval: Double
    public let interval: Double

    public var contains = 0.0

    let queue: DispatchQueue

    var lastDrip = Date().timeIntervalSince1970

    public init(sizeOfBucket: Double, tokensPerInterval: Double, interval: RateInterval, queue: DispatchQueue = .main) {
        self.sizeOfBucket = sizeOfBucket
        self.tokensPerInterval = tokensPerInterval
        self.contains = sizeOfBucket
        self.queue = queue
        self.interval = interval.rawValue
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

    public func removeTokens(_ count: Double, callback: @escaping (Double) -> ()) {
        // Used if we have to wait for more tokens
        func createDispatchLater() {
            queue.asyncAfter(deadline: DispatchTime.now() + ceil((count - contains) * (interval / tokensPerInterval))) {
                self.removeTokens(count, callback: callback)
            }
        }

        // Infinite bucket
        guard sizeOfBucket != 0 else {
            return callback(.infinity)
        }

        guard count <= sizeOfBucket else {
            return callback(-Double.infinity)
        }

        drip()

        guard count <= contains else {
            return createDispatchLater()
        }

        contains -= count
        callback(contains)

        return
    }
}

public enum RateInterval : Double {
    case second = 1
    case minute = 60
    case hour = 3600
    case day = 86400
}
