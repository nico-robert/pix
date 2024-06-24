# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 22-Jun-2024 : v1.0 : Initial example

proc newFont {typeface size color} {
    set font [pix::font::newFont $typeface]

    pix::font::configure $font [list \
        size  $size \
        color $color \
    ]

    return $font
}

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
pix::img::fill $image "rgba(255, 255, 255, 255)"

set file [file join [file dirname [info script]] data Ubuntu-Regular_1.ttf]
set typeface [pix::font::readTypeface $file]

lappend spans [pix::font::newSpan [newFont $typeface 12 {0.78125 0.78125 0.78125 1}] "verb \[with object\] "]
lappend spans [pix::font::newSpan [newFont $typeface 36 {0 0 0 1}] "strallow\n"]
lappend spans [pix::font::newSpan [newFont $typeface 13 {0 0.5 0.953125 1}] "\nstral·low\n"]
lappend spans [pix::font::newSpan [newFont $typeface 14 {0.3125 0.3125 0.3125 1}] "\n1. free (something) from restrictive restrictions \"the regulations are intended to strallow changes in public policy\" "]


set typeset [pix::font::typeset $spans {bounds {180 180}}]
pix::img::fillText $image $typeset {1 0 0 0 1 0 10 10 1}

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1