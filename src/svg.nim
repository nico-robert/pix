# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements: Tcl.PPObj = nil
    var svg: Svg

    if objc notin (2..3):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " 'svg_string {width height}:optional'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Svg string
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    if objc == 3:
      # Size
      if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
        return Tcl.ERROR

      if Tcl.GetIntFromObj(interp, elements[0], width.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK:
        return Tcl.ERROR

      svg = parseSvg($arg1, width, height)

    else:
      svg = parseSvg($arg1)

    let sv = cast[pointer](svg)
    let hex = "0x" & cast[uint64](sv).toHex
    let p = (hex & "^svg").toLowerAscii

    svgTable[p] = svg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_svg_toImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <svg>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Svg
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let svg = svgTable[$arg1]
    
    let image = newImage(svg)
 
    let im = cast[pointer](image)
    let hex = "0x" & cast[uint64](im).toHex
    let i = (hex & "^img").toLowerAscii

    imgTable[i] = image

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(i), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR