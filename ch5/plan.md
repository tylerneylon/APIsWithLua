# Ideas for what may be covered in chapter 4.

* strict.lua
* the call() function in C
* the dumpstack() function in C
* how pcall works and reporting errors from Lua
* getting stack traces with the C API
* using asserts in C and Lua
* checking argument types

# What can happen in EatyGuy?

* Decouple the game engine from the game (error check that a Lua file exists and
  has good syntax)
  + So, show good results when the file doesn't exist, and when it has syntax
    or runtime errors
* Rewrite C to use call()
  + Hopefully call (or pcall()?) can do something smart that results in good
    error messages
* Show how dumpstack() might help debug a stack-usage error in C.
  (The easy example I can think of is loading "eatyguy" within the C event loop.

