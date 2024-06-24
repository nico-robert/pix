# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example
# 22-Jun-2024 : v2.0 : - Rename proc 'pix::img::read' by 'pix::img::readImage'.
#                      - Pass <paint> options to 'pix::paint::configure' proc.               

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set file [file join [file dirname [info script]] data mandrill.png]

set image [pix::img::new {200 200}]
pix::img::fill $image "white"

set path [pix::path::new]
pix::path::polygon $path {100 100} 70 8

set paint [pix::paint::new "TiledImagePaint"]
set f [pix::img::readImage $file]

set mat3 {
    0.08 0.0 0.0
    0.0 0.08 0.0
    0.0 0.0 1.0
}

pix::paint::configure $paint [list image $f imageMat $mat3]
pix::img::fillPath $image $path $paint

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1