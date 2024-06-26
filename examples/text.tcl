# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example
# 22-Jun-2024 : v2.0 : - Rename proc 'pix::font::read' by 'pix::font::readFont'.
#                      - Use dict options instead of parameters for 'pix::font::typeset' proc. 

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
pix::img::fill $image "white"

set font [pix::font::readFont [file join [file dirname [info script]] data Roboto-Regular_1.ttf]]
pix::font::size $font 20
pix::font::color $font "rgb(255,0,0)"


set text "Typesetting is the arrangement and composition of text in graphic design and publishing in both digital and traditional medias."
set arrangement [pix::font::typeset $font $text {
        bounds {180 180} hAlign "LeftAlign" vAlign "TopAlign" wrap "true"
    }
]

set mat3 {
    1.0 0.0 0.0
    0.0 1.0 0.0
    10.0 10.0 1.0
}

pix::img::fillText $image $arrangement $mat3

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1