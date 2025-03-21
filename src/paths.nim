# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_path(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new path.
  #
  # Returns: A *new* [path] object.
  let path = newPath()

  let p = toHexPtr(path)
  pixTables.addPath(p, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_path_addPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a path to the current path.
  # 
  # path1 - [path]
  # path2 - [path]
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path1> <path2>")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Path2
  let path2 = pixTables.loadPath(interp, objv[2])
  if path2.isNil: return Tcl.ERROR

  path.addPath(path2)

  return Tcl.OK

proc pix_path_angleToMiterLimit(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-angle to miter-limit-ratio.
  # 
  # angle - double value (radian)
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "angle")
    return Tcl.ERROR

  var angle: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  let miterLimit = angleToMiterLimit(angle)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(miterLimit))

  return Tcl.OK

proc pix_path_miterLimitToAngle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-ratio to miter-limit-angle.
  # 
  # angle - double value (radian)
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "angle")
    return Tcl.ERROR

  var angle: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  let miterLimit = miterLimitToAngle(angle)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(miterLimit))

  return Tcl.OK

proc pix_path_arc(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc to the current sub-path.
  # 
  # path         - [path::new]
  # coordinates  - list x,y
  # radius       - double value
  # angle0       - double value (radian)
  # angle1       - double value (radian)
  # ccw          - boolean value (optional:false)
  #
  # Returns: Nothing.
  if objc notin [6, 7]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x y} r a0 a1 ?ccw:optional"
    )
    return Tcl.ERROR

  var
    x, y, r, a0, a1: cdouble
    clockcw: int
    ccw: bool = false

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], r)  != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[4], a0) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[5], a1) != Tcl.OK:
    return Tcl.ERROR

  if objc == 7:
    if Tcl.GetBooleanFromObj(interp, objv[6], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  try:
    path.arc(x, y, r, a0, a1, ccw)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc using the given control points and radius.
  # Commonly used for making rounded corners.
  # 
  # path          - [path::new]
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  # radius        - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x1 y1} {x2 y2} radius"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1, 
    "wrong # args: 'coordinates1' should be 'x1' 'y1'") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2, 
    "wrong # args: 'coordinates2' should be 'x2' 'y2'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK:
    return Tcl.ERROR

  try:
    path.arcTo(x1, y1, x2, y2, radius)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a cubic Bézier curve to the current sub-path.
  # 
  # path          - [path::new]
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  # coordinates3  - list x3,y3
  #
  # It requires three points:
  # the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path, 
  # which can be changed using *pix::path::moveTo* before creating the Bézier curve.
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x1 y1} {x2 y2} {x3 y3}"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2, x3, y3: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1, 
    "wrong # args: 'coordinates1' should be 'x1' 'y1'") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2, 
    "wrong # args: 'coordinates2' should be 'x2' 'y2'") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates3
  if pixParses.getListDouble(interp, objv[4], x3, y3, 
    "wrong # args: 'coordinates3' should be 'x3' 'y3'") != Tcl.OK:
    return Tcl.ERROR

  path.bezierCurveTo(x1, y1, x2, y2, x3, y3)

  return Tcl.OK

proc pix_path_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Begins a new sub-path at the point (x, y).
  # 
  # path         - [path]
  # coordinates  - list x,y
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  path.moveTo(x, y)

  return Tcl.OK

proc pix_path_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified (x, y) coordinates.
  # 
  # path         - [path]
  # coordinates  - list x,y
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  path.lineTo(x, y)

  return Tcl.OK

proc pix_path_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Attempts to add a straight line from the current point to the start
  # of the current sub-path. If the shape has already been closed or
  # has only one point, this function does nothing.
  # 
  # path - [path]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  path.closePath()

  return Tcl.OK
    
proc pix_path_polygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an n-sided regular polygon at (x, y) with the parameter size.
  # Polygons "face" north.
  # 
  # path         - [path]
  # coordinates  - list x,y
  # size         - double value
  # sides        - integer value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} size sides")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, size: cdouble
    sides: int

  # Coordinates polygon
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if Tcl.GetDoubleFromObj(interp, objv[3], size) != Tcl.OK:
    return Tcl.ERROR
  # Sides
  if Tcl.GetIntFromObj(interp, objv[4], sides) != Tcl.OK:
    return Tcl.ERROR

  try:
    path.polygon(x, y, size, sides)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract
  # a rect from a path when using even-odd winding rule.
  # 
  # path          - [path]
  # coordinates   - list x,y
  # size          - list width,height
  # ccw           - boolean value (optional:true)
  #
  # Returns: Nothing.
  if objc notin [4, 5]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x y} {width height} ?ccw:optional"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, width, height: cdouble
    clockcw: int
    ccw: bool = true

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  if objc == 5:
    if Tcl.GetBooleanFromObj(interp, objv[4], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  path.rect(x, y, width, height, ccw)

  return Tcl.OK

proc pix_path_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circle.
  # 
  # path          - [path]
  # coordinates   - list cx,cy
  # radius        - double value
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {cx cy} r")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var cx, cy, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], cx, cy, 
    "wrong # args: 'coordinates' should be 'cx' 'cy'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK:
    return Tcl.ERROR

  path.circle(cx, cy, radius)

  return Tcl.OK

proc pix_path_fillOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns whether or not the specified point is contained in the current path.
  # 
  # path          - [path]
  # coordinates   - list x,y
  # matrix        - list (optional:mat3)
  # windingRule   - Enum value (optional:NonZero)
  #
  # The point is transformed into the path's coordinate system
  # before the overlap check is done. The transformation matrix is
  # given in the 'matrix' argument, which is a list of 9 double values.
  # If the 'matrix' argument is not given, the identity matrix is used.
  # The overlap check is done with the given 'windingRule' argument,
  # which is a enum value. If the 'windingRule' argument is not given,
  # the default value 'NonZero' is used.
  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x y} or <path> {x y} 'matrix' or <path> {x y} 'matrix' enum:windingRule"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let windingRule = 
    if objc == 5:
      try:
        parseEnum[WindingRule]($Tcl.GetString(objv[4]))
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else: 
      NonZero

  var matrix3: vmath.Mat3 = mat3()

  if objc in [4, 5]:
    if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
      return Tcl.ERROR

  let value = try:
    if path.fillOverlaps(vec2(x, y), matrix3, windingRule): 1 else: 0
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_path_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Apply a matrix transform to a path.
  # 
  # path    - [path]
  # matrix  - list
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Matrix 3x3 check
  var matrix3: vmath.Mat3

  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  path.transform(matrix3)

  return Tcl.OK
  
proc pix_path_computeBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Compute the bounds of the path.
  # 
  # path    - [path]
  # matrix  - list
  #
  # Returns: A Tcl dictionary with keys *(x, y, w, h)*.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Matrix 3x3 check
  var matrix3: vmath.Mat3

  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  let rect = try:
    path.computeBounds(matrix3)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1),  Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1),  Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1),  Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1),  Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_path_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy path.
  #
  # path - [path]
  #
  # Returns: A *new* [path] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  let pathcopy = path.copy()

  let p = toHexPtr(pathcopy)
  pixTables.addPath(p, pathcopy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_path_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a ellipse.
  # 
  # path         - [path]
  # coordinates  - list x,y
  # rx           - double value
  # ry           - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} rx ry")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, rx, ry: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK or
    Tcl.GetDoubleFromObj(interp, objv[4], ry)  != Tcl.OK:
    return Tcl.ERROR

  path.ellipse(x, y, rx, ry)

  return Tcl.OK

proc pix_path_ellipticalArcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an elliptical arc to the current sub-path, 
  # using the given radius ratios, sweep flags, and end position. 
  # 
  # path                - [path]
  # coordinates_radius  - list rx,ry
  # xAxisRotation       - double value
  # largeArcFlag        - boolean value
  # sweepFlag           - boolean value
  # coordinates         - list x,y 
  #
  # Returns: Nothing.
  if objc != 7:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {rx ry} xAxisRotation largeArcFlag sweepFlag {x y}"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, rx, ry, xAxisRotation: cdouble
    largeA, sweepF: int

  # Coordinates radius
  if pixParses.getListDouble(interp, objv[2], rx, ry, 
    "wrong # args: 'radius coordinates' should be 'rx' 'ry'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp,  objv[3], xAxisRotation) != Tcl.OK or
     Tcl.GetBooleanFromObj(interp, objv[4], largeA) != Tcl.OK or
     Tcl.GetBooleanFromObj(interp, objv[5], sweepF) != Tcl.OK:
    return Tcl.ERROR

  # Coordinates
  if pixParses.getListDouble(interp, objv[6], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  path.ellipticalArcTo(rx, ry, xAxisRotation, largeA.bool, sweepF.bool, x, y)

  return Tcl.OK

proc pix_path_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a quadratic Bézier curve to the current sub-path. It requires two points:
  # the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path, which can be changed
  # using moveTo() before creating the quadratic Bézier curve.
  # 
  # path         - [path]
  # coordinates1 - list x1,y1
  # coordinates2 - list x2,y2
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2}")
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1,
    "wrong # args: 'coordinates1' should be 'x1' 'y1'") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2,
    "wrong # args: 'coordinates2' should be 'x2' 'y2'") != Tcl.OK:
    return Tcl.ERROR

  path.quadraticCurveTo(x1, y1, x2, y2)

  return Tcl.OK

proc pix_path_roundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract a 
  # rect from a path when using even-odd winding rule. 
  # 
  # path         - [path]
  # coordinates  - list x,y
  # size         - list width,height
  # radius       - list {nw ne se sw}
  # ccw          - boolean value (optional:true)
  #
  # Returns: Nothing.
  if objc notin [5, 6]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x y} {width height} {nw ne se sw} ?ccw:optional"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, width, height, nw, ne, se, sw: cdouble
    count: Tcl.Size
    clockcw: int
    ccw: bool = true
    elements: Tcl.PPObj

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y,
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height,
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 4:
    return pixUtils.errorMSG(interp,
    "wrong # args: 'radius' should be 'nw' 'ne' 'se' 'sw'"
    )

  if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK:
    return Tcl.ERROR

  if objc == 6:
    if Tcl.GetBooleanFromObj(interp, objv[5], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  path.roundedRect(x, y, width, height, nw, ne, se, sw, ccw)

  return Tcl.OK

proc pix_path_strokeOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if a point is inside the stroking of a path.
  #
  # path         - The [path] object to check.
  # coordinates  - The coordinates x,y to check against the path.
  # options      - Tcl dictionary (optional)
  # 
  # If the dictionary is present it should contain the following keys:<br>
  # #Begintable
  # **transform**   : The transformation matrix to apply before stroking the path.
  # **strokeWidth** : The width of the stroke.
  # **lineCap**     : The line cap style (Enum).
  # **lineJoin**    : The line join style (Enum).
  # **miterLimit**  : The miter limit for the line join.
  # **dashes**      : The dashes to apply to the stroke.
  # #EndTable
  #
  # Returns whether or not the specified point is inside the area
  # contained by the stroking of a path. The point is considered
  # inside if it is contained in the stroked path and not in any
  # holes.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<path> {x y} ?{key value key value ...}:optional"
    )
    return Tcl.ERROR

  # Path
  let path = pixTables.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var value: int = 0

  # Coordinates
  var x, y: cdouble
  if pixParses.getListDouble(interp, objv[2], x, y,
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

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
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_path_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current path or all paths if special word `all` is specified.
  # 
  # value - [path] object or string.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>|string('all')")
    return Tcl.ERROR

  let key = $Tcl.GetString(objv[1])
  # Path
  if key == "all":
    pixTables.clearPath()
  else:
    pixTables.delKeyPath(key)

  return Tcl.OK