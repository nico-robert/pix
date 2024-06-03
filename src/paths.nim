# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_path(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let path = newPath()
    let a = cast[pointer](path)
    let hex = "0x" & cast[uint64](a).toHex
    let p = (hex & "^path").toLowerAscii

    pathTable[p] = path

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))
    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_addPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> <addpath>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let path2 = pathTable[$arg2]
  
    path.addPath(path2)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR


proc pix_path_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
  
    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    path.moveTo(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
  
    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    path.lineTo(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
  
    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    path.closePath()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_path_polygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, size: cdouble = -1
    let count, sides: cint = 0
    let elements : Tcl.PPObj = nil
  
    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {x y} size sides"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]
    
    # Coordinates polygon
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    # Size
    if Tcl.GetDoubleFromObj(interp, objv[3], size.addr) != Tcl.OK:
      return Tcl.ERROR
      
    # Sides
    if Tcl.GetIntFromObj(interp, objv[4], sides.addr) != Tcl.OK:
      return Tcl.ERROR

    path.polygon(x, y, size, sides)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {x y} {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK:
      return Tcl.ERROR

    path.rect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let cx, cy, r: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {cx cy} r"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'cx' 'cy'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cx.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[1], cy.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], r.addr) != Tcl.OK:
      return Tcl.ERROR

    path.circle(cx, cy, r)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_fillOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var val: int = 0

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    if path.fillOverlaps(vec2(x, y)): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_path_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <path> matrix3x3"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let path = pathTable[$arg1]

    # Matrix 3x3 check
    if matrix3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    path.transform(matrix3)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
