## 1.5.2

 - Add support for `disconnect!` method passthrough

## 1.5.1

 - Add support for `UNWATCH` command
 - Add support for `REDIS_NAMESPACE_QUIET` environment variable

## 1.5.0

 - Fix `brpop`
 - Relax dependency of redis-rb to enable users to use redis-rb 3.1
 - Add support for HyperLogLog family of commands (`PFADD`, `PFCOUNT`, `PFMERGE`)
 - Add (1.x -> 2.x) deprecations and ability to enforce them before upgrading.

## 1.4.1

 - Fixed the build for 1.8.7

## 1.4.0

 - Add support for `SCAN` family of commands (`HSCAN`, `SSCAN`, `ZSCAN`)
 - Add support for redis-rb's `scan_each` method and friends

## 1.3.2

 - Fix #68: Capital commands (e.g. redis.send('GET', 'foo'))
 - Fix #67: Nested namespace vs. `eval` command
 - Fix #65: Require redis ~> 3.0.4 for upstream bugfix
 - Feature: Resque::Namespace::VERSION constant

## 1.3.1

 - Fix: (Security) don't proxy `exec` through `#method_missing`
 - Fix #62: Don't try to remove namespace from `Redis::Future`
 - Fix #61: Support `multi` with no block
 - Feature #58: Support `echo`, `exec`, `strlen` commands

## 1.3.0

Features:
  - Added commands: `multi`, `pipelined`, `mapped_mset`, and `mapped_msetnx`
  - Added temporary namespaces that last for the duration of a block
  - Unknown commands now warn
  - Added `mapped_mset` command

Also lots of bug fixes.

## 1.2.1

Features:
  - make redis connection accessible as a reader

## 1.2.0

Features:
  - added mapped_hmset (@hectcastro, #32)
  - added append,brpoplpush,getbit,getrange,linsert,lpushx,rpushx,setbit,setrange (@yaauie, #33)
  - use Redis.current as default connection (@cldwalker, #29)
  - support for redis 3.0.0 (@czarneckid, #39)
