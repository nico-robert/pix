# 02-Jun-2024 : v1.0 : Initial example

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set fp [open [file join [file dirname [info script]] data tiger.svg] r]
set data [read $fp]
close $fp

set svg [pix::svg::parse $data]
set image [pix::svg::toImage $svg]

set p [image create photo]
label .l1 -image $p -borderwidth 0
pack .l1
pix::drawSurface $image $p
update
