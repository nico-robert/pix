# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

package ifneeded pix 0.3 [list apply {dir {
    # REMINDER ME : Change the 3 values for the version.
    package require platform

    set os [platform::generic]
    if {$os eq "macosx-x86_64"} {
        load [file join $dir $os libpix0.3.dylib] Pix
    } elseif {$os eq "win32-x86_64"} {
        load [file join $dir $os pix0.3.dll] Pix
    } elseif {$os eq "linux-x86_64"} {
        load [file join $dir $os libpix0.3.so] Pix
    } else {
        error "'$os' not supported for 'pix' package."
    }
}} $dir]