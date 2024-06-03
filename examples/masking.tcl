# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
set lines [pix::img::new {200 200}]
set mask  [pix::img::new {200 200}]

pix::img::fill $lines #FC427B
pix::img::fill $image "white"

set ctx [pix::ctx::new $lines]
pix::ctx::strokeStyle $ctx "#F8D1DD"
pix::ctx::lineWidth $ctx 30

pix::ctx::strokeSegment $ctx {25 25} {175 175}
pix::ctx::strokeSegment $ctx {25 175} {175 25}

set svg {
    M 20 60
    A 40 40 90 0 1 100 60
    A 40 40 90 0 1 180 60
    Q 180 120 100 180
    Q 20 120 20 60
    z
}

pix::img::fillPath $mask $svg "red"
pix::img::draw $lines $mask "MaskBlend"
pix::img::draw $image $lines

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1
