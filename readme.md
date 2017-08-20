# Creating Solid APIs with Lua

*Lua and C code examples that illustrate C/Lua integration.*

These code samples were written as companions to the O'Reilly
book
![*Creating Solid APIs with Lua*](https://www.safaribooksonline.com/library/view/creating-solid-apis/9781491986301/).
The samples are built up chapter-by-chapter, and focus on a particular
game called *EatyGuy*, which looks like this:

![](https://github.com/tylerneylon/APIsWithLua/raw/master/img/screenshot.png)

This game is text-based in order to enable simple graphics that work across
platforms yet don't require any libraries.
The code has runs on macOS, Ubuntu,
and Windows.

Run `make` from the root repo directory to build all the examples.
The built products are created in each chapter's directory
(`ch1`, `ch2`, and so on). The game examples can be run by, for
example, in `ch6`, typing the command `./eatyguy10` (each chapter
has its own version of the game).
Use the arrow keys to move your character around, and press `q` to quit.

Many more details are provided in the book! :)

## Table of Contents

This section outlines the flow of content
across the chapters of the book and corresponding
subdirectories of this repo.
Many of these topics center on learning Lua's
C API.

* **Chapter 1** Running a Lua Script from C

  *This chapter covers acquiring Lua's source as
   well as running Lua scripts from C.*

* **Chapter 2** Calling C from Lua

  *Writing C functions that Lua can call.*

* **Chapter 3** Using Lua Values in C

  *Manipulating Lua primitives and tables
   from C.*

* **Chapter 4** Making Your API Classy

  *A review of Lua classes, and
   how C works with Lua's `userdata` type
   to make safe, class-like objects in Lua.*

* **Chapter 5** Detecting Errors

  *Working with Lua errors (similar to exceptions)
   from C; making it easier to notice certain
   common mistakes.*

* **Chapter 6** Sandboxing User Scripts

  *Limiting the API and resource access of user
  scripts, including fine-grained constraints
  on CPU and memory consumption.*
