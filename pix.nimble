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
# 03-Apr-2025 : v0.5
               # Try to improve the comments for the documentation.
               # Fixes bug for `pix::ctx::clip` + `pix::ctx::isPointInPath`
               # procedures when args count was equal to 2.
               # Adds `pix::toBinary` procedure.
               # Adds `pix::getKeys` procedure for image & context, useful for debugging.
               # Adds procedures for working with `matrices` (translate, scale, multiply).
               # Adds `useMalloc` flag for `nim c` command.
               # Adds another test for fonts (works only with Tcl9)
               # Reworks tests files (Compare the result with pix::img::diff proc).
               # Simplification of some procedures + cosmetic changes.
# 07-Sep-2025 : v0.6
               # Fix doc : Matrix values are in column order.
               # Adds HSL color.
               # Redefining Tcl/Tk procedures for transition to Nim version `2.2.4`.
               # Fixes `setLineDash` command to get around pixie's problem when Tcl list is not even.
               # Try to improve the `X11` binding.
               # Cosmetic changes.

version     = "0.6"
author      = "Nicolas ROBERT"
description = "Tcl wrapper around Pixie (https://github.com/treeform/pixie), " &
              "a full-featured 2D graphics library written in Nim."
license     = "MIT"
srcDir      = "src"

# Dependencies
requires "nim >= 2.0.6"
requires "pixie >= 5.1.0"

# Task definition for generating the pix Tcl/Tk library
# Compile bindings for 2 versions of Tcl/Tk.
task pixTclTkBindings, "Generate pix Tcl library.":

  proc extractPixVersionFromNimble(): string =
    let nimbleContent = readFile("pix.nimble")

    for line in nimbleContent.splitLines():
      let trimmedLine = line.strip()
      if trimmedLine.startsWith("version"):
        let parts = trimmedLine.split("=")
        if parts.len >= 2:
          return parts[1].strip().replace("\"", "")

    quit("pix(error): Unable to extract version from 'pix.nimble' file.")

  proc generatePixPkgIndexFile(version: string) =
    let templatePath = "src/pkgIndex.tcl.in"
    if not fileExists(templatePath):
      quit("pix(error): Unable to find template file: " & templatePath)

    let templateContent = readFile(templatePath)
    let finalContent = templateContent.replace("@PACKAGE_VERSION@", version)

    # Write the final content to the output file
    let outputPath = "pkgIndex.tcl"
    try:
      writeFile(outputPath, finalContent)
    except IOError as e:
      quit("pix(error): Unable to write to file: " & outputPath)

  proc compile(libName: string, flags= "") =
    exec "nim c " & flags & " -d:strip -d:useMalloc -d:release --out:" & libName & " src/pix.nim"

  proc getArchFolder(): tuple[folder: string, suffix: string, ext: string] =
    when defined(arm64):
      result.suffix = "arm"
    else:
      result.suffix = "x86_64"

    when defined(windows):
      result.folder = "win32-" & result.suffix
      result.ext    = ".dll"
    elif defined(macosx):
      result.folder = "macosx-" & result.suffix
      result.ext    = ".dylib"
    elif defined(linux):
      result.folder = "linux-" & result.suffix
      result.ext    = ".so"

  let arch = getArchFolder()

  # Generate pix Tcl/Tk library:
  for vtcl in ["8", "9"]:
    let tclFlags = "-d:tcl" & vtcl

    when defined(windows):
      compile "./" & arch.folder & "/pix" & vtcl & "-" & version & arch.ext, tclFlags
    elif defined(macosx) or defined(linux):
      compile "./" & arch.folder & "/lib" & vtcl & "pix" & version & arch.ext, tclFlags
    else:
      quit("pix(error): Unsupported operating system!")

  # Generate pkgIndex.tcl:
  let currentVersion = extractPixVersionFromNimble()
  generatePixPkgIndexFile(currentVersion)