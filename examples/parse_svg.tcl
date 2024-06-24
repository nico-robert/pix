# 02-Jun-2024 : v1.0 : Initial example
# 22-Jun-2024 : v2.0 : Rename proc 'pix::svg::toImage' by 'pix::svg::newImage'.
# 24-Jun-2024 : v3.0 : Replace 'tiger.svg' by 'hello.svg' file.

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set fp [open [file join [file dirname [info script]] data hello.svg] r]
set data [read $fp]
close $fp

set svg [pix::svg::parse $data {200 200}]
set image [pix::svg::newImage $svg]

set p [image create photo]
label .l1 -image $p -borderwidth 0 ; pack .l1
pix::drawSurface $image $p