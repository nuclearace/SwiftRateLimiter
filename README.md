SwiftRateLimiter
================

Token Bucket based rate limiter

ex. `let rl = RateLimiter(tokensPerInterval: 10, interval: "second")`

or a token bucket `let tb = TokenBucket(sizeOfBucket: 10, tokensPerInterval: 1, interval: "second")`

Use removeTokens to queue rate limited functions

```
// Using trailing closures

rl.removeTokens(count: 5) {err, tokensRemaining in
    println("Should do first rate limit")
    println(tokensRemaining!)
}

rl.removeTokens(count: 9) {err, tokensRemaining in
    println("Should do second rate limit")
    println(tokensRemaining!)
}

// Error, requesting more tokens than the bucket can contain
rl.removeTokens(count: 11) {err, tokensRemaining in
    println(err)
}
```

To install just copy the SwiftRateLimiter folder to your project.
