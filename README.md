SwiftRateLimiter
================

Token Bucket based rate limiter

Use removeTokens to queue rate limited functions.

If there are not enough tokens in the bucket to fulfill the request, it will dispatch the callback when there are enough. Alternatively, if you create the rate limiter with the optional parameter `firesImmediatly` eg. `let rl = RateLimiter(tokensPerInterval: 10, interval: "second", firesImmediatly: true)` it will instead execute callbacks immediately.

```swift
let rl = RateLimiter(tokensPerInterval: 10, interval: "second")

// Using trailing closures
rl.removeTokens(count: 5) {err, tokensRemaining in
    println("Should do first rate limit")
    println(tokensRemaining!)
}

// Callback will execute after 1 seconds
rl.removeTokens(count: 9) {err, tokensRemaining in
    println("Should do second rate limit")
    println(tokensRemaining!)
}

// Error, requesting more tokens than the bucket can contain
rl.removeTokens(count: 11) {err, tokensRemaining in
    println(err)
}

// A token bucket
let tb = TokenBucket(sizeOfBucket: 10, tokensPerInterval: 1, interval: "second")

tb.removeToken(count: 10) {err, tokensRemaining in
    println(tokensRemaining)
}

// Bucket is drained
// Callback will execute after 2 seconds seconds
tb.removeToken(count: 2) {err, tokensRemaining in
    println(tokensRemaining)
}

// Callback will execute after 12 seconds seconds
tb.removeToken(count: 10) {err, tokensRemaining in
    println(tokensRemaining!)
}
```

To install just copy the SwiftRateLimiter folder to your project.
