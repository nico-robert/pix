# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_font_readFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " 'file'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    
    # Font
    let font = readFont($arg1)
    
    let fo = cast[pointer](font)
    let hex = "0x" & cast[uint64](fo).toHex
    let p = (hex & "^font").toLowerAscii

    fontTable[p] = font

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_font_size(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let fsize: cdouble = 0

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '<font>' 'size'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let font = fontTable[$arg1]
    
    if Tcl.GetDoubleFromObj(interp, objv[2], fsize.addr) != Tcl.OK:
      return Tcl.ERROR

    font.size = fsize

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_font_color(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '<font>' '{r g b}'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let font = fontTable[$arg1]
    
    # Color simple check
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let color = parseHtmlColor($arg2).color

    font.paint.color = color
    
    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_font_typeset(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count, wrap: cint = 0
    let elements : Tcl.PPObj = nil
    var wrapText: bool = true

    if objc != 7:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '<font>' 'text' {x y} hAlign:enum vAlign:enum 'wrap'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let font = fontTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let text = $arg2
   
    # Position
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR
     
    
    let arg4 = Tcl.GetStringFromObj(objv[4], nil)
    let hEnum = parseEnum[HorizontalAlignment]($arg4)
    
    let arg5 = Tcl.GetStringFromObj(objv[5], nil)
    let vEnum = parseEnum[VerticalAlignment]($arg5)
    
    if Tcl.GetBooleanFromObj(interp, objv[6], wrap.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if wrap.uint8 == 0:
      wrapText = false

    let arr = font.typeset(text, vec2(x, y), hEnum, vEnum, wrapText)
      
    let ar = cast[pointer](arr)
    let hex = "0x" & cast[uint64](ar).toHex
    let p = (hex & "^arr").toLowerAscii

    arrTable[p] = arr
    
    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))
    
    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR