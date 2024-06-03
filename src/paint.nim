# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " enum:PaintKind"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let myEnum = parseEnum[PaintKind]($arg1)

    let paint = newPaint(myEnum)
    let c = cast[pointer](paint)
    let hex = "0x" & cast[uint64](c).toHex
    let p = (hex & "^paint").toLowerAscii

    paintTable[p] = paint

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR


proc pix_paint_gradientHandlePositions(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x1, y1, x2, y2, x3, y3: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <paint> {x1 y1} {x2 y2} {x3 y3}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]
    
    # Positions
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x1' 'y1'", nil)
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[0], x1.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y1.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x2' 'y2'", nil)
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[0], x2.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y2.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x3' 'y3'", nil)
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[0], x3.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y3.addr) != Tcl.OK:
      return Tcl.ERROR
      
    paint.gradientHandlePositions = @[vec2(x1, y1), vec2(x2, y2), vec2(x3, y3)]

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR 
    
proc pix_paint_dict(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var matrix3: vmath.Mat3

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <paint> {image? ?value imageMat? ?value color? ?value blendMode? ?value}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]

    # Dict
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      Tcl.SetResult(interp, "wrong # args: argument should key value key1 value1", nil)
      return Tcl.ERROR
      
    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "color":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.color = parseHtmlColor($value).color
        of "blendMode":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.blendMode = parseEnum[BlendMode]($value)
        of "image":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.image = imgTable[$value]
        of "imageMat":
          # Matrix 3x3 check
          if matrix3(interp, elements[i+1], matrix3) != Tcl.OK:
            return Tcl.ERROR
          paint.imageMat = matrix3
        else:
          Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
          return Tcl.ERROR
      inc(i, 2)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR 
    
proc pix_paint_gradientStops(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let p1, p2: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var cseqColorP1, cseqColorP2: Color

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <paint> {color 'position 1'} {color 'position 2'}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]
    
    # Color position
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'color p1'", nil)
      return Tcl.ERROR
      
    # Color simple check
    if isColor_Simple(elements[0], cseqColorP1) == false:
      let arg3 = Tcl.GetStringFromObj(elements[0], nil)
      cseqColorP1 = parseHtmlColor($arg3).color
    
    if Tcl.GetDoubleFromObj(interp, elements[1], p1.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'color p2'", nil)
      return Tcl.ERROR
      
    # Color simple check
    if isColor_Simple(elements[0], cseqColorP2) == false:
      let arg4 = Tcl.GetStringFromObj(elements[0], nil)
      cseqColorP2 = parseHtmlColor($arg4).color

    if Tcl.GetDoubleFromObj(interp, elements[1], p2.addr) != Tcl.OK:
      return Tcl.ERROR
      
    paint.gradientStops = @[
      ColorStop(color: cseqColorP1, position: p1),
      ColorStop(color: cseqColorP2, position: p2),
    ]

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR 
