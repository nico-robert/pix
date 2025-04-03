# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

package ifneeded pix 0.5 [list apply {dir {
    # REMINDER ME : Change the 2 values for the version.
    package require platform
    
    # Check Tcl version.
    set version [expr {
        [package vsatisfies [package provide Tcl] 9.0-] ? 9 : 8
    }]

    set os  [platform::generic]
    set ext [info sharedlibextension]
    set pixv 0.5

    switch -exact $os {
        macosx-x86_64 - 
        macosx-arm    - 
        linux-x86_64 {set lib [format {lib%spix%s%s} $version $pixv $ext]}
        win32-x86_64 {set lib [format {pix%s-%s%s} $version $pixv $ext]}
        default      {error "'$os' not supported for 'pix' package."}
    }
    # Load library.
    load [file join $dir $os $lib] Pix

}} $dir]