pix - 2D graphics library
================
Tcl/Tk wrapper around [Pixie](https://github.com/treeform/pixie), a full-featured 2D graphics library written in 👑 [Nim](https://nim-lang.org).

<p align="center">
  <img src="docs/assets/pix-dark.png#gh-dark-mode-only">
  <img src="docs/assets/pix.png#gh-light-mode-only">
</p>

Compatibility :
-------------------------
- Tcl/Tk 8.6 & 9.0

Platforms :
-------------------------
- MacOS (x64 / arm64)
- Windows x64
- Linux x64

Source distributions and binary packages can be downloaded [here](https://github.com/nico-robert/pix/releases) for the platforms mentioned
above.

> [!NOTE]  
> I have mainly tested this package on Windows and MacOs x64 with version **8.6.16** and **9.0.1** of Tcl/Tk, it should work on Linux and
MacOS arm (I hope so !)

Build :
-------------------------
If you want to build `pix` from source, please refer to [BUILDING.md](BUILDING.md) for detailed compilation instructions.

Example :
-------------------------
```tcl
package require pix

# Init 'context' with size + color.
set ctx [pix::ctx::new {200 200} "white"]

# Style first rectangle.
pix::ctx::fillStyle $ctx "rgb(0, 0, 255)" ; # blue color
pix::ctx::fillRect $ctx {10 10} {100 100}

# Style second rectangle.
pix::ctx::fillStyle $ctx "rgba(255, 0, 0, 0.5)" ; # red color with alpha 50%
pix::ctx::fillRect $ctx {50 50} {100 100}

# Save context in a image file (*.png|*.bmp|*.qoi|*.ppm)
pix::ctx::writeFile $ctx rectangle.png

# Or display in label by example :
set p [image create photo]
pix::drawSurface $ctx $p
label .l -image $p
pack .l
```
See **[examples folder](/examples)** for more demos.

Documentation :
-------------------------
A large part of the `pix` [documentation](https://nico-robert.github.io/pix/) comes from the [Pixie API](https://treeform.github.io/pixie/) and source files. 

#### Currently API tested and supported are :
| API        | Description
| ------     | ------
| _context_  | This namespace provides a 2D API commonly used on the web.
| _font_     | This namespace allows you to write text, load fonts.
| _image_    | Crop, resize, blur image and much more.
| _paint_    | This namespace plays with colors.
| _path_     | Vector Paths.
| _svg_      | Parse, render SVG (namespace pretty limited)

Acknowledgments :
-------------------------
- [tclstubs-nimble](https://github.com/mpcjanssen/tclstubs-nimble) (MIT)
- [Pixie](https://github.com/treeform/pixie) (MIT)

License :
-------------------------
**pix** is covered under the terms of the [MIT](LICENSE) license.

Release :
-------------------------
*  **03-Jun-2024** : 0.1
    - Initial release.
*  **25-Jun-2024** : 0.2
    - Add `font` namespace + test file.
    - Add `image` namespace + test file.
    - Add `paint` namespace + test file.
    - Add `path` namespace + test file.
    - Rename `pix::ctx::getSize` by `pix::ctx::get` 
    - Rename `pix::img::read` by `pix::img::readImage`
    - Rename `pix::font::read` by `pix::font::readFont`
    - Add documentation based on Pixie API reference.
    - Add binary for Linux.
    - Code refactoring.
*  **06-Oct-2024** : 0.3
    - Doc : Jpeg format is not supported for pix::ctx::writeFile.
    - Rename `pix::parsePath` to `pix::pathObjToString`
    - Add `pix::svgStyleToPathObj` proc (convert SVG path string to path object)
    - Add `pix::rotMatrix` proc (matrix rotation)
    - Fix bug `pix::path::fillOverlaps` bad arguments, used.
    - Code refactoring.
*  **02-Mar-2025** : 0.4
    - Support for `Tcl/Tk9`.
    - Adds binary for MacOS `arm64`.
    - Adds `X11` for purpose testing.
    - Code refactoring ++.
*  **03-Apr-2025** : 0.5
    - Try to improve the comments for the documentation.
    - Fixes bug for `pix::ctx::clip` + `pix::ctx::isPointInPath`   
      procedures when args count was equal to 2.
    - Adds `pix::toBinary` procedure.
    - Adds `pix::getKeys` procedure for image & context, useful for debugging.
    - Adds procedures for working with `matrices` (translate, scale, multiply).
    - Adds `useMalloc` flag for `nim c` command.
    - Adds another test for fonts (works only with Tcl9)
    - Reworks tests files (Compare the result with `pix::img::diff` proc).
    - Simplification of some procedures + cosmetic changes.
*  **07-Sep-2025** : 0.6
    - Fix doc : Matrix values are in column order.
    - Adds HSL color.
    - Redefining Tcl/Tk procedures for transition to Nim version `2.2.4`.
    - Fixes `setLineDash` command to get around pixie's problem when Tcl list is not even.
    - Try to improve the `X11` binding.
    - Cosmetic changes.
*  **13-Oct-2025** : 0.7
    - Adds new procedures for playing with colours (mix, darken,...).
    - Improved compilation support.
    - Bump `pixie` to version `5.1.0`.
    - Refactoring matrix3x3 procedure.
    - Fix doc: Matrix values are in row order (I think it's good now!).
