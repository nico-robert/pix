# Copyright (c) 2024-2025 Nicolas ROBERT.
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
# 06-Oct-2024 : v0.3
               # Doc : Jpeg format is not supported for pix::ctx::writeFile.
               # Rename pix::parsePath to pix::pathObjToString
               # Add pix::svgStyleToPathObj proc (convert SVG path string to path object)
               # Add pix::rotMatrix proc (matrix rotation)
               # Fix bug `pix::path::fillOverlaps` bad arguments, used.
               # Code refactoring.
# 02-Mar-2025 : v0.4
               # Support for `Tcl/Tk9`.
               # Adds binary for MacOS `arm64`.
               # Adds `X11` for purpose testing.
               # Code refactoring ++.

version     = "0.4"
author      = "Nicolas ROBERT"
description = "Tcl wrapper around Pixie (https://github.com/treeform/pixie), a full-featured 2D graphics library written in Nim."
license     = "MIT"

srcDir = "src"

# Dependencies
requires "nim == 2.0.6"
requires "pixie == 5.0.7"

# task
task pixTclTkBindings, "Generate pix Tcl library.":

  proc compile(libName: string, flags= "") =
    exec "nim c " & flags & " -d:release --app:lib --out:" & libName & " src/pix.nim"

  when defined(windows):
    compile "./win32-x86_64/pix9-"&version&".dll", "-d:tcl9"
    compile "./win32-x86_64/pix8-"&version&".dll"

  elif defined(macosx):
    var folder = "macosx-x86_64"
    when defined(arm64): 
      folder = "macosx-arm"
    compile "./"&folder&"/lib9pix"&version&".dylib", "-d:tcl9"
    compile "./"&folder&"/lib8pix"&version&".dylib"

  elif defined(linux):
    compile "./linux-x86_64/lib9pix"&version&".so", "-d:tcl9"
    compile "./linux-x86_64/lib8pix"&version&".so"