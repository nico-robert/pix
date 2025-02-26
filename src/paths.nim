# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_path(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new path.
  #
  # Returns a 'new' path object.
  let path = try:
    newPath()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(path)
  pixTables.addPath(p, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_path_addPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a path to the current path.
  # 
  # path1 - path object
  # path2 - path object
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path1> <path2>")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Path2
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasPath(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg2 & "'")

  let path2 = pixTables.getPath(arg2)

  try:
    path.addPath(path2)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_angleToMiterLimit(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-angle to miter-limit-ratio.
  # 
  # angle - double value (radian)
  #
  # Returns double value.
  var angle: cdouble

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "angle")
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  let miterLimit = try:
    angleToMiterLimit(angle)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(miterLimit))

  return Tcl.OK

proc pix_path_miterLimitToAngle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-ratio to miter-limit-angle.
  # 
  # angle - double value (radian)
  #
  # Returns double value.
  var angle: cdouble

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "angle")
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  let miterLimit = try:
    miterLimitToAngle(angle)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(miterLimit))

  return Tcl.OK

proc pix_path_arc(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc to the current sub-path.
  # 
  # path         - object
  # coordinates  - list x,y
  # radius       - double value
  # angle0       - double value (radian)
  # angle1       - double value (radian)
  # ccw          - boolean value (optional:false)
  #
  # Returns nothing.
  var
    x, y, r, a0, a1: cdouble
    count: Tcl.Size
    clockcw: int
    ccw: bool = false
    elements: Tcl.PPObj

  if objc notin (6..7):
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} r a0 a1 ?ccw:optional")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], r)  != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[4], a0) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[5], a1) != Tcl.OK: return Tcl.ERROR
      
  if objc == 7:
    if Tcl.GetBooleanFromObj(interp, objv[6], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  try:
    path.arc(x, y, r, a0, a1, ccw)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc using the given control points and radius.
  # Commonly used for making rounded corners.
  # 
  # path          - object
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  # radius        - double value
  #
  # Returns nothing.
  var
    x1, y1, x2, y2, radius: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2} radius")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'x1' 'y1'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR
      
  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'x2' 'y2'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK: return Tcl.ERROR

  try:
    path.arcTo(x1, y1, x2, y2, radius)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a cubic Bézier curve to the current sub-path.
  # 
  # path          - object
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  # coordinates3  - list x3,y3
  #
  # It requires three points:
  # the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path, 
  # which can be changed using moveTo() before creating the Bézier curve.
  #
  # Returns nothing.
  var
    x1, y1, x2, y2, x3, y3: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2} {x3 y3}")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'x1' 'y1'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR
      
  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'x2' 'y2'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR
      
  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates3' should be 'x3' 'y3'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x3) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y3) != Tcl.OK: return Tcl.ERROR

  try:
    path.bezierCurveTo(vec2(x1, y1), vec2(x2, y2), vec2(x3, y3))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Begins a new sub-path at the point (x, y).
  # 
  # path         - object
  # coordinates  - list x,y
  #
  # Returns nothing.
  var 
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    path.moveTo(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified (x, y) coordinates.
  # 
  # path         - object
  # coordinates  - list x,y
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    path.lineTo(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Attempts to add a straight line from the current point to the start
  # of the current sub-path. If the shape has already been closed or
  # has only one point, this function does nothing.
  # 
  # path - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  try:
    path.closePath()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK
    
proc pix_path_polygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an n-sided regular polygon at (x, y) with the parameter size.
  # Polygons "face" north.
  # 
  # path         - object
  # coordinates  - list x,y
  # size         - double value
  # sides        - integer value
  #
  # Returns nothing.
  var
    x, y, size: cdouble
    count: Tcl.Size
    sides: int
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} size sides")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates polygon
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  # Size
  if Tcl.GetDoubleFromObj(interp, objv[3], size) != Tcl.OK: return Tcl.ERROR
      
  # Sides
  if Tcl.GetIntFromObj(interp, objv[4], sides) != Tcl.OK: return Tcl.ERROR

  try:
    path.polygon(x, y, size, sides)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract
  # a rect from a path when using even-odd winding rule.
  # 
  # path          - object
  # coordinates   - list x,y
  # size          - list width,height
  # ccw           - boolean value (optional:true)
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    count: Tcl.Size
    clockcw: int
    ccw: bool = true
    elements: Tcl.PPObj

  if objc notin (4..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} {width height} ?ccw:optional")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'size' should be 'width' 'height'")

  if Tcl.GetDoubleFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

  if objc == 5:
    if Tcl.GetBooleanFromObj(interp, objv[4], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  try:
    path.rect(x, y, width, height, ccw)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circle.
  # 
  # path          - object
  # coordinates   - list cx,cy
  # radius        - double value
  #
  # Returns nothing.
  var
    cx, cy, r: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {cx cy} r")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cy) != Tcl.OK: return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], r) != Tcl.OK: return Tcl.ERROR

  try:
    path.circle(cx, cy, r)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_fillOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns whether or not the specified point is contained in the current path.
  # 
  # path          - object
  # coordinates   - list x,y
  # matrix        - list (optional:mat3)
  # windingRule   - Enum value (optional:NonZero)
  #
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj
    value: int = 0
    matrix3: vmath.Mat3

  if objc notin (3..5):
    let errMsg = "<path> {x y} or <path> {x y} 'matrix' or <path> {x y} 'matrix' enum:windingRule"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    if objc == 3:
      if path.fillOverlaps(vec2(x, y)): value = 1
    elif objc == 4:
      # Matrix 3x3 check
      if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR
      if path.fillOverlaps(vec2(x, y), transform = matrix3): value = 1
    else:
      # Matrix 3x3 check
      if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR

      let myEnum = parseEnum[WindingRule]($Tcl.GetString(objv[4]))

      if path.fillOverlaps(vec2(x, y), transform = matrix3, windingRule = myEnum):
         value = 1
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_path_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Apply a matrix transform to a path.
  # 
  # path    - object
  # matrix  - list
  #
  # Returns nothing.
  var matrix3: vmath.Mat3

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Matrix 3x3 check
  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  try:
    path.transform(matrix3)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK
  
proc pix_path_computeBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Compute the bounds of the path.
  # 
  # path    - object
  # matrix  - list
  #
  # Returns Tcl dict value (x, y, w, h).
  var matrix3: vmath.Mat3
  let dictObj = Tcl.NewDictObj()

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Matrix 3x3 check
  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  let rect = try:
    path.computeBounds(matrix3)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1),  Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1),  Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1),  Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1),  Tcl.NewDoubleObj(rect.h))
  
  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_path_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy path.
  #
  # path - object
  #
  # Returns a 'new' path object.

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  let pathcopy = try:
    path.copy()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(pathcopy)
  pixTables.addPath(p, pathcopy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_path_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a ellipse.
  # 
  # path         - object
  # coordinates  - list x,y
  # rx           - double value
  # ry           - double value
  #
  # Returns nothing.
  var
    x, y, rx, ry: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} rx ry")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR
    
  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK: return Tcl.ERROR

  try:
    path.ellipse(x, y, rx, ry)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_ellipticalArcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an elliptical arc to the current sub-path, 
  # using the given radius ratios, sweep flags, and end position. 
  # 
  # path                - object
  # coordinates_radius  - list rx,ry
  # xAxisRotation       - double value
  # largeArcFlag        - boolean value
  # sweepFlag           - boolean value
  # coordinates         - list x,y 
  #
  # Returns nothing.
  var
    x, y, rx, ry, xAxisRotation: cdouble
    count: Tcl.Size
    largeA, sweepF: int
    elements: Tcl.PPObj

  if objc != 7:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {rx ry} xAxisRotation largeArcFlag sweepFlag {x y}")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates_radius' should be 'rx' 'ry'")

  if Tcl.GetDoubleFromObj(interp, elements[0], rx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], ry) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], xAxisRotation) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetBooleanFromObj(interp, objv[4], largeA)       != Tcl.OK: return Tcl.ERROR
  if Tcl.GetBooleanFromObj(interp, objv[5], sweepF)       != Tcl.OK: return Tcl.ERROR
      
  if Tcl.ListObjGetElements(interp, objv[6], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    path.ellipticalArcTo(rx, ry, xAxisRotation, largeA.bool, sweepF.bool, x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a quadratic Bézier curve to the current sub-path. It requires two points:
  # the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path, which can be changed
  # using moveTo() before creating the quadratic Bézier curve.
  # 
  # path           - object
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  #
  # Returns nothing.
  var
    x1, y1, x2, y2: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2}")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'x1' 'y1'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'x2' 'y2'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR

  try:
    path.quadraticCurveTo(x1, y1, x2, y2)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_roundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract a 
  # rect from a path when using even-odd winding rule. 
  # 
  # path         - object
  # coordinates  - list x,y
  # size         - list width,height
  # radius       - list (nw, ne, se, sw)
  # ccw          - boolean value (optional:true)
  #
  # Returns nothing.
  var
    x, y, width, height, nw, ne, se, sw: cdouble
    count: Tcl.Size
    clockcw: int
    ccw: bool = true
    elements: Tcl.PPObj

  if objc notin (5..6):
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} {width height} {nw ne se sw} ?ccw:optional")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR
      
  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'size' should be 'width' 'height'")

  if Tcl.GetDoubleFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 4:
    return pixUtils.errorMSG(interp, "wrong # args: 'radius' should be 'nw' 'ne' 'se' 'sw'")

  if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK: return Tcl.ERROR

  if objc == 6:
    if Tcl.GetBooleanFromObj(interp, objv[5], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  try:
    path.roundedRect(x, y, width, height, nw, ne, se, sw, ccw)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_strokeOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns whether or not the specified point is inside the area
  # contained by the stroking of a path.
  # 
  # path         - object
  # coordinates  - list x,y
  # options      - dict (transform:list, strokeWidth:double, lineCap:enum, lineJoin:enum, miterLimit:double, dashes:list) (optional)
  #
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj
    value: int = 0

  if objc notin (3..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} ?{key value key value ...}:optional")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    if objc == 4:
      var opts = pixParses.RenderOptions()
      pixParses.dictOptions(interp, objv[3], opts)

      if path.strokeOverlaps(
        vec2(x, y),
        transform   = opts.transform,
        strokeWidth = opts.strokeWidth,
        lineCap     = opts.lineCap,
        lineJoin    = opts.lineJoin,
        miterLimit  = opts.miterLimit,
        dashes      = opts.dashes
      ): value = 1
    else:
      if path.strokeOverlaps(vec2(x, y)): value = 1
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_path_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current path or all paths if special word `all` is specified.
  # 
  # value - path object or string 
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:    
    # Path
    if arg1 == "all":
      pathTable.clear()
    else:
      pathTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK