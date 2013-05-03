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
