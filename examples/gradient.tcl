# From Pixie examples folder (https://github.com/treeform/pixie/tree/master/examples)
# ported to Tcl for package pix.

# 02-Jun-2024 : v1.0 : Initial example
# 22-Jun-2024 : v2.0 : pass <paint> options to configure proc

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set image [pix::img::new {200 200}]
pix::img::fill $image "rgba(255, 255, 255, 1)"

set paint [pix::paint::new "RadialGradientPaint"]
pix::paint::configure $paint {
    gradientHandlePositions {{100 100} {200 100} {100 200}}
    gradientStops {{{1 0 0 1} 0} {{1 0 0 0.15625} 1}}
}

set svg {
    M 20 60
    A 40 40 90 0 1 100 60
    A 40 40 90 0 1 180 60
    Q 180 120 100 180
    Q 20 120 20 60
    z
}

pix::img::fillPath $image $svg $paint

set p [image create photo]
pix::drawSurface $image $p

label .l1 -image $p -borderwidth 0
pack .l1 -fill both -expand 1