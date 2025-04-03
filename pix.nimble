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
description = "Tcl wrapper around Pixie (https://github.com/treeform/pixie), " &
              "a full-featured 2D graphics library written in Nim."
license     = "MIT"
srcDir      = "src"

# Dependencies
requires "nim >= 2.0.6"
requires "pixie == 5.0.7"

# Task definition for generating the pix Tcl/Tk library
# Compile bindings for 2 versions of Tcl/Tk.
task pixTclTkBindings, "Generate pix Tcl library.":

  proc compile(libName: string, flags= "") =
    exec "nim c " & flags & " -d:strip -d:useMalloc -d:release --out:" & libName & " src/pix.nim"

  proc getArchFolder(): tuple[folder: string, prefix: string, ext: string] =
    when defined(arm64):
      result.prefix = "arm"
    else:
      result.prefix = "x86_64"

    when defined(windows):
      result.folder = "win32-" & result.prefix
      result.ext    = ".dll"
    elif defined(macosx):
      result.folder = "macosx-" & result.prefix
      result.ext    = ".dylib"
    elif defined(linux):
      result.folder = "linux-" & result.prefix
      result.ext    = ".so"

  let arch = getArchFolder()

  for vtcl in ["8", "9"]:
    let tclFlags = "-d:tcl" & vtcl

    when defined(windows):
      compile "./" & arch.folder & "/pix" & vtcl & "-" & version & arch.ext, tclFlags

    elif defined(macosx) or defined(linux):
      compile "./" & arch.folder & "/lib" & vtcl & "pix" & version & arch.ext, tclFlags
      
    else:
      echo "pix(error): Unsupported operating system!"
      quit(1)