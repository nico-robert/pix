# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example
# 04-Jun-2024 : v2.0 : bad definition mask.

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set file [file join [file dirname [info script]] data trees.png]

set trees [pix::img::read $file]
set blur  [pix::img::copy $trees]
set image [pix::img::new {200 200}]

pix::img::fill $image "white"

set path [pix::path::new]
pix::path::polygon $path {100 100} 70 6

set mask [pix::img::new {200 200}]
pix::img::fillPath $mask $path "rgba(255,255,255,1)"

pix::img::blur $blur 20

pix::img::draw $blur $mask "MaskBlend"

pix::img::draw $image $trees
pix::img::draw $image $blur


set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1