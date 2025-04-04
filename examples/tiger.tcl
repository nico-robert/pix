# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example
# 22-Jun-2024 : v2.0 : rename proc 'pix::img::read' by 'pix::img::readImage'.
# 01-Apr-2025 : v3.0 : Use new `matrix` procedures instead of plain list.

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
pix::img::fill $image "rgba(255, 255, 255, 1)"


set tiger [pix::img::readImage [file join [file dirname [info script]] data tiger.svg]]
pix::img::draw $image $tiger [pix::mulMatrix \
    [pix::transMatrix {100 100}] \
    [pix::scaleMatrix {0.2 0.2}] \
    [pix::transMatrix {-450 -450}] \
]

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1