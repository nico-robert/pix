# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
# pix - Tcl wrapper around Pixie, a full-featured 2D graphics library written in Nim.
# (https://github.com/treeform/pixie)

# 03-Jun-2024 : v0.1 Initial release
# 25-Jun-2024 : v0.2
               # Add `font` namespace + test file.
               # Add `image` namespace + test file.
               # Add `paint` namespace + test file.
               # Add `path` namespace + test file.
               # Rename `pix::ctx::getSize` by `pix::ctx::get` 
               # Rename `pix::img::read` by `pix::img::readImage`
               # Rename `pix::font::read` by `pix::font::readFont`
               # Add documentation based on Pixie API reference.
               # Add binary for Linux.
               # Code refactoring.

version     = "0.2"
author      = "Nicolas ROBERT"
description = "Tcl wrapper around Pixie (https://github.com/treeform/pixie), a full-featured 2D graphics library written in Nim."
license     = "MIT"

srcDir = "src"

# Dependencies
requires "nim   == 2.0.6"
requires "pixie == 5.0.7"

# task
task bindings, "Generate Tcl wrapper":

  proc tclLibCompile(libName: string, flags: string) =
    exec "nim c " & flags & " --path:tclpix --path:tkpix -d:release --app:lib --out:" & libName & " src/pix.nim"

  when defined(windows):
    tclLibCompile "./win32-x86_64/pix"&version&".dll" ,
                  "--cc:'gcc' --passL:'-s -static-libgcc c:/dev/Tcl86/lib/tclstub86.lib c:/dev/Tcl86/lib/tkstub86.lib'"

  elif defined(macosx):
    tclLibCompile "./macosx-x86_64/libpix"&version&".dylib" ,
                  "--passL:'/usr/local/Cellar/tcl-tk/8.6.14/lib/libtclstub8.6.a /usr/local/Cellar/tcl-tk/8.6.14/lib/libtkstub8.6.a'"

  elif defined(linux):
    tclLibCompile "./linux-x86_64/libpix"&version&".so" ,
                  "--passL:'/usr/lib/x86_64-linux-gnu/libtclstub8.6.a /usr/lib/x86_64-linux-gnu/libtkstub8.6.a'"

  else:
    echo "Os not supported."