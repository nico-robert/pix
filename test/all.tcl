# Test all files.
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
    set tclTestFile [file join $dir $file]
    exec tclsh9.0 $tclTestFile
    puts stdout "Tcl90 : $file > Ok"
    exec tclsh8.6 $tclTestFile
    puts stdout "Tcl86 : $file > Ok"
}

exit 0