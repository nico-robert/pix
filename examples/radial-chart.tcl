# 02-Jun-2024 : v1.0 : Initial example

proc progressChart {} {
    global ctx cW cH counter start maxVal p font
    
    set diff [expr {(($counter / 100.) * 3.14 * 2 * 10)}]
    
    pix::ctx::clearRect $ctx {0 0} [list $cW $cH]
    pix::ctx::lineWidth $ctx 15
    pix::ctx::fillStyle $ctx #ff883c
    pix::ctx::textAlign $ctx CenterAlign
    pix::ctx::font $ctx $font
    pix::ctx::fontSize $ctx 25
    pix::ctx::fillText $ctx "$counter%" [list [expr {$cW * 0.5}] [expr {$cH * 0.55}]]
    
    pix::ctx::beginPath $ctx 
    pix::ctx::arc $ctx {100 100} 60 0 [expr {3.14 * 2}] 0
    pix::ctx::strokeStyle $ctx #ddd
    pix::ctx::stroke $ctx
    
    pix::ctx::beginPath $ctx 
    pix::ctx::arc $ctx {100 100} 60 $start [expr {$diff/double(10 + $start)}] 0
    pix::ctx::strokeStyle $ctx #ff883c
    pix::ctx::stroke $ctx
    if {$counter > $maxVal} {
        set counter 0
        return
    }
    
    pix::drawSurface $ctx $p
    
    incr counter
    after 50 progressChart
}

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set font [file join [file dirname [info script]] data Roboto-Regular_1.ttf]
set cW 200
set cH 200
set counter 0
set start 4.72
set maxVal 70
set ctx [pix::ctx::new {200 200} "white"]
set p [image create photo]

label .l1 -image $p -borderwidth 0
pack .l1
update

progressChart