# Test all files.
lappend auto_path [file dirname [file dirname [file dirname [info script]]]]

package require pix

set files {
    test_context.test
    test_fonts.test
    test_images.test
    test_paints.test
    test_paths.test
}

set dir [file dirname [info script]]

# All files.
foreach fc [split $files "\n"] {
    set file [string trim $fc]
    if {[string length $file] == 0 || [string first "#" $file] > -1} {continue}
    source [file join $dir $file]
}

exit 0