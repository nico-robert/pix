pix - 2D graphics library
================
Tcl/Tk wrapper around [Pixie](https://github.com/treeform/pixie), a full-featured 2D graphics library written in Nim.
![Photo gallery](examples/pix.png)

Compatibility :
-------------------------
- **Tcl/Tk 8.6** (Only tested with Tcl/Tk _8.6.14_).

Platforms :
-------------------------
- MacOS 14 x64
- Windows 10 x64
- Linux x64

Source distributions and binary packages can be downloaded [here](https://github.com/nico-robert/pix/releases).

Example :
-------------------------
```tcl
package require pix

# Init 'context' with size + color.
set ctx [pix::ctx::new {200 200} "white"]

# Style first rectangle.
pix::ctx::fillStyle $ctx "rgba(0, 0, 255, 0.5)" ; # blue
pix::ctx::fillRect $ctx {10 10} {100 100}

# Style second rectangle.
pix::ctx::fillStyle $ctx "rgba(255, 0, 0, 0.5)" ; # red
pix::ctx::fillRect $ctx {50 50} {100 100}

# Save context in a file (*.png|*.bmp|*.jpeg|*.qoi|*.ppm)
pix::ctx::writeFile $ctx rectangle.png

# Or display in label by example
set p [image create photo]
pix::drawSurface $ctx $p
label .l -image $p ; pack .l

```
See **[examples folder](/examples)** for more demos.

Documentation :
-------------------------
A large part of the `pix` [documentation](http://htmlpreview.github.io/?https://github.com/nico-robert/pix/blob/master/doc/pix.html) comes from the [Pixie API](https://treeform.github.io/pixie/) and source files. 

#### Currently API tested and supported are :
- [x] context
- [x] font
- [x] image
- [x] paint
- [x] path
- [x] svg

Inspiration Nim to Tcl C API :
-------------------------
- [tclstubs-nimble](https://github.com/mpcjanssen/tclstubs-nimble)

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
