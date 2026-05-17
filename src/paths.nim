# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_path(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates and returns a new path object.
  #
  # Returns: A *new* handle [path] object.
  let ptable = cast[PixTable](clientData)
  let path = newPath()

  let pathKey = toHexPtr(path)
  ptable.addPath(pathKey, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pathKey.cstring, -1))

  return Tcl.OK

proc pix_path_addPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Appends the geometry of another path to the current path.
  # 
  # path1 - destination [path] object handle
  # path2 - source [path] object handle
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path1> <path2>")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Path2
  let path2 = ptable.loadPath(interp, objv[2])
  if path2.isNil: return Tcl.ERROR

  path.addPath(path2)

  return Tcl.OK

proc pix_path_angleToMiterLimit(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Converts miter-limit-angle to miter-limit-ratio.
  # 
  # angle - Double value (radian)
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

proc pix_path_miterLimitToAngle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Converts miter-limit-ratio to miter-limit-angle.
  # 
  # angle - Double value (radian)
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

proc pix_path_arc(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circular arc to the current sub-path.
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  # radius       - Double value
  # angle0       - Double value (radian)
  # angle1       - Double value (radian)
  # ccw          - Boolean value (optional:false)
  #
  # Returns: Nothing.
  if objc notin [6, 7]:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates radius angle0 angle1 ?ccw?"
    )
    return Tcl.ERROR

  var
    x, y, r, a0, a1: cdouble
    clockcw: cint
    ccw: bool = false

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
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

proc pix_path_arcTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circular arc using the given control points and radius.
  # 
  # path          - [path]
  # coordinates1  - A list {x1 y1}
  # coordinates2  - A list {x2 y2}
  # radius        - Double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates1 coordinates2 radius"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1, 
    "wrong # args: 'coordinates1' should be {x1 y1}") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2, 
    "wrong # args: 'coordinates2' should be {x2 y2}") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK:
    return Tcl.ERROR

  try:
    path.arcTo(x1, y1, x2, y2, radius)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_path_bezierCurveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a cubic Bézier curve to the current sub-path.
  # 
  # path          - [path]
  # coordinates1  - A list {x1 y1}
  # coordinates2  - A list {x2 y2}
  # coordinates3  - A list {x3 y3}
  #
  # It requires three points:<br>
  # the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path, 
  # which can be changed using `pix::path::moveTo` before creating the Bézier curve.
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates1 coordinates2 coordinates3"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2, x3, y3: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1, 
    "wrong # args: 'coordinates1' should be {x1 y1}") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2, 
    "wrong # args: 'coordinates2' should be {x2 y2}") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates3
  if pixParses.getListDouble(interp, objv[4], x3, y3, 
    "wrong # args: 'coordinates3' should be {x3 y3}") != Tcl.OK:
    return Tcl.ERROR

  path.bezierCurveTo(x1, y1, x2, y2, x3, y3)

  return Tcl.OK

proc pix_path_moveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Begins a new sub-path at the point {x y}.
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  path.moveTo(x, y)

  return Tcl.OK

proc pix_path_lineTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified {x y} coordinates.
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  path.lineTo(x, y)

  return Tcl.OK

proc pix_path_closePath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Attempts to add a straight line from the current point to the start
  # of the current sub-path.
  # 
  # path - [path]
  #
  # If the shape has already been closed or
  # has only one point, this function does nothing.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  path.closePath()

  return Tcl.OK
    
proc pix_path_polygon(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds an n-sided regular polygon at {x y} with the parameter size.
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  # size         - Double value
  # sides        - Integer value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates size sides")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, size: cdouble
    sides: cint

  # Coordinates polygon
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
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

proc pix_path_rect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a rectangle. Clockwise parameter can be used to subtract
  # a rect from a path when using even-odd winding rule.
  # 
  # path          - [path]
  # coordinates   - A list {x y}
  # size          - A list {width height}
  # ccw           - Boolean value (optional:true)
  #
  # Returns: Nothing.
  if objc notin [4, 5]:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates size ?ccw?"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, width, height: cdouble
    clockcw: cint
    ccw: bool = true

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be {width height}") != Tcl.OK:
    return Tcl.ERROR

  if objc == 5:
    if Tcl.GetBooleanFromObj(interp, objv[4], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  path.rect(x, y, width, height, ccw)

  return Tcl.OK

proc pix_path_circle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circle.
  # 
  # path          - [path]
  # coordinates   - A list {cx cy}
  # radius        - Double value
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates radius")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var cx, cy, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], cx, cy, 
    "wrong # args: 'coordinates' should be {cx cy}") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK:
    return Tcl.ERROR

  path.circle(cx, cy, radius)

  return Tcl.OK

proc pix_path_fillOverlaps(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks whether a given point is inside the filled region of the path.
  #
  # path        - [path] object handle
  # coordinates - A Tcl list {x y} (the point to test)
  # windingRule - Optional enum value (WindingRule, defaults to `NonZero`)
  # transform   - An optional 3x3 transformation matrix (optional:identityMatrix)
  #
  # Returns: True if the point overlaps the filled area, false otherwise.
  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates ?windingRule? ?transform?")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  let windingRule = 
    if objc == 5:
      try:
        parseEnum[WindingRule]($objv[4])
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else: 
      NonZero

  var matrix3: vmath.Mat3 = mat3()

  if objc in [4, 5]:
    if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
      return Tcl.ERROR

  let value = try:
    path.fillOverlaps(vec2(x, y), matrix3, windingRule)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_path_transform(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Applies an affine transformation matrix to the path.
  #
  # path      - [path] object handle
  # matrix3x3 - A 3x3 transformation matrix (list of 9 numbers)
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Matrix 3x3 check
  var matrix3: vmath.Mat3

  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  path.transform(matrix3)

  return Tcl.OK
  
proc pix_path_computeBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Computes the bounding box enclosing the path.
  #
  # path      - [path] object handle
  # transform - An optional 3x3 transformation matrix (optional:identityMatrix)
  #
  # Returns: A Tcl dictionary with keys {x y w h} representing the bounding box.
  if objc notin [2 ,3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> ?matrix?")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  let rect = 
    try:
      if objc == 3:
        var matrix3: vmath.Mat3
        if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
          return Tcl.ERROR
        path.computeBounds(matrix3)
      else:
        path.computeBounds()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1),  Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1),  Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1),  Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1),  Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_path_copy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Copy path.
  #
  # path - [path]
  #
  # Returns: A *new* handle [path] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  let pathcopy = path.copy()

  let pathKey = toHexPtr(pathcopy)
  ptable.addPath(pathKey, pathcopy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pathKey.cstring, -1))

  return Tcl.OK

proc pix_path_ellipse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a ellipse.
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  # rx           - Double value
  # ry           - Double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates rx ry")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, rx, ry: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK or
    Tcl.GetDoubleFromObj(interp, objv[4], ry)  != Tcl.OK:
    return Tcl.ERROR

  path.ellipse(x, y, rx, ry)

  return Tcl.OK

proc pix_path_ellipticalArcTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds an elliptical arc to the current sub-path, 
  # using the given radius ratios, sweep flags, and end position. 
  # 
  # path           - [path]
  # coordinates    - A list {rx ry}
  # xAxisRotation  - Double value
  # largeArcFlag   - Boolean value
  # sweepFlag      - Boolean value
  # coordinates    - A list {x y} 
  #
  # Returns: Nothing.
  if objc != 7:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates xAxisRotation largeArcFlag sweepFlag {x y}"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, rx, ry, xAxisRotation: cdouble
    largeA, sweepF: cint

  # Coordinates radius
  if pixParses.getListDouble(interp, objv[2], rx, ry, 
    "wrong # args: 'radius coordinates' should be {rx ry}") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp,  objv[3], xAxisRotation) != Tcl.OK or
     Tcl.GetBooleanFromObj(interp, objv[4], largeA) != Tcl.OK or
     Tcl.GetBooleanFromObj(interp, objv[5], sweepF) != Tcl.OK:
    return Tcl.ERROR

  # Coordinates
  if pixParses.getListDouble(interp, objv[6], x, y, 
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  path.ellipticalArcTo(rx, ry, xAxisRotation, largeA.bool, sweepF.bool, x, y)

  return Tcl.OK

proc pix_path_quadraticCurveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a quadratic Bézier curve to the current sub-path.
  # 
  # path         - [path]
  # coordinates1 - A list {x1 y1}
  # coordinates2 - A list {x2 y2}
  #
  # It requires two points:<br>
  # The first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path, which can be changed
  # using `pix::path::moveTo` before creating the quadratic Bézier curve.
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<path> coordinates1 coordinates2")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1,
    "wrong # args: 'coordinates1' should be {x1 y1}") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2,
    "wrong # args: 'coordinates2' should be {x2 y2}") != Tcl.OK:
    return Tcl.ERROR

  path.quadraticCurveTo(x1, y1, x2, y2)

  return Tcl.OK

proc pix_path_roundedRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a rectangle. Clockwise parameter can be used to subtract a 
  # rect from a path when using even-odd winding rule. 
  # 
  # path         - [path]
  # coordinates  - A list {x y}
  # size         - A list {width height}
  # radius       - A list {nw ne se sw}
  # ccw          - Boolean value (optional:true)
  #
  # Returns: Nothing.
  if objc notin [5, 6]:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates size radius ?ccw?"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var
    x, y, width, height, nw, ne, se, sw: cdouble
    count: Tcl.Size
    clockcw: cint
    ccw: bool = true
    elements: Tcl.PPObj

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y,
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height,
    "wrong # args: 'size' should be {width height}") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 4:
    return pixUtils.errorMSG(interp,
      "wrong # args: 'radius' should be {nw ne se sw}"
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

proc pix_path_strokeOverlaps(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks whether a given point intersects the stroked outline of the path.
  #
  # path        - [path] object handle
  # coordinates - A Tcl list {x y} (the point to test)
  # options     - An optional dictionary of stroke rendering settings (optional).
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
  # Returns: True if the point overlaps the stroke outline, false otherwise.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv,
      "<path> coordinates {?key value key value ...?}"
    )
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  var value: cint = 0

  # Coordinates
  var x, y: cdouble
  if pixParses.getListDouble(interp, objv[2], x, y,
    "wrong # args: 'coordinates' should be {x y}") != Tcl.OK:
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

proc pix_path_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy the [path] or all paths if special word `all` is specified.
  # 
  # value - [path] object or string.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $objv[1]

  # Path
  if key == "all":
    ptable.clearPath()
  else:
    ptable.delKeyPath(key)

  return Tcl.OK