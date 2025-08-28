# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_context(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a *new* context.
  #
  # size  - list width,height
  # value - string [color] or [img::new] (optional:none)
  #
  # Returns: A *new* [ctx] object.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "'{width height} ?color:optional' or <image>"
    )
    return Tcl.ERROR

  var 
    width, height: cint
    img: pixie.Image

  # Table
  let ptable = cast[PixTable](clientData)

  if objc == 2:
    # Image or size coordinates.
    let arg1 = $Tcl.GetString(objv[1])
    if ptable.hasImage(arg1):
      img = ptable.getImage(arg1)
    else:
      # Size
      if pixParses.getListInt(interp, objv[1], width, height, 
        "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
        return Tcl.ERROR

      try:
        img = newImage(width, height)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # Size
    if pixParses.getListInt(interp, objv[1], width, height, 
      "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
      return Tcl.ERROR

    try:
      img = newImage(width, height)
      # Color gets.
      img.fill(pixUtils.getColor(objv[2]))
    except InvalidColor as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let
    ctx = newContext(img) 
    pc = toHexPtr(ctx)
    pi = pc.replace("^ctx", "^img")

  # Adds img + ctx.
  ptable.addContext(pc, ctx)
  ptable.addImage(pi, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pc.cstring, -1))

  return Tcl.OK

proc pix_ctx_strokeStyle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets color style current context.
  #
  # context - [ctx::new]
  # color   - [paint::new] or string [color]
  #
  # If the string is not in the correct format, an error
  # will be generated.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color|<paint>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Paint or string [color].
  let arg2 = $Tcl.GetString(objv[2])

  ctx.strokeStyle =
    if ptable.hasPaint(arg2):
      ptable.getPaint(arg2) # Paint
    else:
      try:
        pixUtils.getColor(objv[2]) # Color
      except InvalidColor as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_save(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Saves the entire state of the context
  # by pushing the current state onto a stack.
  #
  # context - [ctx::new]
  #
  # The *pix::ctx::save* procedure adds the current context state
  # to the stack, and the restore() procedure pops the
  # top context state from the stack and restores
  # the context state to the top state.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  ctx.save()

  return Tcl.OK

proc pix_ctx_textBaseline(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Set the base line alignment for the current context.
  #
  # context           - [ctx::new]
  # baselineAlignment - Enum value
  #
  # Parse the second argument as an enum value of type `BaselineAlignment`.
  # This value tells us how to align the text baseline.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=BaselineAlignment")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  let baseline = try:
    parseEnum[BaselineAlignment]($Tcl.GetString(objv[2]))
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  ctx.textBaseline = baseline # Enum

  return Tcl.OK

proc pix_ctx_restore(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Restores the most recently saved context state by popping the top entry
  # in the drawing state stack. If there is no saved state, this method does nothing.
  #
  # context - [ctx::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    ctx.restore()
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_saveLayer(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Saves the entire state of the context by pushing the current state onto a stack
  # and allocates a new image layer for subsequent drawing. Calling restore blends
  # the current layer image onto the prior layer or root image.
  #
  # context - [ctx::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    ctx.saveLayer()
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeSegment(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Strokes a segment (draws a line from ax, ay to bx, by) according to
  # the current strokeStyle and other context settings.
  #
  # context       - [ctx::new]
  # coordinates1  - list x,y
  # coordinates2  - list x1,y1
  #
  # Create a segment using the start and stop vectors
  # 'start' is the beginning point of the segment *(x, y)*
  # 'stop' is the end point of the segment (x1, y1)
  # The segment represents a line that will be drawn from start to stop
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {x1 y1}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates segment
  var x, y, x1, y1: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates1' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  if pixParses.getListDouble(interp, objv[3], x1, y1, 
    "wrong # args: 'coordinates2' should be 'x1' 'y2'") != Tcl.OK:
    return Tcl.ERROR

  let 
    start = vec2(x, y)
    stop  = vec2(x1, y1)

  try:
    ctx.strokeSegment(segment(start, stop))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a rectangle that is stroked (outlined) according to the
  # current strokeStyle and other context settings.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.strokeRect(x, y, width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_quadraticCurveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a quadratic Bézier curve to the current sub-path.
  # It requires two points: the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the quadratic Bézier curve.
  #
  # context       - [ctx::new]
  # coordinates1  - list cpx,cpy
  # coordinates2  - list x,y
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cpx cpy} {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, cpx, cpy: cdouble

  if pixParses.getListDouble(interp, objv[2], cpx, cpy, 
    "wrong # args: 'coordinates1' should be 'cpx' 'cpy'") != Tcl.OK:
    return Tcl.ERROR

  if pixParses.getListDouble(interp, objv[3], x, y, 
    "wrong # args: 'coordinates2' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  ctx.quadraticCurveTo(cpx, cpy, x, y)

  return Tcl.OK

proc pix_ctx_arc(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circular arc to the current sub-path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # radius      - double value
  # angleStart  - double value (radian)
  # angleEnd    - double value (radian)
  # ccw         - boolean value (optional:false)
  #
  # Returns: Nothing.
  if objc notin [6, 7]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> {x y} r angleStart angleEnd ?ccw:optional"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var
    x, y, r, a0, a1: cdouble
    clockcw: cint
    ccw: bool = false

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
    ctx.arc(x, y, r, a0, a1, ccw)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_arcTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circular arc using the given control points and radius.
  #
  # context       - [ctx::new]
  # coordinates1  - list x1,y1
  # coordinates2  - list x2,y2
  # radius        - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x1 y1} {x2 y2} radius")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates1
  var x1, y1, x2, y2, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], x1, y1, 
    "wrong # args: 'coordinates1' should be 'x1' 'y1'") != Tcl.OK:
    return Tcl.ERROR

  # Coordinates2
  if pixParses.getListDouble(interp, objv[3], x2, y2, 
    "wrong # args: 'coordinates2' should be 'x2' 'y2'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[4], radius) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.arcTo(x1, y1, x2, y2, radius)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_bezierCurveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a cubic Bézier curve to the current sub-path.
  # It requires three points: the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the Bézier curve.
  #
  # context      - [ctx::new]
  # coordinates1 - list cp1x,cp1y
  # coordinates2 - list cp2x,cp2y
  # coordinates3 - list x,y
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cp1x cp1y} {cp2x cp2y} {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var cp1x, cp1y, cp2x, cp2y, x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], cp1x, cp1y, 
    "wrong # args: 'coordinates1' should be 'cp1x' 'cp1y'") != Tcl.OK:
    return Tcl.ERROR

  if pixParses.getListDouble(interp, objv[3], cp2x, cp2y, 
    "wrong # args: 'coordinates2' should be 'cp2x' 'cp2y'") != Tcl.OK:
    return Tcl.ERROR

  if pixParses.getListDouble(interp, objv[4], x, y, 
    "wrong # args: 'coordinates3' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  ctx.bezierCurveTo(vec2(cp1x, cp1y), vec2(cp2x, cp2y), vec2(x, y))

  return Tcl.OK

proc pix_ctx_circle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a circle to the current path.
  #
  # context      - [ctx::new]
  # coordinates  - list cx,cy
  # radius       - double value
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var cx, cy, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], cx, cy, 
    "wrong # args: 'coordinates' should be 'cx' 'cy'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK:
    return Tcl.ERROR

  ctx.circle(cx, cy, radius)

  return Tcl.OK

proc pix_ctx_clip(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Turns the path into the current clipping region.
  # The previous clipping region, if any, is intersected
  # with the current or given path to create the new clipping region.
  #
  # context     - [ctx::new]
  # path        - [path::new] (optional)
  # windingRule - Enum value (optional:NonZero)
  #
  # Returns: Nothing.
  if objc notin (2..4):
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> ?<path>:optional ?enum=WindingRule:optional"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    if objc == 3:
      # Path
      let arg2 = $Tcl.GetString(objv[2])
      if ptable.hasPath(arg2):
        let path = ptable.getPath(arg2)
        ctx.clip(path)
      else:
        # Enum
        let myEnum = parseEnum[WindingRule](arg2)
        ctx.clip(myEnum)
    elif objc == 4:
      # Path
      let 
        path = ptable.getPath($Tcl.GetString(objv[2]))
        myEnum = parseEnum[WindingRule]($Tcl.GetString(objv[3]))
      ctx.clip(path, myEnum)
    else:
      ctx.clip()
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_measureText(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Information about the measured text.
  #
  # context  - [ctx::new]
  # text     - string
  #
  # Returns: A Tcl dict that contains information
  # about the measured text (such as its width, for example).
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Text
  let metrics = try:
    ctx.measureText($Tcl.GetString(objv[2]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", 5), Tcl.NewDoubleObj(metrics.width))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_ctx_resetTransform(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Resets the current transform to the identity matrix.
  #
  # context - [ctx::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  ctx.resetTransform()

  return Tcl.OK

proc pix_ctx_drawImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a source image onto the destination image.
  #
  # context  - [ctx::new]
  # image    - [img::new]
  # options  - See description below:
  #
  # There are 3 ways to use this proc:
  #
  # 1. With simple destination:<br>
  # #Begintable
  # **destinationXY** :A list destination coordinates dx,dy.
  # #EndTable
  #
  # 2. With destination + size destination:<br>
  # #Begintable
  # **destinationXY** :A list destination coordinates dx,dy.
  # **destinationWH** :A list destination size dw,dh.
  # #EndTable
  #
  # 3. With source + size source + destination + size destination:<br>
  # #Begintable
  # **source**         :A list source coordinates sx,sy.
  # **sourceWH**       :A list source size sW,SH .
  # **destinationXY**  :A list destination coordinates dx,dy.
  # **destinationWH**  :A list destination size dw,dh.
  # #EndTable
  #
  # Returns: Nothing.
  if objc notin [4, 5, 7]:
    let errMsg = "'<ctx> <img> {dx dy}' or " &
    "'<ctx> <img> {dx dy} {dWidth dHeight}' or " &
    "'<ctx> <img> {sx sy} {sWidth sHeight} {dx dy} {dWidth dHeight}'"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR
  
  let ptable = cast[PixTable](clientData)

  # Context
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Image
  let img = ptable.loadImage(interp, objv[2])
  if img.isNil: return Tcl.ERROR

  var dx, dy, dWidth, dHeight: cdouble

  if objc == 5:
    # Destination
    if pixParses.getListDouble(interp, objv[3], dx, dy, 
      "wrong # args: 'destinationXY' should be 'dx' 'dy'") != Tcl.OK:
      return Tcl.ERROR

    # Size
    if pixParses.getListDouble(interp, objv[4], dWidth, dHeight, 
      "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'") != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.drawImage(img, dx, dy, dWidth, dHeight)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif objc == 7:
    var sx, sy, sWidth, sHeight: cdouble
    # Source
    if pixParses.getListDouble(interp, objv[3], sx, sy, 
      "wrong # args: 'source' should be 'sx' 'sy'") != Tcl.OK:
      return Tcl.ERROR

    # Source Size
    if pixParses.getListDouble(interp, objv[4], sWidth, sHeight, 
      "wrong # args: 'sourceWH' should be 'sWidth' 'sHeight'") != Tcl.OK:
      return Tcl.ERROR

    # Destination
    if pixParses.getListDouble(interp, objv[5], dx, dy, 
      "wrong # args: 'destinationXY' should be 'dx' 'dy'") != Tcl.OK:
      return Tcl.ERROR

    # Destination Size
    if pixParses.getListDouble(interp, objv[6], dWidth, dHeight, 
      "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'") != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    # Destination
    if pixParses.getListDouble(interp, objv[3], dx, dy, 
      "wrong # args: 'destinationXY' should be 'dx' 'dy'") != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.drawImage(img, dx, dy)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_ellipse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds an ellipse to the current sub-path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, rx, ry: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK:
    return Tcl.ERROR

  ctx.ellipse(x, y, rx, ry)

  return Tcl.OK

proc pix_ctx_strokeEllipse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws an ellipse that is stroked (outlined) according
  # to the current strokeStyle and other context settings.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, rx, ry: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.strokeEllipse(vec2(x, y), rx, ry)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_setTransform(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Overrides the transform matrix being applied to the context.
  #
  # context   - [ctx::new]
  # matrix3x3 - list
  #
  # If you want to save the current transform matrix, you can get it by calling
  # *pix::ctx::getTransform* and later restore it using *pix::ct::setTransform*.
  # If you want to add a new transform to the current transform matrix, use
  # *pix::ctx::transform* instead.
  #
  # The matrix is a list of 9 values representing a 3x3 matrix.
  # The values are in column order:<br>
  #```
  # set matrix {
  #   a d g
  #   b e h
  #   c f i
  # }
  #```
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Matrix 3x3 check
  var matrix3: vmath.Mat3

  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  ctx.setTransform(matrix3)

  return Tcl.OK

proc pix_ctx_transform(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Multiplies the current transform with the matrix
  # described by the arguments of this method.
  #
  # context   - [ctx::new]
  # matrix3x3 - list
  #
  # This is useful if you want to add a new transform
  # to the current transform matrix without replacing
  # the current transform matrix.
  #
  # For example, if you have set a transform matrix
  # using *pix::ctx::setTransform* and later want to
  # add a rotation to the current transform matrix,
  # you can use *pix::ctx::transform* to add the rotation
  # to the current transform matrix.
  #
  # Another example is if you want to add a scale
  # to the current transform matrix, you can use
  # *pix::ctx::transform* to add the scale to the current
  # transform matrix.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Matrix 3x3 check
  var matrix3: vmath.Mat3

  if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  ctx.transform(matrix3)

  return Tcl.OK

proc pix_ctx_rotate(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a rotation to the transformation matrix.
  #
  # context - [ctx::new]
  # angle   - double value (radian)
  #
  # The rotation is around the origin (0,0).
  # The rotation is counterclockwise.
  # The angle is in radians.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> angle")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Angle
  var angle: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], angle) != Tcl.OK:
    return Tcl.ERROR

  ctx.rotate(angle)

  return Tcl.OK

proc pix_ctx_translate(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a translation transformation to the current matrix.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  #
  # The translation is by the given *(x, y)* vector in the current
  # coordinate system.
  #
  # This is the same:
  #```
  # ctx.transform = ctx.transform.translate(vec2(x, y))
  # Or:
  # ctx.transform = ctx.transform * Mat3.translation(vec2(x, y))
  #```
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  ctx.translate(x, y)

  return Tcl.OK

proc pix_ctx_lineJoin(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse the string as an enum value of type LineJoin
  # and assign it to the lineJoin property of the context.
  #
  # context  - [ctx::new]
  # lineJoin - Enum value
  #
  # The parseEnum function will raise an exception if the string is not a valid
  # enum value.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=LineJoin")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    # Enum
    ctx.lineJoin = parseEnum[LineJoin]($Tcl.GetString(objv[2]))
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fill(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills the path with the current fillStyle.
  #
  # context     - [ctx::new]
  # path        - [path::new] (optional)
  # windingRule - Enum value (optional:NonZero)
  #
  # If no path is specified, then call *pix::ctx::fill $ctx* with no arguments.
  # This will fill the current path with the current fillStyle.<br>
  # If no fillStyle has been set, it will default to *Color(0.0, 0.0, 0.0, 1.0)*.
  # If no path has been set, it will default to an empty path.
  # If no winding rule has been set, it will default to NonZero.
  #
  # Returns: Nothing.
  if objc notin (2..4):
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> ?<path>:optional ?enum=WindingRule:optional"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  if objc == 3:
    # Path
    let arg2 = $Tcl.GetString(objv[2])
    if ptable.hasPath(arg2):
      let path = ptable.getPath(arg2)
      try:
        ctx.fill(path)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      # Enum only
      try:
        ctx.fill(parseEnum[WindingRule](arg2))
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  elif objc == 4:
    # Path + Enum
    let path = ptable.loadPath(interp, objv[2])
    if path.isNil: return Tcl.ERROR
    try:
      ctx.fill(path, parseEnum[WindingRule]($Tcl.GetString(objv[3])))
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # No path
    try:
      ctx.fill()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_rect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a rectangle to the current path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  ctx.rect(x, y, width, height)

  return Tcl.OK

proc pix_ctx_fillRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a rectangle that is filled according to the current fillStyle.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - list width,height
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.fillRect(x, y, width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_roundedRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a rectangle with rounded corners that is filled according to the current fillStyle.
  #
  # context      - [ctx::new]
  # coordinates  - list x,y
  # size         - list width,height
  # radius       - list {nw ne se sw}
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> {x y} {width height} {nw ne se sw}"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, width, height: cdouble
    nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

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

  ctx.roundedRect(x, y, width, height, nw, ne, se, sw)

  return Tcl.OK

proc pix_ctx_fillRoundedRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a rounded rectangle that is filled according to the current fillStyle.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - list width,height
  # radius      - double value or list radius {nw ne se sw}
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> {x y} {width height} radius|{nw ne se sw}"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, width, height: cdouble
    radius, nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  let 
    pos = vec2(x, y)
    wh  = vec2(width, height)

  if count == 1:
    if Tcl.GetDoubleFromObj(interp, elements[0], radius) != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.fillRoundedRect(rect(pos, wh), radius)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif count == 4:
    if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.fillRoundedRect(rect(pos, wh), nw, ne, se, sw)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    return pixUtils.errorMSG(interp,
    "wrong # args: 'radius' should be a list {nw ne se sw}, or simple value."
    )

  return Tcl.OK

proc pix_ctx_strokeRoundedRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a rounded rectangle that is stroked (outlined) according
  # to the current strokeStyle and other context settings.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - list width,height
  # radius      - double value or list radius {nw ne se sw}
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> {x y} {width height} radius|{nw ne se sw}"
    )
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, width, height: cdouble
    radius, nw, ne, se, sw: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.ListObjGetElements(interp, objv[4], count, elements) != Tcl.OK:
    return Tcl.ERROR

  let 
    pos = vec2(x, y)
    wh  = vec2(width, height)

  if count == 1:
    if Tcl.GetDoubleFromObj(interp, elements[0], radius) != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.strokeRoundedRect(rect(pos, wh), radius)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  elif count == 4:
    if Tcl.GetDoubleFromObj(interp, elements[0], nw) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[1], ne) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[2], se) != Tcl.OK or
       Tcl.GetDoubleFromObj(interp, elements[3], sw) != Tcl.OK:
      return Tcl.ERROR

    try:
      ctx.strokeRoundedRect(rect(pos, wh), nw, ne, se, sw)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    return pixUtils.errorMSG(interp,
    "wrong # args: 'radius' should be a list {nw ne se sw}, or simple value."
    )

  return Tcl.OK

proc pix_ctx_clearRect(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Erases the pixels in a rectangular area.
  #
  # context      - [ctx::new]
  # coordinates  - list x,y
  # size         - list width,height
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListDouble(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.clearRect(x, y, width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillStyle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills current style.
  #
  # context - [ctx::new]
  # value   - [paint::new] or string [color]
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color|<paint>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Paint or string [color].
  let arg2 = $Tcl.GetString(objv[2])

  ctx.fillStyle =
    if ptable.hasPaint(arg2):
      ptable.getPaint(arg2) # Paint
    else:
      try:
        pixUtils.getColor(objv[2]) # Color
      except InvalidColor as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_globalAlpha(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets color alpha.
  #
  # context - [ctx::new]
  # alpha   - double value
  #
  # This determines the transparency level of the drawing operations.
  # The alpha value must be a floating-point number between 0.0 (completely transparent)
  # and 1.0 (completely opaque).
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> alpha")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Alpha
  var alpha: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], alpha) != Tcl.OK:
    return Tcl.ERROR

  if alpha < 0.0 or alpha > 1.0:
    return pixUtils.errorMSG(interp,
    "pix(error): the global alpha should be in the range 0 to 1."
    )

  # Set the global alpha value for the context.
  ctx.globalAlpha = alpha

  return Tcl.OK

proc pix_ctx_moveTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Begins a new sub-path at the point *(x, y)*.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  #
  # This is a fundamental operation,
  # it clears the current path and starts a new path at the point given.<br>
  # The subsequent path operations are all relative to this point.
  # * The point is the starting point of the new path that is being built.
  # * The point is used as the first point of the path that is being built.
  # * The point is used as the reference point for all of the relative path
  # operations, such as lineTo, curveTo, and arc.
  # * The point is used as the starting point for the built path.
  # * The point should be the first point that is used in the path.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Start a new sub-path at the point (x, y).
  ctx.moveTo(x, y)

  return Tcl.OK

proc pix_ctx_isPointInStroke(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks whether or not the specified point is inside the area
  # contained by the stroking of a path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # path        - [path::new] (optional)
  #
  # Returns: A Tcl boolean value.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} ?<path>:optional")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Context
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y: cdouble
    value: int = 0

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  if objc == 4:
    # Path
    let path = ptable.loadPath(interp, objv[3])
    if path.isNil: return Tcl.ERROR
    try:
      if ctx.isPointInStroke(path, x, y): value = 1
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # No Path
    try:
      if ctx.isPointInStroke(x, y): value = 1
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_ctx_isPointInPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks whether or not the specified point is contained in the current path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # path        - [path::new] (optional)
  # windingRule - Enum value (optional:NonZero)
  #
  # Returns: A Tcl boolean value.
  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> {x y} ?<path>:optional ?enum=WindingRule:optional"
    )
    return Tcl.ERROR
  
  let ptable = cast[PixTable](clientData)

  # Context
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y: cdouble
    value: int = 0

  # Coordinates
  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  if objc == 4:
    # Path
    let arg3 = $Tcl.GetString(objv[3])
    if ptable.hasPath(arg3):
      try:
        if ctx.isPointInPath(ptable.getPath(arg3), x, y): value = 1
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      # Enum
      try:
        if ctx.isPointInPath(
          x, y, 
          windingRule = parseEnum[WindingRule](arg3)
        ): value = 1
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  elif objc == 5:
    # Enum + Path
    let path = ptable.loadPath(interp, objv[3])
    if path.isNil: return Tcl.ERROR
    try:
      if ctx.isPointInPath(
        path,
        x, y,
        windingRule = parseEnum[WindingRule]($Tcl.GetString(objv[4]))
      ): value = 1
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      if ctx.isPointInPath(x, y): value = 1
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_ctx_lineTo(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a straight line to the current sub-path by connecting
  # the sub-path's last point to the specified *(x, y)* coordinates.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  #
  # The lineTo method can be called multiple times to draw multiple lines.
  # Each call to lineTo adds a line to the current path, and the stroke
  # method will draw all of the lines in the path.
  #
  # For example, to draw a square with the top-left corner at (10, 10)
  # and the bottom-right corner at (20, 20), you can use the following
  # code:
  #```
  # pix::ctx::moveTo $ctx {10 10}
  # pix::ctx::lineTo $ctx {20 10}
  # pix::ctx::lineTo $ctx {20 20}
  # pix::ctx::lineTo $ctx {10 20}
  # pix::ctx::stroke $ctx
  #```
  #
  # This code will draw a square with the top-left corner at (10, 10)
  # and the bottom-right corner at (20, 20).
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  ctx.lineTo(x, y)

  return Tcl.OK

proc pix_ctx_stroke(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Strokes (outlines) the current or given path with the current strokeStyle.
  #
  # context - [ctx::new]
  # path    - [path::new] (optional)
  #
  # Returns: Nothing.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>:optional")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Context
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  if objc == 3:
    # Path
    let path = ptable.loadPath(interp, objv[2])
    if path.isNil: return Tcl.ERROR

    try:
      ctx.stroke(path)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      ctx.stroke()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_scale(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds a scaling transformation to the context units horizontally and/or vertically.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  ctx.scale(x, y)

  return Tcl.OK

proc pix_ctx_writeFile(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Save context to image file.
  #
  # context  - [ctx::new]
  # filePath - string (\*.png|\*.bmp|\*.qoi|\*.ppm)
  #
  # The context is rendered into an image which is then saved to the
  # file specified by $filePath.<br>
  # Therefore, it's generally safer to specify the format separately
  # from the file name, like so:
  #```
  # pix::ctx::writeFile $ctx 'image.png'
  #```
  #
  # This ensures that the image is saved in the correct format regardless
  # of the current format of the context.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filePath")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    # File
    ctx.image.writeFile($Tcl.GetString(objv[2]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_beginPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Starts a new path by emptying the list of sub-paths.
  #
  # context - [ctx::new]
  #
  # Begin a new path by clearing any existing sub-paths in the context.
  # This is typically used to start drawing a new shape or path.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  ctx.beginPath()

  return Tcl.OK

proc pix_ctx_closePath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Attempts to add a straight line from the current point to
  # the start of the current sub-path. If the shape has already been
  # closed or has only one point, this function does nothing.
  #
  # context - [ctx::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  ctx.closePath()

  return Tcl.OK

proc pix_ctx_lineWidth(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets line width for current context.
  #
  # context - [ctx::new]
  # width   - double value
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> width")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # LineWidth
  var width: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], width) != Tcl.OK:
    return Tcl.ERROR

  ctx.lineWidth = width

  return Tcl.OK

proc pix_ctx_font(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets font for current context.
  #
  # context  - [ctx::new]
  # filepath - string
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filepath")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  ctx.font = $Tcl.GetString(objv[2])

  return Tcl.OK

proc pix_ctx_fontSize(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets font size for current context.
  #
  # context - [ctx::new]
  # size    - double value
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> size")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Context font size.
  var fsize: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], fsize) != Tcl.OK:
    return Tcl.ERROR

  ctx.fontSize = fsize

  return Tcl.OK

proc pix_ctx_fillText(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a text string at the specified coordinates,
  # filling the string's characters with the current fillStyle.
  #
  # context     - [ctx::new]
  # text        - string
  # coordinates - list x,y
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[3], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.fillText($Tcl.GetString(objv[2]), x, y)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillCircle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a circle that is filled according to the current fillStyle
  #
  # context     - [ctx::new]
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var cx, cy, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], cx, cy, 
    "wrong # args: 'coordinates' should be 'cx' 'cy'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK:
    return Tcl.ERROR

  if radius <= 0.0:
    return pixUtils.errorMSG(interp, "The radius must be greater than 0")

  let circle = Circle(pos: vec2(cx, cy), radius: radius)

  try:
    ctx.fillCircle(circle)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillEllipse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws an ellipse that is filled according to the current fillStyle.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, rx, ry: cdouble

  if pixParses.getListDouble(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], rx) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[4], ry) != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.fillEllipse(vec2(x, y), rx, ry)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_fillPolygon(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws an n-sided regular polygon at *(x, y)* of size that is 
  # filled according to the current fillStyle.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, size: cdouble
    sides: cint

  # Coordinates
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
    ctx.fillPolygon(vec2(x, y), size, sides)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_polygon(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Adds an n-sided regular polygon at *(x, y)* of size to the current path.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, size: cdouble
    sides: cint

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
    ctx.polygon(x, y, size, sides)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokePolygon(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws an n-sided regular polygon at *(x, y)* of size that is stroked
  # (outlined) according to the current strokeStyle and other context settings.
  #
  # context     - [ctx::new]
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    x, y, size: cdouble
    sides: cint

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
    ctx.strokePolygon(vec2(x, y), size, sides)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeCircle(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws a circle that is stroked (outlined) according to the current
  # strokeStyle and other context settings.
  #
  # context     - [ctx::new]
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var cx, cy, radius: cdouble

  if pixParses.getListDouble(interp, objv[2], cx, cy, 
    "wrong # args: 'coordinates' should be 'cx' 'cy'") != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[3], radius) != Tcl.OK:
    return Tcl.ERROR

  if radius <= 0:
    return pixUtils.errorMSG(interp,
    "pix(error): the radius must be greater than 0."
    )

  try:
    let circle = Circle(pos: vec2(cx, cy), radius: radius)
    ctx.strokeCircle(circle)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeText(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws the outlines of the characters of a text string at the specified coordinates.
  #
  # context     - [ctx::new]
  # text        - string
  # coordinates - list x,y
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> 'text' {x y}")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  # Coordinates
  var x, y: cdouble

  if pixParses.getListDouble(interp, objv[3], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  try:
    ctx.strokeText($Tcl.GetString(objv[2]), x, y)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_textAlign(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets text alignment.
  #
  # context             - [ctx::new]
  # horizontalAlignment - Enum value
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=HorizontalAlignment")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  try:
    # Enum
    ctx.textAlign = parseEnum[HorizontalAlignment]($Tcl.GetString(objv[2]))
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_get(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Retrieves detailed information about the current context and returns it as a Tcl dictionary.
  #
  # context - [ctx::new]
  #
  # The dictionary includes:
  #
  # * **image**       : A nested Tcl dictionary with the following keys:
  # #Begintable
  #  **addr**         : A pointer to the raw image data.
  #  **width**        : An integer representing the width of the image in pixels.
  #  **height**       : An integer representing the height of the image in pixels.
  # #EndTable
  # * **globalAlpha** : A double value indicating the global alpha (transparency) level of the context.
  #                    This affects the transparency of all drawing operations performed on the context.
  # * **lineWidth**   : A double value specifying the current line width used for stroking operations.
  #                    This determines the thickness of lines drawn in the context.
  # * **lineCap**     : An enum value describing the style of the end caps for lines. Possible values include
  #                    'ButtCap', 'RoundCap', and 'SquareCap', which define how the end points of lines are rendered.
  # * **lineJoin**    : An enum value that indicates the style of the join between two lines. Options include
  #                    'MiterJoin', 'RoundJoin', and 'BevelJoin', each affecting the appearance of corners where lines meet.
  # * **miterLimit**  : A double value that sets the miter limit. This is relevant when 'lineJoin' is set to 'MiterJoin' and
  #                    controls the maximum length of the miter. If the miter limit is exceeded, a bevel join is used instead.
  # * **font**        : A string representing the font settings for text rendering in the context. This includes font family,
  #                    size, weight, and style, and dictates how text appears when drawn onto the context.
  #
  # Returns: 
  # A Tcl dictionary object that contains various properties (see above) of the context,
  # which can be useful for introspection or debugging.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  let 
    dictObj       = Tcl.NewDictObj()
    dictImgObj    = Tcl.NewDictObj()
    newListMatobj = Tcl.NewListObj(0, nil)
    ctxKey        = $Tcl.GetString(objv[1])
    img           = ctxKey.replace("^ctx", "^img")

  discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("addr", 4), Tcl.NewStringObj(img.cstring, -1))
  discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("width", 5), Tcl.NewIntObj(ctx.image.width.cint))
  discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("height", 6), Tcl.NewIntObj(ctx.image.height.cint))

  let mat = ctx.getTransform()
  for x in 0..2:
    for y in 0..2:
      if Tcl.ListObjAppendElement(interp, newListMatobj, Tcl.NewDoubleObj(mat[x][y])) != Tcl.OK:
        return Tcl.ERROR

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("image", 5), dictImgObj)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("globalAlpha", 11),  Tcl.NewDoubleObj(ctx.globalAlpha))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineWidth", 9),     Tcl.NewDoubleObj(ctx.lineWidth))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("miterLimit", 10),   Tcl.NewDoubleObj(ctx.miterLimit))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineCap", 7),       Tcl.NewStringObj(cstring($ctx.lineCap), -1))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineJoin", 8),      Tcl.NewStringObj(cstring($ctx.lineJoin), -1))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("font", 4),          Tcl.NewStringObj(cstring(ctx.font), -1))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("fontSize", 8),      Tcl.NewDoubleObj(ctx.fontSize))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("transform", 9),     newListMatobj)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textAlign", 9),     Tcl.NewStringObj(cstring($ctx.textAlign), -1))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textBaseline", 12), Tcl.NewStringObj(cstring($ctx.textBaseline), -1))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_ctx_setLineDash(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets line dash for current context.
  #
  # context - [ctx::new]
  # dashes  - list
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> dashes")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  var
    v: cdouble
    count: Tcl.Size
    elements: Tcl.PPObj
    pattern : seq[float32]

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  for i in 0..count-1:
    if Tcl.GetDoubleFromObj(interp, elements[i], v) != Tcl.OK:
      return Tcl.ERROR
    pattern.add(v)

  # To get around pixie's problem when my list is not even.
  # See pixparses.nim file for more details.
  if pattern.len mod 2 != 0:
    let dashesCopy = pattern
    pattern.add(dashesCopy)

  ctx.setLineDash(pattern)

  return Tcl.OK

proc pix_ctx_getTransform(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets matrix for current context.
  #
  # context - [ctx::new]
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
  # Returns: A matrix as Tcl list.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  let newListobj = Tcl.NewListObj(0, nil)

  # Get the transformation matrix for the context.
  let mat = ctx.getTransform()
  for x in 0..2:
    for y in 0..2:
      if Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(mat[x][y])) != Tcl.OK:
        return Tcl.ERROR

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_ctx_getLineDash(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets line dash for current context.
  #
  # context - [ctx::new]
  #
  # Returns: A list with current values.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.loadContext(interp, objv[1])
  if ctx.isNil: return Tcl.ERROR

  let newSeqListobj = Tcl.NewListObj(0, nil)

  for _, value in ctx.getLineDash():
    if Tcl.ListObjAppendElement(interp, newSeqListobj, Tcl.NewDoubleObj(value)) != Tcl.OK:
      return Tcl.ERROR

  Tcl.SetObjResult(interp, newSeqListobj)

  return Tcl.OK

proc pix_ctx_fillPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # See [img::fillPath] procedure.
  if objc notin [4, 5]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> <path>|stringPath 'color|<paint>' ?matrix:optional"
    )
    return Tcl.ERROR

  if pix_image_fillpath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_strokePath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # See [img::strokePath] procedure.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<ctx> <path>|stringPath 'color|<paint>' {key value key value ...}"
    )
    return Tcl.ERROR

  if pix_image_strokePath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy current [ctx] or all contexts if special word `all` is specified.
  #
  # value - [ctx] or string value.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $Tcl.GetString(objv[1])

  # Context
  if key == "all":
    ptable.clearContext()
  else:
    ptable.delKeyContext(key)

  return Tcl.OK