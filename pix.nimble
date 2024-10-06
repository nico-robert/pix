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
# 06-oct-2024 : v0.3
               # Doc : Jpeg format is not supported for pix::ctx::writeFile.
               # Rename pix::parsePath to pix::pathObjToString
               # Add pix::svgStyleToPathObj proc (convert SVG path string to path object)
               # Add pix::rotMatrix proc (matrix rotation)
               # Fix bug `pix::path::fillOverlaps` bad arguments, used.
               # Code refactoring.

version     = "0.3"
author      = "Nicolas ROBERT"
description = "Tcl wrapper around Pixie (https://github.com/treeform/pixie), a full-featured 2D graphics library written in Nim."
license     = "MIT"

srcDir = "src"

# Dependencies
requires "nim   == 2.0.6"
requires "pixie == 5.0.7"

# task
task tclWrapper, "Generate pix Tcl library.":

  proc compile(libName: string, flags= "") =
    exec "nim c " & flags & " --path:tclpix --path:tkpix -d:release --app:lib --out:" & libName & " src/pix.nim"

  when defined(windows):
    compile "./win32-x86_64/pix"&version&".dll", "--cc:gcc --passL:-s --passL:-static-libgcc"

  elif defined(macosx):
    compile "./macosx-x86_64/libpix"&version&".dylib"

  elif defined(linux):
    compile "./linux-x86_64/libpix"&version&".so"