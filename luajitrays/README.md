LuaJIT version
==============

These times were taken on a i7-2640M @ 2.8GHz with 8g running Ubuntu 12.10.

The version of LuaJIT was the 2.1.0-alpha.  Last commit:

	  commit 47df3ae5136521da96767e6daed4cdd241de2fa6
	  Author: Mike Pall <mike>
	  Date:   Fri Sep 20 11:36:33 2013 +0200

	      Properly fix loading of embedded bytecode.

Results
-------

C++ times for reference:

	$ time ./cpp 512 512 1 > output_cpp.ppm

	real    0m3.943s
	user    0m3.924s
	sys     0m0.008s

	$ time ./cpp 512 512 > output_cpp.ppm

	real    0m1.727s
	user    0m6.852s
	sys     0m0.004s

Lua times 

(luarays/main.lua, using official interpreter):

	$ time lua5.1 luarays/main.lua 512 512 > output_lua51.ppm

	real    34m29.941s
	user    34m26.377s
	sys     0m0.128s

(luarays/main.lua, using LuaJIT):

	$ time luajit-2.1.0-alpha luarays/main.lua 512 512 > output_luajit.ppm

	real    1m32.228s
	user    1m32.050s
	sys     0m0.012s

(luajitrays/main.lua, using LuaJIT):

	$ time luajit-2.1.0-alpha luajitrays/main.lua 512 512 > output_luajit2.ppm

	real    0m20.534s
	user    0m20.489s
	sys     0m0.000s

About
-----

The luarays version is a straight forward transliteration of the cpp version with some lua-fications.

The luajitrays version modifiies the luarays version by using ffi to make a 3d vector type.

Neither Lua nor LuaJIT can take advantage of multiple concurrent hardware threads so all times are for a single thread.  To achieve concurrency using Lua[JIT] the ray trace could be broken into segments which are rendered using multiple processessors and stitched together when all complete.


