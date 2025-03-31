# Tcl program to generate pix documentation.
# Note : ruff package is required (https://github.com/apnadkarni/ruff)

# Find tcl procedures in pix.nim
proc parsePIxFile {datapix what} {
    foreach line $datapix {
        if {[string match "*: $what,*" $line]} {
            if {[regexp {\"(.+)\"} $line -> match]} {
                return $match
            }
        }
    }
    return {}
}

# Read example file
proc parseExample {file} {
    set fp [open $file]
    set data [split [read $fp] \n]
    close $fp

    set example {}
    foreach line $data {
        if {[string match "*auto_path*" $line] ||
            [string match "*label*" $line] ||
            [string match "*pack .*" $line]} {
            continue
        }

        lappend example $line

    }
    return $example
}

lappend auto_path [file dirname [file dirname [file dirname [info script]]]]
package require ruff 2.5

set dirpix [file dirname [file dirname [info script]]]

# Write pix.ruff
set fp [open [file join [file dirname [info script]] pix.ruff] w+]
puts $fp {
# File generated by pixdoc.tcl
namespace eval ::pix {
    variable _intro {
        # pix - 2D graphics library
        Tcl/Tk wrapper around [Pixie](https://github.com/treeform/pixie), a full-featured 2D graphics library written in [Nim](https://nim-lang.org).

        #### Compatibility
        Tcl/Tk 8.6 & 9.0

        #### Platforms
        * MacOS (x64 / arm64)
        * Windows x64
        * Linux x64

        Source distributions and binary packages can be downloaded [here](https://github.com/nico-robert/pix/releases).

        #### Example
        ```
        package require pix

        # Init 'context' with size + color.
        set ctx [pix::ctx::new {200 200} "white"]

        # Style first rectangle.
        pix::ctx::fillStyle $ctx "rgb(0, 0, 255)" ; # blue color
        pix::ctx::fillRect $ctx {10 10} {100 100}

        # Style second rectangle.
        pix::ctx::fillStyle $ctx "rgba(255, 0, 0, 0.5)" ; # red color with alpha 50%
        pix::ctx::fillRect $ctx {50 50} {100 100}

        # Save context in a image file (*.png|*.bmp|*.qoi|*.ppm)
        pix::ctx::writeFile $ctx rectangle.png

        # Or display in label by example
        set p [image create photo]
        pix::drawSurface $ctx $p
        label .l -image $p
        pack .l
        ```
        See [examples](./pix-examples.html) folder for more demos.

        #### Documentation
        A large part of the `pix` [documentation](http://htmlpreview.github.io/?https://github.com/nico-robert/pix/blob/master/doc/pix.html) comes from the [Pixie API](https://treeform.github.io/pixie/)   
        and source files. 

        #### API
        ** Currently API tested and supported are : **
        *context*  - This namespace provides a 2D API commonly used on the web.
        *font*     - This namespace allows you to write text, load fonts.
        *image*    - Crop, resize, blur image and much more.
        *paint*    - This namespace plays with colors.
        *paths*    - Vector Paths.
        *svg*      - Parse, render SVG (namespace pretty limited)

        #### Acknowledgement:
        * [tclstubs-nimble](https://github.com/mpcjanssen/tclstubs-nimble) (MIT) <br>
        * [Pixie](https://github.com/treeform/pixie) (MIT)
    }
}
}
# Read LICENSE file
set fplic [open [file join $dirpix LICENSE]]
set lic [read $fplic]
close $fplic
set lic [string map {\" '} $lic]
puts $fp "append pix::_intro \{\n#### License\n```\n$lic\n```\n\}"

close $fp

# set fp [open [file join [file dirname [info script]] pix.ruff] r]
# puts [read $fp]
# close $fp

# Read pix.nim to find all tcl procedures 
set fp [open [file join $dirpix src pix.nim]]
set datapix [string map {pixUtils. ""} [split [read $fp] \n]]
close $fp

# List name files.
foreach dirName {
    src src src src src src {src core}
    } name {
    context paint image svg paths font pixutils
    } {

    # Reads source file
    set fp [open [file join $dirpix {*}$dirName $name.nim]]
    set data [split [read $fp] \n]
    close $fp

    set hasProc 0
    set tclproc {}
    set coms {}

    # Writes doc files
    if {$name eq "pixutils"} {
        set _file [file join [file dirname [info script]] utils.ruff]
    } else {
        set _file [file join [file dirname [info script]] $name.ruff]
    }
    
    set fp [open $_file w+]

    set preamble "{}"

    if {$name eq "context"} {
        set ns "ctx"
        set preamble {{
            #### Note
            This namespace provides a 2D API commonly used on the web.\
            For more info, see: [https://developer.mozilla.org/en-US/docs/Web/API/ContextRenderingContext2D]\
            (https://developer.mozilla.org/en-US/docs/Web/API/ContextRenderingContext2D)

            #### Struct Context:
            image         - [img]
            fillStyle     - [paint]
            strokeStyle   - [paint]
            globalAlpha   - double
            lineWidth     - double
            miterLimit    - double
            lineCap       - Enum LineCap
            lineJoin      - Enum LineJoin
            font          - string ## File path to a .ttf or .otf file.
            fontSize      - double
            textAlign     - Enum HorizontalAlignment
            textBaseline  - Enum BaselineAlignment

            #### Enum BaselineAlignment:
            BaselineAlignment - enum
            TopBaseline - &nbsp;
            HangingBaseline - &nbsp;
            MiddleBaseline - &nbsp;
            AlphabeticBaseline - &nbsp;
            IdeographicBaseline - &nbsp;
            BottomBaseline - &nbsp;

        }}
    } elseif {$name eq "font"} {
        set ns "font"
        set preamble {{
            #### Enum HorizontalAlignment:
            HorizontalAlignment  - enum
            LeftAlign            - &nbsp;
            CenterAlign          - &nbsp;
            RightAlign           - &nbsp;

            #### Enum VerticalAlignment:
            VerticalAlignment    - enum
            TopAlign             - &nbsp;
            MiddleAlign          - &nbsp;
            BottomAlign          - &nbsp;

        }}
    } elseif {$name eq "paint"} {
        set ns "paint"
        set preamble {{
            #### Enum PaintKind:
            PaintKind             - enum
            SolidPaint            - &nbsp;
            ImagePaint            - &nbsp;
            TiledImagePaint       - &nbsp;
            LinearGradientPaint   - &nbsp;
            RadialGradientPaint   - &nbsp;
            AngularGradientPaint  - &nbsp;
        }}

    } elseif {$name eq "image"} {
        set ns "img"
    } elseif {$name eq "paths"} {
        set ns "path"
        set preamble {{
            #### Enum Winding rules:
            WindingRule  - enum
            NonZero      - &nbsp;
            EvenOdd      - &nbsp;
            #### Enum Line cap type for strokes:
            LineCap      - enum
            ButtCap      - &nbsp;
            RoundCap     - &nbsp;
            SquareCap    - &nbsp;
            #### Enum Line join type for strokes:
            LineJoin      - enum
            MiterJoin    - &nbsp;
            RoundJoin    - &nbsp;
            BevelJoin    - &nbsp;
        }}

    } elseif {$name eq "svg"} {
        set ns "svg"
        set preamble {"Load, parse, render SVG."}
    } elseif {$name eq "pixutils"} {
        set preamble {"Help procedures."}
    } else {
        set ns $name
    }
    puts $fp "# File generated by pixdoc.tcl"
    if {$name eq "pixutils"} {
        puts $fp "namespace eval ::pix {
            variable _ruff_preamble $preamble
        }"
    } else {
        puts $fp "namespace eval ::pix {
            namespace eval $ns {
                # Ruff documentation
                variable _ruff_preamble $preamble
            }
        }"
    }

    foreach line $data {
        if {[string match "*proc *" $line]} {
            if {[regexp {proc (.+)\(} $line -> match]} {
                set match [string map {* ""} $match] ; # delete export Nim function
                set tclproc [parsePIxFile $datapix $match]
                if {($tclproc eq "") && ($name ne "pixutils")} {
                    error "not possible to find name tcl proc '$match'\
                           for this file $name.nim"
                }
                if {($tclproc eq "") && ($name eq "pixutils")} {
                    set hasProc 0 ; continue
                }
                set hasProc 1
            }
        }
        # Search comments
        if {[string match "*  #*" $line] && $hasProc} {lappend coms $line}

        if {
            ([string match "*try:*" $line] ||
            [string match "*let mess =*" $line] ||
            [string match "* if *:*" $line] ||
            [string match "* var *" $line] ||
            [string match "* let *" $line] ||
            [string match "*# See *" $line]) && $hasProc
        } {
            set myarg {}
            foreach com $coms {
                if {[string match "* - *" $com]} {
                    set a [lindex [split $com "-"] 0]
                    set a [string map {# "" " " ""} $a]

                    if {[string match "*optional*" $com]} {
                        if {[regexp {optional:([a-zA-Z0-9]+)} $com -> match]} {
                            set a "$a {$match}"
                        } else {
                            set a "$a {}"
                        }
                    }

                    lappend myarg $a
                    if {$a eq "args"} {
                        break
                    }
                }
            }
            puts $fp "proc $tclproc {$myarg} {"
            foreach com $coms {
                if {[string match "*(optional*" $com]} {
                    regsub {\(optional:[a-zA-Z0-9]+\)|\(optional\)} $com {} com 
                }
                puts $fp $com
            }
            puts $fp "}"

            set myarg {}
            set coms {}
            set hasProc 0
            set tclproc {}
        }
    }

    close $fp
}

# Write examples.ruff
set fp [open [file join [file dirname [info script]] examples.ruff] w+]

puts $fp "namespace eval ::examples {
    # Ruff documentation
    variable _ruff_preamble {"

# List examples
foreach {file_name var} {
    blur.tcl image gradient.tcl image heart.tcl image image_tiled.tcl image
    line.tcl ctx masking.tcl image rounded_rectangle.tcl ctx shadow.tcl image
    square.tcl ctx text_spans.tcl image text.tcl image tiger.tcl image
} {
    set ex [parseExample [file join $dirpix examples $file_name]]
    source [file join $dirpix examples $file_name]
    set bin [pix::toBinary [set $var]]
    set b64 [binary encode base64 -maxlen 80 $bin]
    puts $fp "#### $file_name"
    puts $fp "```"
    puts -nonewline $fp "[join $ex \n]"
    puts $fp "```"
    puts $fp  "!\[alt img](data:image/png;base64,$b64)"
    destroy .l1
}
puts $fp "}"
puts $fp "}"

close $fp

# Write color.ruff
set fp [open [file join [file dirname [info script]] color.ruff] w+]

puts $fp "namespace eval pix::color {
    # Ruff documentation
    variable _ruff_preamble {"

puts $fp "* The following color formats can be used:"

# Color
puts $fp "rgba         - e.g : *rgba(x,x,x,x)*<br>"
puts $fp "This format takes four arguments, for the *red*, *green*, *blue*, and"
puts $fp "*alpha* components of the color. The arguments are all floating point"
puts $fp "numbers between **0.0** and **255.0**."
puts $fp "hexHtml      - e.g : *#F8D1DD*<br>"
puts $fp "This format takes a single argument, which is a string in the"
puts $fp "format of a hex code. The hex code should **7**"
puts $fp "characters long, and each character should be a valid hex digit."
puts $fp "rgb          - e.g : *rgb(x,x,x)*<br>"
puts $fp "This format takes three arguments, for the red, green, and blue"
puts $fp "components of the color. The arguments are all floating point"
puts $fp "numbers between **0.0** and **255.0**."
puts $fp "hexalpha     - e.g : *FF0000FF*<br>"
puts $fp "Only uppercase hexadecimal characters."
puts $fp "Length of **8** characters (typical for an **RGBA** color)"
puts $fp "hex          - e.g : *FF0000*<br>"
puts $fp "Only uppercase hexadecimal characters."
puts $fp "Length of **6** characters (typical for an **RGB** color)"
puts $fp "rgbx         - e.g : *rgbx(x,x,x,x)*<br>"
puts $fp "This format takes four arguments, for the *red*, *green*, *blue*, and"
puts $fp "*alpha* components of the color. The arguments are all floating point"
puts $fp "numbers between **0.0** and **1.0**."
puts $fp "simple color - e.g : *{0.0 0.0 0.0 0.0}*<br>"
puts $fp "This format takes a single argument, which is a list of four"
puts $fp "floating point numbers between **0.0** and **1.0**. The numbers are the"
puts $fp "*red*, *green*, *blue*, and *alpha* components of the color."
puts $fp "string color  - e.g : *white*<br>"
puts $fp "HTML color as a name."
puts $fp "}"
puts $fp "}"

close $fp

# Write release.ruff
set fp [open [file join [file dirname [info script]] release.ruff] w+]

puts $fp "namespace eval ::Release {
    # Ruff documentation
    variable _ruff_preamble {"

# Read README file
set fpreadme [open [file join $dirpix README.MD]]
set readme [split [read $fpreadme] \n]
close $fpreadme

set match false
set release {}
foreach line $readme {
    if {[string match "Release*:*" $line]} {
        set match true
        continue
    }
    if {$match && ![string match "--------*" $line]} {
        lappend release "$line<br>"
    }
}

if {$release ne ""} {
    puts $fp "#### Release\n[join $release \n]"
}

puts $fp "}"
puts $fp "}"

close $fp

foreach name {examples color release pix context paint image svg paths font utils} {
    source [file join [file dirname [info script]] $name.ruff]
}

# Read pix.nimble to find pix version.
set fp [open [file join $dirpix pix.nimble]]
set datanimble [split [read $fp] \n]
close $fp

# Find out pix version
set version ""
foreach line $datanimble {
    if {[string match "*version*=*" $line]} {
        if {[regexp {[0-9.]+} $line match]} {
            set version $match ; break
        }
    }
}

if {$version eq ""} {
    error "not possible to find out version in pix.nim"
}

# Generate docs
::ruff::document "::examples ::Release ::pix [namespace children ::pix]" \
                 -title "pix ${version}: Reference Manual" \
                 -sortnamespaces true \
                 -preamble $::pix::_intro \
                 -compact false \
                 -pagesplit namespace \
                 -navigation sticky \
                 -includesource false \
                 -outdir [file dirname [info script]]  \
                 -outfile "pix.html"

# Syntax highlight.
foreach nameFile {
    pix-examples.html pix.html pix-pix-ctx.html pix-pix-img.html pix-pix-font.html
    pix-pix-path.html pix-pix-paint.html
} {
    set fp [open [file join [file dirname [info script]] $nameFile] r]
    set html [split [read $fp] \n]
    close $fp

    set fp [open [file join [file dirname [info script]] $nameFile] w+]

    set figure 0
    foreach line $html {
        if {[string match "*<figure*>" $line]}  {set figure 1}
        if {[string match "*</figure>*" $line]} {set figure 0}

        if {[string match "*#Begintable*" $line]}  {
            if {![regexp {#Begintable(.+)#EndTable} $line -> match]} {
                error "#Begintable"
            }
            set listTable {}
            regexp {^(.+)#Begintable} $line -> match2
            lappend listTable $match2
            lappend listTable "<table class='ruff_deflist'>"
            set match [string map {.html @html} $match]
            set match [string map {:: @@} $match]
            foreach element [split $match "."] {
                set element [string trim $element]
                if {$element eq ""} {continue}

                if {[llength [split $element ":"]] != 2} {
                    error "#Begintable 1"
                }

                lassign [split $element ":"] info des
                lappend listTable "<tr>"
                lappend listTable "<td>$info</td>"
                lappend listTable "<td>$des.</td>"
                lappend listTable "</tr>"
            } 
            lappend listTable "</table>"
            set listTable [string map {@html .html} $listTable]
            set listTable [string map {@@ ::} $listTable]
            puts $fp [join $listTable "\n"]
            set listTable {}
            continue
        }

        if {$figure} {
            if {[string match "set *" $line]} {
                set l {}
                foreach word [split $line " "] {
                    if {$word eq "set"} {
                        set word "<span style=\"color: hsl(206, 98.02%, 29.04%);font-weight: 550;\">set</span>"
                    }
                    append l "$word "
                }
                set line [string trimright $l]
            }
            if {[string match "package *" $line]} {
                set line [string map {package {<span style="color: hsl(206, 98.02%, 29.04%);font-weight: 550;">package</span>}} $line]
            }
            if {[string match "*&quot;*" $line]} {
                regexp {&quot;(.+)&quot;} $line -> match
                set line [string map [list "&quot;$match&quot;" "<span style=\"color: hsl(120, 71%, 16%);\">&quot;$match&quot;</span>"] $line]
            }

            if {[string match "# *" $line]} {
                set line "<span style=\"color: hsl(218, 8%, 43.5%);font-weight: 500;\">$line</span>"
            }

            if {[string match {*$*} $line]} {
                set l {}
                foreach word [split $line " "] {
                    if {[string index $word 0] eq "$"} {
                        regexp {(\$[a-z0-9A-Z]+)} $word -> match
                        set word [string map [list $match "<span style=\"color: rgb(233, 98, 98);\">$match</span>"] $word]
                    }
                    append l "$word "
                }
                set line [string trimright $l]
            }
        }

        puts $fp $line
    }
    close $fp
}

# Color : 
set fp [open [file join [file dirname [info script]] pix-pix-color.html] r]
set html [split [read $fp] \n]
close $fp

set fp [open [file join [file dirname [info script]] pix-pix-color.html] w+]
set table 0
foreach line $html {
    if {[string match "<table*>" $line]}  {
        set table 1
        set line [string map {"<table" "<table style='width:95%'"} $line]
        puts $fp $line
        continue
    }
    if {$table} {
        puts $fp "<tr>"
        puts $fp "<th style='background-color: var(--ruff-nav-background-color); color: var(--ruff-bd-h1-color)'>Formats</th>"
        puts $fp "<th style='background-color: var(--ruff-nav-background-color); color: var(--ruff-bd-h1-color)'>Color</th>"
        puts $fp "</tr>"
        set table 0
    }
    puts $fp $line
}
close $fp

puts "dir     : [file dirname [info script]]"
puts "file    : pix.html"
puts "version : $version"
puts done!
exit 0