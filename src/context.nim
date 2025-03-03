# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_context(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new context.
  #
  # size  - list width,height
  # value - string color or image object (optional:none)
  #
  # Returns a 'new' context object.
  var 
    width, height: int
    count: Tcl.Size
    elements: Tcl.PPObj
    img: pixie.Image

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "'{width height} ?color:optional' or <image>")
    return Tcl.ERROR

  if objc == 2:
    # Image
    let arg1 = $Tcl.GetString(objv[1])
    if pixTables.hasImage(arg1):
      img = pixTables.getImage(arg1)
    else:
      # Size
      if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        return pixUtils.errorMSG(interp, "wrong # args: 'size' should be 'width' 'height'")

      if Tcl.GetIntFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetIntFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

      try:
        img = newImage(width, height)
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # Size
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'size' should be 'width' 'height'")

    if Tcl.GetIntFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

    try:
      img = newImage(width, height)
      # Color gets.
      img.fill(pixUtils.getColor(objv[2]))
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let ctx = try:
    newContext(img)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let 
    pc = toHexPtr(ctx)
    pi = pc.replace("^ctx", "^img")

  # Adds img + ctx.
  pixTables.addContext(pc, ctx)
  pixTables.addImage(pi, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pc.cstring, -1))
    
  return Tcl.OK

proc pix_ctx_strokeStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets color style current context.
  #
  # context - object
  # color   - string
  #
  # The color is set from the string argument provided.
  # The string should be in the format of a HTML color
  # (i.e. "#rrggbb" or "rgb(r,g,b)" or "rgba(r,g,b,a)")
  # where 'r', 'g', 'b' are the red, green and blue color
  # values and 'a' is the alpha value (for transparency).
  #
  # If the string is not in the correct format, an error
  # will be generated.
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    # The color is set for the current context.
    ctx.strokeStyle = SomePaint(pixUtils.getColor(objv[2]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_save(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Saves the entire state of the context  
  # by pushing the current state onto a stack.
  #
  # context - object
  #
  # The save() procedure adds the current context state
  # to the stack, and the restore() procedure pops the
  # top context state from the stack and restores
  # the context state to the top state.
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.save()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_textBaseline(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Set the base line alignment for the current context.
  #
  # context           - object
  # BaselineAlignment - Enum value
  #
  # Parse the second argument as an enum value of type BaselineAlignment.
  # This value tells us how to align the text baseline.
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=BaselineAlignment")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let
    ctx = pixTables.getContext(arg1)
    arg2 = $Tcl.GetString(objv[2])

  try:
    let baseline = parseEnum[BaselineAlignment](arg2)
    ctx.textBaseline = baseline
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_restore(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Restores the most recently saved context state by popping the top entry
  # in the drawing state stack. If there is no saved state, this method does nothing.
  #
  # context - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.restore()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_saveLayer(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Saves the entire state of the context by pushing the current state onto a stack
  # and allocates a new image layer for subsequent drawing. Calling restore blends
  # the current layer image onto the prior layer or root image.
  #
  # context - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.saveLayer()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeSegment(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes a segment (draws a line from ax, ay to bx, by) according to
  # the current strokeStyle and other context settings.
  #
  # context       - object
  # coordinates1  - list x,y
  # coordinates2  - list x1,y1
  #
  # Create a segment using the start and stop vectors
  # 'start' is the beginning point of the segment (x, y)
  # 'stop' is the end point of the segment (x1, y1)
  # The segment represents a line that will be drawn from start to stop
  #
  # Returns nothing.
  var 
    x, y, x1, y1: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {x1 y1}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates segment
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'x1' 'y1'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x1) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y1) != Tcl.OK: return Tcl.ERROR

  let 
    start = vec2(x, y)
    stop  = vec2(x1, y1)

  try:
    ctx.strokeSegment(segment(start, stop))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle that is stroked (outlined) according to the
  # current strokeStyle and other context settings.
  #
  # context     - object
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
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

  try:
    ctx.strokeRect(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a quadratic Bézier curve to the current sub-path.
  # It requires two points: the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the quadratic Bézier curve.
  #
  # context       - object
  # coordinates1  - list cpx,cpy
  # coordinates2  - list x,y
  #
  # Returns nothing.
  var 
    x, y, cpx, cpy: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cpx cpy} {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'cpx' 'cpy'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cpx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cpy) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.quadraticCurveTo(cpx, cpy, x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_arc(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc to the current sub-path.
  #
  # context     - object
  # coordinates - list x,y
  # radius      - double value
  # angleStart  - double value (radian)
  # angleEnd    - double value (radian)
  # ccw         - boolean value (optional:false)
  #
  # Returns nothing.
  var
    x, y, r, a0, a1: cdouble
    count: Tcl.Size
    clockcw: int
    ccw: bool = false
    elements: Tcl.PPObj

  if objc notin (6..7):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} r angleStart angleEnd ?ccw:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK : return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK : return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], r)  != Tcl.OK : return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[4], a0) != Tcl.OK : return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[5], a1) != Tcl.OK : return Tcl.ERROR

  if objc == 7:
    if Tcl.GetBooleanFromObj(interp, objv[6], clockcw) != Tcl.OK:
      return Tcl.ERROR
    ccw = clockcw.bool

  try:
    ctx.arc(x, y, r, a0, a1, ccw)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc using the given control points and radius.
  #
  # context       - object
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
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x1 y1} {x2 y2} radius")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.arcTo(x1, y1, x2, y2, radius)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a cubic Bézier curve to the current sub-path.
  # It requires three points: the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the Bézier curve.
  #
  # context      - object
  # coordinates1 - list cx1,cy1
  # coordinates2 - list cx2,cy2
  # coordinates3 - list x,y
  #
  # Returns nothing.
  var
    cp1x, cp1y, cp2x, cp2y, x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cp1x cp1y} {cp2x cp2y} {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates1' should be 'cp1x' 'cp1y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cp1x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cp1y) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates2' should be 'cp2x' 'cp2y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cp2x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cp2y) != Tcl.OK: return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates3' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.bezierCurveTo(vec2(cp1x, cp1y), vec2(cp2x, cp2y), vec2(x, y))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circle to the current path.
  #
  # context      - object
  # coordinates  - list cx,cy
  # radius       - double value
  #
  # Returns nothing.
  var
    cx, cy, radius: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cy) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.circle(cx, cy, radius)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_clip(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Turns the path into the current clipping region.
  # The previous clipping region, if any, is intersected
  # with the current or given path to create the new clipping region.
  #
  # context     - object
  # path        - object (optional)
  # WindingRule - Enum value (optional:NonZero)
  #
  # Returns nothing.
  if objc notin (2..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>:optional ?enum=WindingRule:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx = pixTables.getContext(arg1)
    arg2 = $Tcl.GetString(objv[2])

  try:
    if objc == 3:
      # Path
      if pixTables.hasPath(arg2):
        let path = pixTables.getPath(arg2)
        ctx.clip(path)
      else:
        # Enum
        let myEnum = parseEnum[WindingRule](arg2)
        ctx.clip(myEnum)
    elif objc == 4:
      # Path
      let 
        path = pixTables.getPath(arg2)
        myEnum = parseEnum[WindingRule]($Tcl.GetString(objv[3]))
      ctx.clip(path, myEnum)
    else:
      ctx.clip()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_measureText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Information about the measured text.
  #
  # context  - object
  # text     - string
  #
  # Returns a TextMetrics object that contains information
  # about the measured text (such as its width, for example).
  let dictObj = Tcl.NewDictObj()

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)
  # Text
  let metrics = try:
    ctx.measureText($Tcl.GetString(objv[2]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", 5), Tcl.NewDoubleObj(metrics.width))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_ctx_resetTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Resets the current transform to the identity matrix.
  #
  # context - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.resetTransform()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_drawImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a source image onto the destination image.
  #
  # context  - object
  # image    - object
  # args     - options described below:
  #
  # destination                                 - list destination coordinates dx,dy <br>
  # destinationXY+destinationWH                 - list destination coordinates dx,dy <br>
  #                                               list destination size dw,dh <br>
  # source+sourceWH+destinationXY+destinationWH - list source coordinates sx,sy <br>
  #                                               list source size sW,SH <br>
  #                                               list destination coordinates dx,dy <br>
  #                                               list destination size dw,dh
  #
  # Returns nothing.
  var
    sx, sy, dx, dy: cdouble
    sWidth, sHeight: cdouble
    dWidth, dHeight: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4 and objc != 5 and objc != 7:
    let errMsg = "<ctx> <img> {dx dy} or " &
    "<ctx> <img> {dx dy} {dWidth dHeight} or " &
    "<ctx> <img> {sx sy} {sWidth sHeight} {dx dy} {dWidth dHeight}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Image
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasImage(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg2 & "'")

  let img = pixTables.getImage(arg2)

  if objc == 5:
    # Destination
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")

    if Tcl.GetDoubleFromObj(interp, elements[0], dx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], dy) != Tcl.OK: return Tcl.ERROR

    # Size
    if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'")

    if Tcl.GetDoubleFromObj(interp, elements[0], dWidth)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], dHeight) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.drawImage(img, dx, dy, dWidth, dHeight)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif objc == 7:
    # Source
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'source' should be 'sx' 'sy'")

    if Tcl.GetDoubleFromObj(interp, elements[0], sx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], sy) != Tcl.OK: return Tcl.ERROR

    # Source Size
    if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'sourceWH' should be 'sWidth' 'sHeight'")

    if Tcl.GetDoubleFromObj(interp, elements[0], sWidth)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], sHeight) != Tcl.OK: return Tcl.ERROR

    # Destination
    if Tcl.ListObjGetElements(interp, objv[5], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")

    if Tcl.GetDoubleFromObj(interp, elements[0], dx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], dy) != Tcl.OK: return Tcl.ERROR

    # Destination Size
    if Tcl.ListObjGetElements(interp, objv[6], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'")

    if Tcl.GetDoubleFromObj(interp, elements[0], dWidth)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], dHeight) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    # Destination
    if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")

    if Tcl.GetDoubleFromObj(interp, elements[0], dx) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], dy) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.drawImage(img, dx, dy)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an ellipse to the current sub-path.
  #
  # context     - object
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns nothing.
  var
    x, y, rx, ry: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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
    ctx.ellipse(x, y, rx, ry)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeEllipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an ellipse that is stroked (outlined) according
  # to the current strokeStyle and other context settings.
  #
  # context     - object
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns nothing.
  var
    x, y, rx, ry: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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
    ctx.strokeEllipse(vec2(x, y), rx, ry)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_setTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Overrides the transform matrix being applied to the context.
  #
  # context   - object
  # matrix3x3 - list
  #
  # If you want to save the current transform matrix, you can get it by calling
  # `pix::ctx::getTransform` and later restore it using `pix::ct::setTransform`.
  # If you want to add a new transform to the current transform matrix, use
  # `pix::ctx::transform` instead.
  #
  # The matrix is a list of 9 values representing a 3x3 matrix.
  # The values are in row-major order:<br>
  # a b c<br>
  # d e f<br>
  # g h i<br>
  #
  # Returns nothing.
  var matrix3: vmath.Mat3

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Matrix 3x3 check
  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.setTransform(matrix3)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Multiplies the current transform with the matrix
  # described by the arguments of this method.
  #
  # context   - object
  # matrix3x3 - list
  #
  # This is useful if you want to add a new transform
  # to the current transform matrix without replacing
  # the current transform matrix.
  #
  # For example, if you have set a transform matrix
  # using `pix::ctx::setTransform` and later want to
  # add a rotation to the current transform matrix,
  # you can use `pix::ctx::transform` to add the rotation
  # to the current transform matrix.
  #
  # Another example is if you want to add a scale
  # to the current transform matrix, you can use
  # `pix::ctx::transform` to add the scale to the current
  # transform matrix.
  #
  # Returns nothing.
  var matrix3: vmath.Mat3

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Matrix 3x3 check
  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.transform(matrix3)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_rotate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rotation to the transformation matrix.
  #
  # context - object
  # angle  - double value (radian)
  #
  # The rotation is around the origin (0,0).
  # The rotation is counterclockwise.
  # The angle is in radians.
  #
  # Returns nothing.
  var angle: cdouble

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> angle")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Angle
  if Tcl.GetDoubleFromObj(interp, objv[2], angle) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.rotate(angle)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_translate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a translation transformation to the current matrix.
  #
  # context     - object
  # coordinates - list x,y
  #
  # The translation is by the given (x, y) vector in the current
  # coordinate system.
  #
  # This is the same as ctx.transform = ctx.transform.translate(vec2(x, y))
  # or ctx.transform = ctx.transform * Mat3.translation(vec2(x, y))
  #
  # This is the same as ctx.translate(x, y) in the C++ API.
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.translate(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_lineJoin(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse the string as an enum value of type LineJoin
  # and assign it to the lineJoin property of the context.
  #
  # context  - object
  # LineJoin - Enum value
  #
  # This is the same as ctx.lineJoin = LineJoin.arg2 in the C++ API.
  #
  # The parseEnum function will raise an exception if the string is not a valid
  # enum value.
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=LineJoin")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])
  # Enum
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    # Enum
    ctx.lineJoin = parseEnum[LineJoin](arg2)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the path with the current fillStyle.
  #
  # context     - object
  # path        - object (optional)
  # WindingRule - Enum value (optional:NonZero)
  #
  # If no path is specified, then call 'pix::ctx::fill $ctx' with no arguments.
  # This will fill the current path with the current fillStyle.
  # If no fillStyle has been set, it will default to Color(0.0, 0.0, 0.0, 1.0).
  # If no path has been set, it will default to an empty path.
  # If no winding rule has been set, it will default to NonZero.
  #
  # Returns nothing.
  if objc notin (2..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>:optional ?enum=WindingRule:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if objc == 3:
    # Path
    let arg2 = $Tcl.GetString(objv[2])
    if pixTables.hasPath(arg2):
      let path = pixTables.getPath(arg2)
      try:
        ctx.fill(path)
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      # Enum only
      try:
        ctx.fill(parseEnum[WindingRule](arg2))
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  elif objc == 4:
    # Path + Enum
    let arg2 = $Tcl.GetString(objv[2])
    if not pixTables.hasPath(arg2):
      return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg2 & "'")
    let path = pixTables.getPath(arg2)
    try:
      ctx.fill(path, parseEnum[WindingRule]($Tcl.GetString(objv[3])))
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # No path
    try:
      ctx.fill()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle to the current path.
  #
  # context     - object
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  try:
    ctx.rect(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle that is filled according to the current fillStyle.
  #
  # context     - object
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  try:
    ctx.fillRect(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_roundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle with rounded corners that is filled according to the current fillStyle.
  #
  # context      - object
  # coordinates  - list x,y
  # size         - list
  # radius       - list (nw, ne, se, sw)
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} {nw ne se sw}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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
    return pixUtils.errorMSG(interp, "wrong # args: 'radius' should be {nw ne se sw}")

  if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.roundedRect(x, y, width, height, nw, ne, se, sw)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillRoundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rounded rectangle that is filled according to the current fillStyle.
  #
  # context     - object
  # coordinates - list x,y
  # size        - list width,height
  # radius      - double value or list radius (nw, ne, se, sw)
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    radius, nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} radius|{nw ne se sw}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  let 
    pos = vec2(x, y)
    wh  = vec2(width, height)

  if count == 1:
    if Tcl.GetDoubleFromObj(interp, elements[0], radius) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.fillRoundedRect(rect(pos, wh), radius)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif count == 4:
    if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.fillRoundedRect(rect(pos, wh), nw, ne, se, sw)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    return pixUtils.errorMSG(interp, "wrong # args: 'radius' should be a list {nw ne se sw}, or simple value.")

  return Tcl.OK

proc pix_ctx_strokeRoundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rounded rectangle that is stroked (outlined) according
  # to the current strokeStyle and other context settings.
  #
  # context     - object
  # coordinates - list x,y
  # size        - list width,height
  # radius      - double value or list radius (nw, ne, se, sw)
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    radius, nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} radius|{nw ne se sw}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  let 
    pos = vec2(x, y)
    wh  = vec2(width, height)

  if count == 1:
    if Tcl.GetDoubleFromObj(interp, elements[0], radius) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.strokeRoundedRect(rect(pos, wh), radius)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif count == 4:
    if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK: return Tcl.ERROR

    try:
      ctx.strokeRoundedRect(rect(pos, wh), nw, ne, se, sw)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    return pixUtils.errorMSG(interp, "wrong # args: 'radius' should be a list {nw ne se sw}, or simple value.")

  return Tcl.OK

proc pix_ctx_clearRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Erases the pixels in a rectangular area.
  #
  # context      - object
  # coordinates  - list x,y
  # size         - list width,height
  #
  # Returns nothing.
  var
    x, y, width, height: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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

  try:
    ctx.clearRect(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills current style.
  #
  # context - object
  # value   - paint object or string color
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color|<paint>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx  = pixTables.getContext(arg1)
    arg2 = $Tcl.GetString(objv[2])

  if pixTables.hasPaint(arg2):
    # Paint
    try:
      ctx.fillStyle = pixTables.getPaint(arg2)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # Color
    try:
      ctx.fillStyle = pixUtils.getColor(objv[2])
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_globalAlpha(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets color alpha.
  #
  # context - object
  # alpha   - double value
  #
  # This determines the transparency level of the drawing operations.
  # The alpha value must be a floating-point number between 0.0 (completely transparent)
  # and 1.0 (completely opaque).
  #
  # Returns nothing.
  var alpha: cdouble

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> alpha")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.GetDoubleFromObj(interp, objv[2], alpha) != Tcl.OK:
    return Tcl.ERROR

  if alpha < 0.0 or alpha > 1.0:
    return pixUtils.errorMSG(interp, "global alpha must be between 0 and 1" )

  try:
    # Set the global alpha value for the context.
    ctx.globalAlpha = alpha
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Begins a new sub-path at the point (x, y).
  #
  # context     - object
  # coordinates - list x,y
  #
  # This is a fundamental operation,
  # it clears the current path and starts a new path at the point given.
  # The subsequent path operations are all relative to this point.
  # The point is the starting point of the new path that is being built.
  # The point is used as the first point of the path that is being built.
  # The point is used as the reference point for all of the relative path
  # operations, such as lineTo, curveTo, and arc.
  # The point is used as the starting point for the built path.
  # The point should be the first point that is used in the path.
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    # Start a new sub-path at the point (x, y).
    ctx.moveTo(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_isPointInStroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks whether or not the specified point is inside the area
  # contained by the stroking of a path.
  #
  # context     - object
  # coordinates - list x,y
  # path        - object (optional)
  #
  # Returns true, false otherwise.
  var
    x, y: cdouble
    count: Tcl.Size
    value: int = 0
    elements: Tcl.PPObj

  if objc notin (3..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} ?<path>:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if objc == 4:
    # Path
    let arg3 = $Tcl.GetString(objv[3])

    if not pixTables.hasPath(arg3):
      return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg3 & "'")

    try:
      if ctx.isPointInStroke(pixTables.getPath(arg3), x, y): value = 1
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # No Path
    try:
      if ctx.isPointInStroke(x, y): value = 1
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_ctx_isPointInPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks whether or not the specified point is contained in the current path.
  #
  # context     - object
  # coordinates - list x,y
  # path        - object (optional)
  # WindingRule - Enum value (optional:NonZero)
  #
  # Returns true, false otherwise.
  var
    x, y: cdouble
    count: Tcl.Size
    value: int = 0
    elements: Tcl.PPObj

  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} ?<path>:optional ?enum=WindingRule:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  let arg3 = $Tcl.GetString(objv[3])

  if objc == 4:
    # Path
    if pixTables.hasPath(arg3):
      try:
        if ctx.isPointInPath(pixTables.getPath(arg3), x, y): value = 1
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      # Enum
      try:
        if ctx.isPointInPath(
          x, y, 
          windingRule = parseEnum[WindingRule](arg3)
        ): value = 1
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  elif objc == 5:
    # Enum + Path
    if not pixTables.hasPath(arg3):
      return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg3 & "'")
    try:
      if ctx.isPointInPath(
        pixTables.getPath(arg3),
        x, y,
        windingRule = parseEnum[WindingRule]($Tcl.GetString(objv[4]))
      ): value = 1
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)    
  else:
    try:
      if ctx.isPointInPath(x, y): value = 1
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_ctx_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified (x, y) coordinates.
  #
  # context     - object
  # coordinates - list x,y
  #
  # The lineTo method can be called multiple times to draw multiple lines.
  # Each call to lineTo adds a line to the current path, and the stroke
  # method will draw all of the lines in the path.
  #
  # For example, to draw a square with the top-left corner at (10, 10)
  # and the bottom-right corner at (20, 20), you can use the following
  # code:
  #
  #   pix::ctx::moveTo $ctx {10 10}
  #   pix::ctx::lineTo $ctx {20 10}
  #   pix::ctx::lineTo $ctx {20 20}
  #   pix::ctx::lineTo $ctx {10 20}
  #   pix::ctx::stroke $ctx
  #
  # This code will draw a square with the top-left corner at (10, 10)
  # and the bottom-right corner at (20, 20).
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.lineTo(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_stroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes (outlines) the current or given path with the current strokeStyle.
  #
  # context - object
  # path    - object (optional)
  #
  # Returns nothing.
  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>:optional")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if objc == 3:
    # Path
    let arg2 = $Tcl.GetString(objv[2])
    if not pixTables.hasPath(arg2):
      return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg2 & "'")

    try:
      ctx.stroke(pixTables.getPath(arg2))
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      ctx.stroke()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_scale(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a scaling transformation to the context units horizontally and/or vertically.
  #
  # context     - object
  # coordinates - list x,y
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.scale(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_writeFile(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Save context to image file.
  #
  # context  - object
  # filePath - string (\*.png|\*.bmp|\*.qoi|\*.ppm)
  #
  # The context is rendered into an image which is then saved to the
  # file specified by `filePath`.
  #
  # Therefore, it's generally safer to specify the format separately
  # from the file name, like so:
  #
  #   pix::ctx::writeFile $ctx "image.png"
  #
  # This ensures that the image is saved in the correct format regardless
  # of the current format of the context.
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filePath")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx  = pixTables.getContext(arg1)
    file = $Tcl.GetString(objv[2])

  try:
    ctx.image.writeFile(file)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_beginPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Starts a new path by emptying the list of sub-paths.
  #
  # context - object
  #
  # Begin a new path by clearing any existing sub-paths in the context.
  # This is typically used to start drawing a new shape or path.
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.beginPath()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Attempts to add a straight line from the current point to
  # the start of the current sub-path. If the shape has already been
  # closed or has only one point, this function does nothing.
  #
  # context - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.closePath()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_lineWidth(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets line width for current context.
  #
  # context - object
  # width   - double value
  #
  # Returns nothing.
  var width: cdouble

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> width")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.GetDoubleFromObj(interp, objv[2], width) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.lineWidth = width
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_font(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font for current context.
  #
  # context  - object
  # filepath - string
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filepath")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    ctx.font = $Tcl.GetString(objv[2])
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fontSize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font size for current context.
  #
  # context - object
  # size    - double value
  #
  # Returns nothing.
  var fsize: cdouble

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> size")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.GetDoubleFromObj(interp, objv[2], fsize) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.fontSize = fsize
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a text string at the specified coordinates,
  # filling the string's characters with the current fillStyle.
  #
  # context     - object
  # text        - string
  # coordinates - list x,y
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx  = pixTables.getContext(arg1)
    text = $Tcl.GetString(objv[2])

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.fillText(text, x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillCircle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a circle that is filled according to the current fillStyle
  #
  # context     - object
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns nothing.
  var
    cx, cy, radius: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cy) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK: return Tcl.ERROR

  if radius <= 0:
    return pixUtils.errorMSG(interp, "The radius must be greater than 0")

  try:
    let circle = Circle(pos: vec2(cx, cy), radius: radius)
    ctx.fillCircle(circle)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillEllipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an ellipse that is filled according to the current fillStyle.
  #
  # context     - object
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns nothing.
  var
    x, y, rx, ry: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.fillEllipse(vec2(x, y), rx, ry)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillPolygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an n-sided regular polygon at (x, y) of size that is filled according to the current fillStyle.
  #
  # context     - object
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns nothing.
  var
    x, y, size: cdouble
    count: Tcl.Size
    sides: int
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], size) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetIntFromObj(interp, objv[4], sides)   != Tcl.OK: return Tcl.ERROR

  try:
    ctx.fillPolygon(vec2(x, y), size, sides)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_polygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an n-sided regular polygon at (x, y) of size to the current path.
  #
  # context     - object
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns nothing.
  var
    x, y, size: cdouble
    count: Tcl.Size
    sides: int
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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
    ctx.polygon(x, y, size, sides)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokePolygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an n-sided regular polygon at (x, y) of size that is stroked
  # (outlined) according to the current strokeStyle and other context settings.
  #
  # context     - object
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns nothing.
  var
    x, y, size: cdouble
    count: Tcl.Size
    sides: int
    elements: Tcl.PPObj

  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

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
    ctx.strokePolygon(vec2(x, y), size, sides)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeCircle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a circle that is stroked (outlined) according to the current
  # strokeStyle and other context settings.
  #
  # context     - object
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns nothing.
  var
    cx, cy, radius: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  # Coordinates
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")

  if Tcl.GetDoubleFromObj(interp, elements[0], cx) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], cy) != Tcl.OK: return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK: return Tcl.ERROR

  if radius <= 0:
    return pixUtils.errorMSG(interp, "The radius must be greater than 0")

  try:
    let circle = Circle(pos: vec2(cx, cy), radius: radius)
    ctx.strokeCircle(circle)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws the outlines of the characters of a text string at the specified coordinates.
  #
  # context     - object
  # text        - string
  # coordinates - list x,y
  #
  # Returns nothing.
  var
    x, y: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> 'text' {x y}")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let
    ctx = pixTables.getContext(arg1)
    text = $Tcl.GetString(objv[2])

  if Tcl.ListObjGetElements(interp, objv[3], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK: return Tcl.ERROR
  if Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK: return Tcl.ERROR

  try:
    ctx.strokeText(text, x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_textAlign(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets text alignment.
  #
  # context             - object
  # HorizontalAlignment - Enum value
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=HorizontalAlignment")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx  = pixTables.getContext(arg1)
    arg2 = $Tcl.GetString(objv[2])

  try:
    # Enum
    ctx.textAlign = parseEnum[HorizontalAlignment](arg2)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_get(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets information about context.
  #
  # context - object
  #
  # Returns Tcl dict value.
  let 
    dictObj       = Tcl.NewDictObj()
    dictImgObj    = Tcl.NewDictObj()
    newListMatobj = Tcl.NewListObj(0, nil)

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let 
    ctx = pixTables.getContext(arg1)
    img = arg1.replace("^ctx", "^img")

  try:
    let 
      myEnumLineCap      = ctx.lineCap
      myEnumLineJoin     = ctx.lineJoin
      myEnumTextAlign    = ctx.textAlign
      myEnumTextBaseline = ctx.textBaseline

    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("addr", 4), Tcl.NewStringObj(img.cstring, -1))
    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("width", 5), Tcl.NewIntObj(ctx.image.width))
    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("height", 6), Tcl.NewIntObj(ctx.image.height))

    let mat = ctx.getTransform()

    for x in 0..2:
      for y in 0..2:
        discard Tcl.ListObjAppendElement(interp, newListMatobj, Tcl.NewDoubleObj(mat[x][y]))

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("image", 5), dictImgObj)
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("globalAlpha", 11),  Tcl.NewDoubleObj(ctx.globalAlpha))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineWidth", 9),     Tcl.NewDoubleObj(ctx.lineWidth))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("miterLimit", 10),   Tcl.NewDoubleObj(ctx.miterLimit))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineCap", 7),       Tcl.NewStringObj(cstring($myEnumLineCap), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineJoin", 8),      Tcl.NewStringObj(cstring($myEnumLineJoin), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("font", 4),          Tcl.NewStringObj(cstring(ctx.font), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("fontSize", 8),      Tcl.NewDoubleObj(ctx.fontSize))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("transform", 9),     newListMatobj)
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textAlign", 9),     Tcl.NewStringObj(cstring($myEnumTextAlign), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textBaseline", 12), Tcl.NewStringObj(cstring($myEnumTextBaseline), -1))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_ctx_setLineDash(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets line dash for current context.
  #
  # context - object
  # dashes  - list
  #
  # Returns nothing.
  var
    v: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj
    pattern : seq[float32]

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> dashes")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  for i in 0..count-1:
    if Tcl.GetDoubleFromObj(interp, elements[i], v) != Tcl.OK:
      return Tcl.ERROR
    pattern.add(v)

  try:
    ctx.setLineDash(pattern)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_getTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets matrix for current context.
  #
  # context - object
  #
  # The matrix is represented as a sequence of 3 sequences
  # of floats, where each inner sequence represents a row
  # of the matrix.
  #
  # The first element of the first row represents the x
  # component of the transformation, the second element
  # represents the y component of the transformation, and
  # the third element represents the z component of the
  # transformation.
  #
  # Returns list values.
  let newListobj = Tcl.NewListObj(0, nil)

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    # Get the transformation matrix for the context.
    let mat = ctx.getTransform()
    for x in 0..2:
      for y in 0..2:
        discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(mat[x][y]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_ctx_getLineDash(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets line dash for current context.
  #
  # context - object
  # values  - list
  #
  # Returns list values.
  let newSeqListobj = Tcl.NewListObj(0, nil)

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasContext(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")

  let ctx = pixTables.getContext(arg1)

  try:
    for _, value in ctx.getLineDash():
      discard Tcl.ListObjAppendElement(interp, newSeqListobj, Tcl.NewDoubleObj(value))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, newSeqListobj)

  return Tcl.OK

proc pix_ctx_fillPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # See [img::fillPath] procedure.
  if objc notin (4..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>|stringPath 'color|<paint>' ?matrix:optional")
    return Tcl.ERROR

  if pix_image_fillpath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # See [img::strokePath] procedure.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>|stringPath 'color|<paint>' {key value key value ...}")
    return Tcl.ERROR

  if pix_image_strokePath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current context or all contexts if special word `all` is specified.
  #
  # value - context object or string
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:
    if arg1 == "all":
      ctxTable.clear()
    else:
      ctxTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK
