# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set ctx [pix::ctx::new {200 200} "white"]

pix::ctx::fillStyle $ctx "rgba(255, 0, 0, 1)"
pix::ctx::fillRect $ctx {50 50} {100 100}

set p [image create photo]
pix::drawSurface $ctx $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1

