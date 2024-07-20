# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse SVG XML. Defaults to the SVG's view box size.
  # 
  # svg  - string data
  # size - list width + height (optional:SVGviewbox)
  #
  # Returns a 'new' svg object.
  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements: Tcl.PPObj = nil
    var svg: Svg

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "'svg string' {width height}:optional")
      return Tcl.ERROR
      
    # Svg string
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    if objc == 3:
      # Size
      if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
        return Tcl.ERROR

      if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

      svg = parseSvg($arg1, width, height)

    else:
      svg = parseSvg($arg1)

    let myPtr = cast[pointer](svg)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^svg").toLowerAscii

    svgTable[p] = svg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_svg_newImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Render SVG and return the image. 
  # 
  # svg - object
  #
  # Returns a 'new' img object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<svg>")
      return Tcl.ERROR
      
    # Svg
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let svg = svgTable[$arg1]
    
    let image = newImage(svg)
 
    let myPtr = cast[pointer](image)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = image

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_svg_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current svg or all svgs if special word `all` is specified.
  # 
  # value - svg object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<svg>|string")
      return Tcl.ERROR
    
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    if $arg1 == "all":
      svgTable.clear()
    else:
      svgTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR