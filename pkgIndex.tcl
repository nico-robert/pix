# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

package ifneeded pix 0.4 [list apply {dir {
    # REMINDER ME : Change the 3 values for the version.
    package require platform
    
    # Check Tcl version.
    set version [expr {
        [package vsatisfies [package provide Tcl] 9.0-] ? 9 : 8
    }]

    set os [platform::generic]
    if {$os in {macosx-x86_64 macosx-arm}} {
        load [file join $dir $os lib${version}pix0.4.dylib] Pix
    } elseif {$os eq "win32-x86_64"} {
        load [file join $dir $os pix${version}-0.4.dll] Pix
    } elseif {$os eq "linux-x86_64"} {
        load [file join $dir $os lib${version}pix0.4.so] Pix
    } else {
        error "'$os' not supported for 'pix' package."
    }
}} $dir]