# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_path(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new path.
  #
  # Returns a 'new' path object.
  try:
    let path = newPath()
    let p = toHexPtr(path)
    pathTable[p] = path

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_addPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a path to the current path.
  # 
  # path  - object
  # path2 - object
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> <path2>")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    let arg2 = Tcl.GetString(objv[2])
    let path2 = pathTable[$arg2]
  
    path.addPath(path2)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_angleToMiterLimit(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-angle to miter-limit-ratio.
  # 
  # angle - double value (radian)
  #
  # Returns double value.
  try:
    var angle: cdouble = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "angle")
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
      return Tcl.ERROR

    let value = angleToMiterLimit(angle)
  
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_miterLimitToAngle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts miter-limit-ratio to miter-limit-angle.
  # 
  # angle - double value (radian)
  #
  # Returns double value.
  try:
    var angle: cdouble = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "angle")
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
      return Tcl.ERROR

    let value = miterLimitToAngle(angle)
  
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

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
  try:
    var x, y, r, a0, a1: cdouble = 0
    var count: Tcl.Size
    var clockcw: int = 0
    var ccw: bool = false
    var elements: Tcl.PPObj

    if objc notin (6..7):
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} r a0 a1 ccw:optional")
      return Tcl.ERROR

    # path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], r)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], a0) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[5], a1) != Tcl.OK: return Tcl.ERROR
      
    if objc == 7:
      if Tcl.GetBooleanFromObj(interp, objv[6], clockcw) != Tcl.OK:
        return Tcl.ERROR
      ccw = clockcw.bool

    path.arc(x, y, r, a0, a1, ccw)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc using the given control points and radius.
  # Commonly used for making rounded corners.
  # 
  # path           - object
  # coordinates_1  - list x1,y1
  # coordinates_2  - list x2,y2
  # radius         - double value
  #
  # Returns nothing.
  try:
    var x1, y1, x2, y2, radius: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2} radius")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'x1' 'y1'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x2' 'y2'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR

    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK: return Tcl.ERROR

    path.arcTo(x1, y1, x2, y2, radius)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a cubic Bézier curve to the current sub-path.
  # It requires three points:
  # the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path, 
  # which can be changed using moveTo() before creating the Bézier curve.
  # 
  # path           - object
  # coordinates_1  - list x1,y1
  # coordinates_2  - list x2,y2
  # coordinates_3  - list x3,y3
  #
  # Returns nothing.
  try:
    var x1, y1, x2, y2, x3, y3: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2} {x3 y3}")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'x1' 'y1'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x2' 'y2'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_3' should be 'x3' 'y3'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x3) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y3) != Tcl.OK: return Tcl.ERROR

    path.bezierCurveTo(vec2(x1, y1), vec2(x2, y2), vec2(x3, y3))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Begins a new sub-path at the point (x, y).
  # 
  # path         - object
  # coordinates  - list x,y
  #
  # Returns nothing.
  try:
    var x, y: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj
  
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    path.moveTo(x, y)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified (x, y) coordinates.
  # 
  # path         - object
  # coordinates  - list x,y
  #
  # Returns nothing.
  try:
    var x, y: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj
  
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y}")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    path.lineTo(x, y)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Attempts to add a straight line from the current point to the start
  # of the current sub-path. If the shape has already been closed or
  # has only one point, this function does nothing.
  # 
  # path - object
  #
  # Returns nothing.
  try:
  
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<path>")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    path.closePath()

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
    
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
  try:
    var x, y, size: cdouble = 0
    var count: Tcl.Size
    var sides: int = 0
    var elements: Tcl.PPObj
  
    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} size sides")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]
    
    # Coordinates polygon
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    # Size
    if Tcl.GetDoubleFromObj(interp, objv[3], size) != Tcl.OK: return Tcl.ERROR
      
    # Sides
    if Tcl.GetIntFromObj(interp, objv[4], sides) != Tcl.OK: return Tcl.ERROR

    path.polygon(x, y, size, sides)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract
  # a rect from a path when using even-odd winding rule.
  # 
  # path          - object
  # coordinates   - list x,y
  # size          - list width + height
  # ccw           - boolean value (optional:true)
  #
  # Returns nothing.
  try:
    var x, y, width, height: cdouble = 0
    var count: Tcl.Size
    var clockcw: int = 0
    var ccw: bool = true
    var elements: Tcl.PPObj

    if objc notin (4..5):
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} {width height} ccw:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")

    if Tcl.GetDoubleFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

    if objc == 5:
      if Tcl.GetBooleanFromObj(interp, objv[4], clockcw) != Tcl.OK:
        return Tcl.ERROR
      ccw = clockcw.bool

    path.rect(x, y, width, height, ccw)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circle.
  # 
  # path          - object
  # coordinates   - list cx,cy
  # radius        - double value
  #
  # Returns nothing.
  try:
    var cx, cy, r: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {cx cy} r")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")

    if Tcl.GetDoubleFromObj(interp, elements[0], cx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cy) != Tcl.OK: return Tcl.ERROR

    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[3], r) != Tcl.OK: return Tcl.ERROR

    path.circle(cx, cy, r)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_fillOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns whether or not the specified point is contained in the current path.
  # 
  # path          - object
  # coordinates   - list x,y
  # matrix        - list (optional:mat3)
  # windingRule   - Enum value (optional:NonZero)
  #
  try:
    var x, y: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj
    var val: int = 0
    var matrix3: vmath.Mat3

    if objc != 3 and objc != 4 and objc != 5:
      let msg = """ <path> {x y} or
      <path> {x y} 'matrix' or
      <path> {x y} 'matrix' enum:windingRule"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    if objc == 3:
      if path.fillOverlaps(vec2(x, y)): val = 1
    elif objc == 4:
      # Matrix 3x3 check
      if matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR
      if path.fillOverlaps(vec2(x, y), transform = matrix3): val = 1
    else:
      # Matrix 3x3 check
      if matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR
      
      let arg2 = Tcl.GetString(objv[4])
      let myEnum = parseEnum[WindingRule]($arg2)

      if path.fillOverlaps(vec2(x, y), transform = matrix3, windingRule = myEnum): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Apply a matrix transform to a path.
  # 
  # path    - object
  # matrix  - list
  #
  # Returns nothing.
  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Matrix 3x3 check
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    path.transform(matrix3)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
  
proc pix_path_computeBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Compute the bounds of the path.
  # 
  # path    - object
  # matrix  - list
  #
  # Returns Tcl dict value (x, y, w, h).
  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> matrix")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Matrix 3x3 check
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    let dictObj  = Tcl.NewDictObj()
    let rect = path.computeBounds(matrix3)

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1),  Tcl.NewDoubleObj(rect.x))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1),  Tcl.NewDoubleObj(rect.y))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1),  Tcl.NewDoubleObj(rect.w))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1),  Tcl.NewDoubleObj(rect.h))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy path.
  #
  # path - object
  #
  # Returns a 'new' path object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<path>")
      return Tcl.ERROR
    
    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    let cp = path.copy()
    let p = toHexPtr(cp)
    pathTable[p] = cp

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a ellipse.
  # 
  # path         - object
  # coordinates  - list x,y
  # rx           - double value
  # ry           - double value
  #
  # Returns nothing.
  try:
    var x, y, rx, ry: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} rx ry")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR
    
    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK: return Tcl.ERROR

    path.ellipse(x, y, rx, ry)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

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
  try:
    var x, y, rx, ry, xAxisRotation: cdouble = 0
    var count: Tcl.Size
    var largeA, sweepF: int = 0
    var largeArcFlag, sweepFlag: bool = false
    var elements: Tcl.PPObj

    if objc != 7:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {rx ry} xAxisRotation largeArcFlag sweepFlag {x y}")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_radius' should be 'rx' 'ry'")

    if Tcl.GetDoubleFromObj(interp, elements[0], rx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], ry) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], xAxisRotation) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetBooleanFromObj(interp, objv[4], largeA)       != Tcl.OK: return Tcl.ERROR
    if Tcl.GetBooleanFromObj(interp, objv[5], sweepF)       != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[6], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR
      
    largeArcFlag = largeA.bool
    sweepFlag    = sweepF.bool

    path.ellipticalArcTo(rx, ry, xAxisRotation, largeArcFlag, sweepFlag, x, y)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a quadratic Bézier curve to the current sub-path. It requires two points:
  # the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path, which can be changed
  # using moveTo() before creating the quadratic Bézier curve.
  # 
  # path           - object
  # coordinates_1  - list x1,y1
  # coordinates_2  - list x2,y2
  #
  # Returns nothing.
  try:
    var x1, y1, x2, y2: cdouble = 0
    var count: Tcl.Size
    var elements: Tcl.PPObj

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x1 y1} {x2 y2}")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'x1' 'y1'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x2' 'y2'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x2) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y2) != Tcl.OK: return Tcl.ERROR

    path.quadraticCurveTo(x1, y1, x2, y2)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_roundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle. Clockwise parameter can be used to subtract a 
  # rect from a path when using even-odd winding rule. 
  # 
  # path         - object
  # coordinates  - list x,y
  # size         - list width + height
  # radius       - list (nw, ne, se, sw)
  # ccw          - boolean value (optional:true)
  #
  # Returns nothing.
  try:
    var x, y, width, height, nw, ne, se, sw: cdouble = 0
    var count: Tcl.Size
    var clockcw: int = 0
    var ccw: bool = true
    var elements: Tcl.PPObj

    if objc notin (5..6):
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} {width height} {nw ne se sw} ccw:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")

    if Tcl.GetDoubleFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 4:
      return ERROR_MSG(interp, "wrong # args: 'radius' should be 'nw' 'ne' 'se' 'sw'")

    if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK: return Tcl.ERROR

    if objc == 6:
      if Tcl.GetBooleanFromObj(interp, objv[5], clockcw) != Tcl.OK:
        return Tcl.ERROR
      ccw = clockcw.bool

    path.roundedRect(x, y, width, height, nw, ne, se, sw, ccw)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_strokeOverlaps(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns whether or not the specified point is inside the area
  # contained by the stroking of a path.
  # 
  # path         - object
  # coordinates  - list x,y
  # options      - dict (transform:list, strokeWidth:double, lineCap:enum, lineJoin:enum, miterLimit:double, dashes:list) (optional)
  #
  try:
    var x, y, sWidth, v: cdouble = 1.0
    var mymiterLimit: cdouble = defaultMiterLimit
    var count, dashescount: Tcl.Size
    var elements, dasheselements: Tcl.PPObj
    var matrix3: vmath.Mat3 = mat3()
    var mydashes: seq[float32] = @[]
    var myEnumlineCap, myEnumlineJoin: string = "null"
    var val: int = 0

    if objc notin (3..4):
      Tcl.WrongNumArgs(interp, 1, objv, "<path> {x y} {key value key value ...}:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    let path = pathTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

    if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

    if objc == 4:
      # Dict
      if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
        return Tcl.ERROR

      if count mod 2 == 1:
        return ERROR_MSG(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

      var i = 0
      while i < count:
        let mkey = Tcl.GetString(elements[i])
        case $mkey:
          of "strokeWidth":
            if Tcl.GetDoubleFromObj(interp, elements[i+1], sWidth) != Tcl.OK:
              return Tcl.ERROR
          of "transform":
            if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
              return Tcl.ERROR
          of "lineCap":
            let arg = Tcl.GetString(elements[i+1])
            myEnumlineCap = $arg
          of "miterLimit":
            if Tcl.GetDoubleFromObj(interp, elements[i+1], mymiterLimit) != Tcl.OK:
              return Tcl.ERROR
          of "lineJoin":
            let arg = Tcl.GetString(elements[i+1])
            myEnumlineJoin = $arg
          of "dashes":
            if Tcl.ListObjGetElements(interp, elements[i+1], dashescount, dasheselements) != Tcl.OK:
              return Tcl.ERROR
            for j in 0..dashescount-1:
              if Tcl.GetDoubleFromObj(interp, dasheselements[j], v) != Tcl.OK:
                return Tcl.ERROR
              mydashes.add(v)
          else:
            return ERROR_MSG(interp, "wrong # args: Key '" & $mkey & "' not supported.")
        inc(i, 2)

    let myEnumLC = parseEnum[LineCap]($myEnumlineCap, ButtCap)
    let myEnumLJ = parseEnum[LineJoin]($myEnumlineJoin, MiterJoin)

    if path.strokeOverlaps(
      vec2(x, y),
      transform = matrix3,
      strokeWidth = sWidth,
      lineCap = myEnumLC,
      lineJoin = myEnumLJ,
      miterLimit = mymiterLimit,
      dashes = mydashes
    ): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_path_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current path or all paths if special word `all` is specified.
  # 
  # value - path object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<path>|string")
      return Tcl.ERROR
    
    # Image
    let arg1 = Tcl.GetString(objv[1])
    if $arg1 == "all":
      pathTable.clear()
    else:
      pathTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
