# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

package ifneeded pix 0.8 [list apply {dir {
    package require platform

    # Check Tcl version.
    set version [expr {
        [package vsatisfies [package provide Tcl] 9.0-] ? 9 : 8
    }]

    set os  [platform::generic]
    set ext [info sharedlibextension]
    set pixv 0.8

    switch -exact -- $os {
        macosx-x86_64 - macos-x86_64 -
        macosx-arm    - macos-arm -
        linux-x86_64 {set lib [format {lib%spix%s%s} $version $pixv $ext]}
        win32-x86_64 {set lib [format {pix%s-%s%s} $version $pixv $ext]}
        default      {error "'$os' not supported for 'pix' package."}
    }
    # Load library.
    # macosx and macos share the same library name, but the directory is different.
    # Since 9.0.3, we need to map macos to macosx to load the library, 
    # but we still need to keep the macosx directory for backward compatibility with 8.6 and 9.0.1.
    set os [string map {macos- macosx-} $os]
    load [file join $dir $os $lib] Pix

}} $dir]