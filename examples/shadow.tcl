# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
pix::img::fill $image "white"

set path [pix::path::new]
pix::path::polygon $path {100 100} 70 8

set polygonImage [pix::img::new {200 200}]
pix::img::fillPath $polygonImage $path "white"

set shadow [pix::img::shadow $polygonImage {offset {2 2} spread 2 blur 10 color "rgba(0,0,0,0.85)"}]

pix::img::draw $image $shadow
pix::img::draw $image $polygonImage

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1