# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

package ifneeded pix 0.1 [list apply {dir {
    # <REMINDER ME> : Change the 3 values for the version.
    package require platform

    set os [platform::generic]
    if {$os eq "macosx-x86_64"} {
        load [file join $dir $os libpix0.1.dylib] Pix
    } elseif {$os eq "win32-x86_64"} {
        load [file join $dir $os pix0.1.dll] Pix
    } else {
        error "'$os' not supported for 'pix'"
    }
}} $dir]