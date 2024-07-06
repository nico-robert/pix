# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_context(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new context.
  # 
  # size  - list width + height
  # value - string color or image object (optional:none)
  #
  # Returns a 'new' context object.
  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var img: Image

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "'{width height} color:optional' or <image>")
      return Tcl.ERROR

    if objc == 2:
      # Image
      let arg1 = Tcl.GetStringFromObj(objv[1], nil)
      if imgTable.hasKey($arg1):
        img = imgTable[$arg1]
      else:
        # Size
        if Tcl.ListObjGetElements(interp, objv[1], count.addr, elements.addr) != Tcl.OK:
          return Tcl.ERROR
        
        if count != 2:
          ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
          return Tcl.ERROR
          
        if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
        if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
        
        img = newImage(width, height)
    else:
      # Size
      if Tcl.ListObjGetElements(interp, objv[1], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR
      
      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
        return Tcl.ERROR
        
      if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
      
      # Color RGBA check
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      let color = parseHtmlColor($arg2).rgba

      img = newImage(width, height)
      img.fill(color)

    let ctx   = newContext(img)
    let myPtr = cast[pointer](ctx)
    let hex   = "0x" & cast[uint64](myPtr).toHex
    let pc    = (hex & "^ctx").toLowerAscii
    let pi    = (hex & "^img").toLowerAscii

    # Adds img + ctx.
    ctxTable[pc] = ctx
    imgTable[pi] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(pc.cstring, -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_strokeStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets color style current context.
  # 
  # context - object
  # color   - string
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    ctx.strokeStyle = parseHtmlColor($arg2).rgba

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_save(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Saves the entire state of the context by pushing the current state onto a stack.
  # 
  # context - object
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.save()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_textBaseline(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Set the base line alignment for the current context.
  # 
  # context           - object
  # BaselineAlignment - Enum value
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=BaselineAlignment")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    let baseline = parseEnum[BaselineAlignment]($arg2)

    ctx.textBaseline = baseline

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR


proc pix_ctx_restore(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Restores the most recently saved context state by popping the top entry 
  # in the drawing state stack. If there is no saved state, this method does nothing.
  # 
  # context - object
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.restore()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_saveLayer(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Saves the entire state of the context by pushing the current state onto a stack
  # and allocates a new image layer for subsequent drawing. Calling restore blends
  # the current layer image onto the prior layer or root image.
  # 
  # context - object
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.saveLayer()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_strokeSegment(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes a segment (draws a line from ax, ay to bx, by) according to
  # the current strokeStyle and other context settings.
  # 
  # context        - object
  # coordinates_1  - list x,y 
  # coordinates_2  - list x1,y1
  #
  # Returns nothing.
  try:
    let x, y, x1, y1: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {x1 y1}")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates segment
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x1' 'y1'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x1.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y1.addr) != Tcl.OK: return Tcl.ERROR

    let start = vec2(x, y)
    let stop  = vec2(x1, y1)
    ctx.strokeSegment(segment(start, stop))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_strokeRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle that is stroked (outlined) according to the
  # current strokeStyle and other context settings.
  # 
  # context     - object
  # coordinates - list x,y
  # size        - list width + height
  #
  # Returns nothing.
  try:
    let x, y, width, height: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    ctx.strokeRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a quadratic Bézier curve to the current sub-path.
  # It requires two points: the first one is a control point and the second one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the quadratic Bézier curve.
  # 
  # context      - object
  # coordinates_1  - list cpx,cpy
  # coordinates_2  - list x,y 
  #
  # Returns nothing.
  try:
    let x, y, cpx, cpy: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cpx cpy} {x y}")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'cpx' 'cpy'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cpx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cpy.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.quadraticCurveTo(cpx, cpy, x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR


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
  try:
    let x, y, r, a0, a1: cdouble = 0
    let count, clockcw: cint = 0
    var ccw: bool = false
    let elements : Tcl.PPObj = nil

    if objc notin (6..7):
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} r angleStart angleEnd ccw:optional")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK : return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK : return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], r.addr)     != Tcl.OK : return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], a0.addr)    != Tcl.OK : return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[5], a1.addr)    != Tcl.OK : return Tcl.ERROR
      
    if objc == 7:
      if Tcl.GetBooleanFromObj(interp, objv[6], clockcw.addr) != Tcl.OK:
        return Tcl.ERROR
      if clockcw.uint8 == 1:
        ccw = true

    ctx.arc(x, y, r, a0, a1, ccw)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circular arc using the given control points and radius.
  # 
  # context       - object
  # coordinates_1 - list x1,y1
  # coordinates_2 - list x2,y2
  # radius        - double value
  #
  # Returns nothing.
  try:
    let x1, y1, x2, y2, radius: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    
    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x1 y1} {x2 y2} radius")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'x1' 'y1'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x1.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y1.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'x2' 'y2'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x2.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y2.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[4], radius.addr) != Tcl.OK: return Tcl.ERROR
      
    ctx.arcTo(x1, y1, x2, y2, radius)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a cubic Bézier curve to the current sub-path.
  # It requires three points: the first two are control points and the third one is the end point.
  # The starting point is the latest point in the current path,
  # which can be changed using moveTo() before creating the Bézier curve.
  # 
  # context       - object
  # coordinates_1 - list cx1,cy1
  # coordinates_2 - list cx2,cy2
  # coordinates_3 - list x,y
  #
  # Returns nothing.
  try:
    let cp1x, cp1y, cp2x, cp2y, x, y: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    
    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cp1x cp1y} {cp2x cp2y} {x y}")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_1' should be 'cp1x' 'cp1y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cp1x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cp1y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_2' should be 'cp2x' 'cp2y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cp2x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cp2y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates_3' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    ctx.bezierCurveTo(vec2(cp1x, cp1y), vec2(cp2x, cp2y), vec2(x, y))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a circle to the current path.
  # 
  # context      - object
  # coordinates  - list cx,cy
  # radius       - double value
  #
  # Returns nothing.
  try:
    let cx, cy, radius: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    
    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cy.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], radius.addr) != Tcl.OK: return Tcl.ERROR

    ctx.circle(cx, cy, radius)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

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
  try:

    if objc notin (2..4):
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>:optional enum=WindingRule:optional")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    if objc == 3:
      # Path
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      if pathTable.hasKey($arg2):
        let path = pathTable[$arg2]
        ctx.clip(path)
      else:
        # Enum
        let myEnum = parseEnum[WindingRule]($arg2)
        ctx.clip(myEnum)
    elif objc == 4:
      # Path
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      let path = pathTable[$arg2]
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let myEnum = parseEnum[WindingRule]($arg3)
      ctx.clip(path, myEnum)
    else:
      ctx.clip()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_measureText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns a TextMetrics object that contains information
  # about the measured text (such as its width, for example).
  # 
  # context  - object
  # text     - string
  #
  # Returns Tcl dict value {width}.
  try:
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Text
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let text = $arg2

    let metrics = ctx.measureText(text)

    let dictObj = Tcl.NewDictObj()
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", -1), Tcl.NewDoubleObj(metrics.width))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_resetTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Resets the current transform to the identity matrix.
  # 
  # context - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.resetTransform()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

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
  try:
    let sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4 and objc != 5 and objc != 7:
      let msg = """ <ctx> <img> {dx dy} or
      <ctx> <img> {dx dy} {dWidth dHeight} or
      <ctx> <img> {sx sy} {sWidth sHeight} {dx dy} {dWidth dHeight}"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Image
    let im = Tcl.GetStringFromObj(objv[2], nil)
    let img = imgTable[$im]
    
    if objc == 5:
      # Destination
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK: return Tcl.ERROR

      # Size
      if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dWidth.addr)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], dHeight.addr) != Tcl.OK: return Tcl.ERROR

      ctx.drawImage(img, dx, dy, dWidth, dHeight)

    elif objc == 7:
      # Source
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'source' should be 'sx' 'sy'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], sx.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], sy.addr) != Tcl.OK: return Tcl.ERROR

      # Source Size
      if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'sourceWH' should be 'sWidth' 'sHeight'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], sWidth.addr)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], sHeight.addr) != Tcl.OK: return Tcl.ERROR

      # Destination
      if Tcl.ListObjGetElements(interp, objv[5], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK: return Tcl.ERROR

      # Destination Size
      if Tcl.ListObjGetElements(interp, objv[6], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'destinationWH' should be 'dWidth' 'dHeight'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dWidth.addr)  != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], dHeight.addr) != Tcl.OK: return Tcl.ERROR

      ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)

    else:
      # Destination
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        ERROR_MSG(interp, "wrong # args: 'destinationXY' should be 'dx' 'dy'")
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK: return Tcl.ERROR

      ctx.drawImage(img, dx, dy)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an ellipse to the current sub-path.
  # 
  # context     - object
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns nothing.
  try:
    let x, y, rx, ry: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
    
    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[3], rx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], ry.addr) != Tcl.OK: return Tcl.ERROR

    ctx.ellipse(x, y, rx, ry)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

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
  try:
    let x, y, rx, ry: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
    
    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[3], rx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], ry.addr) != Tcl.OK: return Tcl.ERROR

    ctx.strokeEllipse(vec2(x, y), rx, ry)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR


proc pix_ctx_setTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Overrides the transform matrix being applied to the context.
  # 
  # context   - object
  # matrix3x3 - list
  #
  # Returns nothing.
  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Matrix 3x3 check
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    ctx.setTransform(matrix3)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Multiplies the current transform with the matrix 
  # described by the arguments of this method.
  # 
  # context   - object
  # matrix3x3 - list
  #
  # Returns nothing.
  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> matrix3x3")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Matrix 3x3 check
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    ctx.transform(matrix3)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_rotate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rotation to the transformation matrix.
  # 
  # context - object
  # angle  - double value (radian)
  #
  # Returns nothing.
  try:
    let angle: cdouble = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> angle")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Angle
    if Tcl.GetDoubleFromObj(interp, objv[2], angle.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.rotate(angle)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_translate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a translation transformation to the current matrix.
  # 
  # context     - object
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.translate(x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_lineJoin(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets enum value.
  # 
  # context  - object
  # LineJoin - Enum value
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=LineJoin")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Enum
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let myEnum = parseEnum[LineJoin]($arg2)

    ctx.lineJoin = myEnum

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the path with the current fillStyle.
  # 
  # context     - object
  # path        - object (optional)
  # WindingRule - Enum value (optional:NonZero)
  #
  # Returns nothing.
  try:

    if objc notin (2..4):
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>:optional enum=WindingRule:optional")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    if objc == 3:
      # Path
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      if pathTable.hasKey($arg2):
        let path = pathTable[$arg2]
        ctx.fill(path)
      else:
        # Enum
        let myEnum = parseEnum[WindingRule]($arg2)
        ctx.fill(myEnum)
    elif objc == 4:
      # Path
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      let path = pathTable[$arg2]
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let myEnum = parseEnum[WindingRule]($arg3)
      ctx.fill(path, myEnum)
    else:
      ctx.fill()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rectangle to the current path.
  # 
  # context     - object
  # coordinates - list x,y
  # size        - list width + height
  #
  # Returns nothing.
  try:
    let x, y, width, height: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    ctx.rect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle that is filled according to the current fillStyle.
  # 
  # context     - object
  # coordinates - list x,y 
  # size        - list width + height
  #
  # Returns nothing.
  try:
    let x, y, width, height: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    ctx.fillRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_roundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rectangle that is filled according to the current fillStyle.
  # 
  # context      - object
  # coordinates  - list x,y
  # size         - list
  # radius       - list (nw, ne, se, sw)
  #
  # Returns nothing.
  try:
    let x, y, width, height, nw, ne, se, sw: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} {nw ne se sw}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 4:
      ERROR_MSG(interp, "wrong # args: 'radius' should be {nw ne se sw}")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], nw.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], ne.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[2], se.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[3], sw.addr) != Tcl.OK: return Tcl.ERROR

    ctx.roundedRect(x, y, width, height, nw, ne, se, sw)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillRoundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rounded rectangle that is filled according to the current fillStyle.
  # 
  # context     - object
  # coordinates - list x,y
  # size        - list width + height
  # radius      - double value or list radius (nw, ne, se, sw) 
  #
  # Returns nothing.
  try:
    let x, y, width, height, radius, nw, ne, se, sw: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} radius|{nw ne se sw}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK: return Tcl.ERROR

    let pos = vec2(x, y)
    let wh  = vec2(width, height)

    if count notin (1..4):
      ERROR_MSG(interp, "wrong # args: 'radius' should be a list {nw ne se sw}")
      return Tcl.ERROR

    if count == 1:
      if Tcl.GetDoubleFromObj(interp, elements[0], radius.addr) != Tcl.OK:
        return Tcl.ERROR

      ctx.fillRoundedRect(rect(pos, wh), radius)

    else:
      if Tcl.GetDoubleFromObj(interp, elements[0], nw.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], ne.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[2], se.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[3], sw.addr) != Tcl.OK: return Tcl.ERROR

      ctx.fillRoundedRect(rect(pos, wh), nw, ne, se, sw)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_strokeRoundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a rounded rectangle that is stroked (outlined) according
  # to the current strokeStyle and other context settings.
  # 
  # context     - object
  # coordinates - list x,y 
  # size        - list width + height
  # radius      - double value or list radius (nw, ne, se, sw)
  #
  # Returns nothing.
  try:
    let x, y, width, height, radius, nw, ne, se, sw: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height} radius|{nw ne se sw}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    let pos = vec2(x, y)
    let wh  = vec2(width, height)

    if count notin (1..4):
      ERROR_MSG(interp, "wrong # args: 'radius' should be a list {nw ne se sw}")
      return Tcl.ERROR

    if count == 1:
      if Tcl.GetDoubleFromObj(interp, elements[0], radius.addr) != Tcl.OK:
        return Tcl.ERROR

      ctx.strokeRoundedRect(rect(pos, wh), radius)

    else:
      if Tcl.GetDoubleFromObj(interp, elements[0], nw.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[1], ne.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[2], se.addr) != Tcl.OK: return Tcl.ERROR
      if Tcl.GetDoubleFromObj(interp, elements[3], sw.addr) != Tcl.OK: return Tcl.ERROR

      ctx.strokeRoundedRect(rect(pos, wh), nw, ne, se, sw)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR


proc pix_ctx_clearRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Erases the pixels in a rectangular area.
  # 
  # context       - object
  # coordinates  - list x,y
  # size         - list width + height
  #
  # Returns nothing.
  try:
    let x, y, width, height: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} {width height}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'size' should be 'width' 'height'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    ctx.clearRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills current style.
  # 
  # context - object
  # value   - paint object or string color
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> color|<paint>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    if paintTable.hasKey($arg2):
      let paint = paintTable[$arg2]
      ctx.fillStyle = paint
    else:
      # Color
      ctx.fillStyle = parseHtmlColor($arg2)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_globalAlpha(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets color alpha.
  # 
  # context - object
  # alpha   - double value
  #
  # Returns nothing.
  try:
    let alpha: cdouble = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> alpha")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.GetDoubleFromObj(interp, objv[2], alpha.addr) != Tcl.OK:
      return Tcl.ERROR

    if alpha < 0.0 or alpha > 1.0:
      ERROR_MSG(interp, "global alpha must be between 0 and 1" )
      return Tcl.ERROR

    ctx.globalAlpha = alpha

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Begins a new sub-path at the point (x, y).
  # 
  # context     - object
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.moveTo(x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_isPointInStroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks whether or not the specified point is inside the area 
  # contained by the stroking of a path.
  # 
  # context     - object
  # coordinates - list x,y
  # path        - object (optional)
  #
  # Returns true, false otherwise.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    var val: int = 0
    let elements : Tcl.PPObj = nil

    if objc notin (3..4):
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} <path>:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if objc == 4:
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let path = pathTable[$arg3]
      if ctx.isPointInStroke(path, x, y): val = 1
    else:
      if ctx.isPointInStroke(x, y): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_isPointInPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks whether or not the specified point is contained in the current path.
  # 
  # context     - object
  # coordinates - list x,y
  # path        - object (optional)
  # WindingRule - Enum value (optional:NonZero)
  #
  # Returns true, false otherwise.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    var val: int = 0
    let elements : Tcl.PPObj = nil

    if objc != 3 and objc != 4 and objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} <path>:optional enum=WindingRule:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if objc == 4:
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      if pathTable.hasKey($arg3):
        let path = pathTable[$arg3]
        if ctx.isPointInPath(path, x, y): val = 1
      else:
        let myEnum = parseEnum[WindingRule]($arg3)
        if ctx.isPointInPath(x, y, windingRule = myEnum): val = 1
    elif objc == 5:
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let path = pathTable[$arg3]
      let arg4 = Tcl.GetStringFromObj(objv[4], nil)
      let myEnum = parseEnum[WindingRule]($arg4)
      if ctx.isPointInPath(path, x, y, windingRule = myEnum): val = 1
    else:
      if ctx.isPointInPath(x, y): val = 1
  
    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a straight line to the current sub-path by connecting 
  # the sub-path's last point to the specified (x, y) coordinates. 
  # 
  # context     - object
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.lineTo(x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_stroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes (outlines) the current or given path with the current strokeStyle.
  # 
  # context - object
  # path    - object (optional)
  #
  # Returns nothing.
  try:

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if objc == 3:
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      let path = pathTable[$arg2]
      ctx.stroke(path)
    else:
      ctx.stroke()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_scale(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a scaling transformation to the context units horizontally and/or vertically.
  # 
  # context     - object
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.scale(x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_writeFile(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Save context to image file.
  # 
  # context  - object
  # filePath - string (\*.png|\*.bmp|\*.jpeg|\*.qoi|\*.ppm)
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filePath")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let file = Tcl.GetStringFromObj(objv[2], nil)

    ctx.image.writeFile($file)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_beginPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Starts a new path by emptying the list of sub-paths.
  # 
  # context - object
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.beginPath()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Attempts to add a straight line from the current point to
  # the start of the current sub-path. If the shape has already been 
  # closed or has only one point, this function does nothing. 
  # 
  # context - object
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.closePath()

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_lineWidth(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets line width for current context.
  # 
  # context - object
  # width   - double value
  #
  # Returns nothing.
  try:
    let width: cdouble = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> width")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.GetDoubleFromObj(interp, objv[2], width.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.lineWidth = width

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_font(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font for current context.
  # 
  # context  - object
  # filepath - string
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filepath")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let ctx = ctxTable[$arg1]

    ctx.font = $arg2

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_fontSize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font size for current context.
  # 
  # context - object
  # size    - double value
  #
  # Returns nothing.
  try:
    let fsize: cdouble = 1

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> size")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    if Tcl.GetDoubleFromObj(interp, objv[2], fsize.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.fontSize = fsize

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_fillText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a text string at the specified coordinates, 
  # filling the string's characters with the current fillStyle.
  # 
  # context     - object
  # text        - string
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> text {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let text = $arg2
    
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.fillText(text, x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillCircle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a circle that is filled according to the current fillStyle
  # 
  # context     - object
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns nothing.
  try:
    let cx, cy, radius: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cy.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], radius.addr) != Tcl.OK: return Tcl.ERROR

    if radius <= 0:
      ERROR_MSG(interp, "The radius must be greater than 0")
      return Tcl.ERROR

    let circle = Circle(pos: vec2(cx, cy), radius: radius)
    ctx.fillCircle(circle)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillEllipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an ellipse that is filled according to the current fillStyle.
  # 
  # context     - object
  # coordinates - list x,y
  # radiusx     - double value
  # radiusy     - double value
  #
  # Returns nothing.
  try:
    let x, y, rx, ry: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} rx ry")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], rx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, objv[4], ry.addr) != Tcl.OK: return Tcl.ERROR

    ctx.fillEllipse(vec2(x, y), rx, ry)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillPolygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws an n-sided regular polygon at (x, y) of size that is filled according to the current fillStyle.
  # 
  # context     - object
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns nothing.
  try:
    let x, y, size: cdouble = 1
    let count, sides: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR
    
    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], size.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, objv[4], sides.addr)   != Tcl.OK: return Tcl.ERROR

    ctx.fillPolygon(vec2(x, y), size, sides)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_polygon(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds an n-sided regular polygon at (x, y) of size to the current path.
  # 
  # context     - object
  # coordinates - list x,y
  # size        - double value
  # sides       - integer value
  #
  # Returns nothing.
  try:
    let x, y, size: cdouble = 0
    let count, sides: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates polygon
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    # Size
    if Tcl.GetDoubleFromObj(interp, objv[3], size.addr) != Tcl.OK: return Tcl.ERROR
      
    # Sides
    if Tcl.GetIntFromObj(interp, objv[4], sides.addr) != Tcl.OK: return Tcl.ERROR

    ctx.polygon(x, y, size, sides)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
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
  try:
    let x, y, size: cdouble = 0
    let count, sides: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {x y} size sides")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates polygon
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    # Size
    if Tcl.GetDoubleFromObj(interp, objv[3], size.addr) != Tcl.OK: return Tcl.ERROR
      
    # Sides
    if Tcl.GetIntFromObj(interp, objv[4], sides.addr) != Tcl.OK: return Tcl.ERROR

    ctx.strokePolygon(vec2(x, y), size, sides)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_strokeCircle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws a circle that is stroked (outlined) according to the current
  # strokeStyle and other context settings.
  # 
  # context     - object
  # coordinates - list cx,cy
  # radius      - double value
  #
  # Returns nothing.
  try:
    let cx, cy, radius: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> {cx cy} radius")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'cx' 'cy'")
      return Tcl.ERROR
    
    if Tcl.GetDoubleFromObj(interp, elements[0], cx.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], cy.addr) != Tcl.OK: return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[3], radius.addr) != Tcl.OK: return Tcl.ERROR

    if radius <= 0:
      ERROR_MSG(interp, "The radius must be greater than 0")
      return Tcl.ERROR

    let circle = Circle(pos: vec2(cx, cy), radius: radius)
    ctx.strokeCircle(circle)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_strokeText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws the outlines of the characters of a text string at the specified coordinates.
  # 
  # context     - object
  # text        - string
  # coordinates - list x,y
  #
  # Returns nothing.
  try:
    let x, y: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> 'text' {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      ERROR_MSG(interp, "wrong # args: 'coordinates' should be 'x' 'y'")
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    ctx.strokeText($arg2, x, y)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
    
proc pix_ctx_textAlign(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets text alignment.
  # 
  # context             - object
  # HorizontalAlignment - Enum value
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> enum=HorizontalAlignment")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let myEnum = parseEnum[HorizontalAlignment]($arg2)

    ctx.textAlign = myEnum

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_get(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets information context.
  # 
  # context - object
  #
  # Returns Tcl dict value.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let st  = split($arg1, '^')
    let img = st[0] & "^img"

    let ctx = ctxTable[$arg1]
    let dictObj            = Tcl.NewDictObj()
    let dictImgObj         = Tcl.NewDictObj()
    let newListMatobj      = Tcl.NewListObj(0, nil)
    let myEnumLineCap      = ctx.lineCap
    let myEnumLineJoin     = ctx.lineJoin
    let myEnumTextAlign    = ctx.textAlign
    let myEnumTextBaseline = ctx.textBaseline

    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("addr", -1), Tcl.NewStringObj(cstring(img), -1))
    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("width", -1), Tcl.NewIntObj(ctx.image.width))
    discard Tcl.DictObjPut(nil, dictImgObj, Tcl.NewStringObj("height", -1), Tcl.NewIntObj(ctx.image.height))

    let mat = ctx.getTransform()

    for x in 0..2:
      for y in 0..2:
        discard Tcl.ListObjAppendElement(interp, newListMatobj, Tcl.NewDoubleObj(mat[x][y]))

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("image", -1), dictImgObj)
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("globalAlpha", -1),  Tcl.NewDoubleObj(ctx.globalAlpha))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineWidth", -1),    Tcl.NewDoubleObj(ctx.lineWidth))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("miterLimit", -1),   Tcl.NewDoubleObj(ctx.miterLimit))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineCap", -1),      Tcl.NewStringObj(cstring($myEnumLineCap), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("lineJoin", -1),     Tcl.NewStringObj(cstring($myEnumLineJoin), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("font", -1),         Tcl.NewStringObj(cstring(ctx.font), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("fontSize", -1),     Tcl.NewDoubleObj(ctx.fontSize))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("transform", -1),    newListMatobj)
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textAlign", -1),    Tcl.NewStringObj(cstring($myEnumTextAlign), -1))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("textBaseline", -1), Tcl.NewStringObj(cstring($myEnumTextBaseline), -1))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_setLineDash(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets line dash for current context.
  # 
  # context - object
  # dashes  - list
  #
  # Returns nothing.
  try:
    let v: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var pattern : seq[float32]

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx> dashes")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR
    
    for i in 0..count-1:
      if Tcl.GetDoubleFromObj(interp, elements[i], v.addr) != Tcl.OK:
        return Tcl.ERROR
      pattern.add(v)

    ctx.setLineDash(pattern)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_getTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets matrix for current context.
  # 
  # context - object
  #
  # Returns list values.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let mat = ctx.getTransform()
    let newListobj = Tcl.NewListObj(0, nil)
        
    for x in 0..2:
      for y in 0..2:
        discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(mat[x][y]))

    Tcl.SetObjResult(interp, newListobj)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_getLineDash(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets line dash for current context.
  # 
  # context - object
  # values - list
  #
  # Returns list values.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    let newSeqListobj = Tcl.NewListObj(0, nil)
    
    for _, value in ctx.getLineDash():
      discard Tcl.ListObjAppendElement(interp, newSeqListobj, Tcl.NewDoubleObj(value))

    Tcl.SetObjResult(interp, newSeqListobj)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_ctx_fillPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # See image fillPath
  if objc notin (4..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>|string color|paint matrix:optional")
    return Tcl.ERROR

  if pix_image_fillpath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # See image strokePath
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> <path>|string color {key value key value ...}")
    return Tcl.ERROR

  if pix_image_strokePath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current context or all contexts if special word `all` is specified.
  # 
  # value - context object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|string")
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    if arg1 == "all":
      ctxTable.clear()
    else:
      ctxTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
