# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_context(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var img: Image

    if objc notin (2..3):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '{width height} color:optional' or <image>"
      Tcl.SetResult(interp, mess.cstring , nil)
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
          Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
          return Tcl.ERROR
          
        if Tcl.GetIntFromObj(interp, elements[0], width.addr) != Tcl.OK:
          return Tcl.ERROR
        
        if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK:
          return Tcl.ERROR
        
        img = newImage(width, height)
    else:
      # Size
      if Tcl.ListObjGetElements(interp, objv[1], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR
      
      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
        return Tcl.ERROR
        
      if Tcl.GetIntFromObj(interp, elements[0], width.addr) != Tcl.OK:
        return Tcl.ERROR
      
      if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK:
        return Tcl.ERROR
      
      # Color RGBA check
      let arg2 = Tcl.GetStringFromObj(objv[2], nil)
      let color = parseHtmlColor($arg2).rgba

      img = newImage(width, height)
      img.fill(color)

    let ctx = newContext(img)
    let c = cast[pointer](ctx)
    let hex = "0x" & cast[uint64](c).toHex
    let p = (hex & "^ctx").toLowerAscii
    let i = (hex & "^img").toLowerAscii
    ctxTable[p] = ctx
    imgTable[i] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_strokeStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> color'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    ctx.strokeStyle = parseHtmlColor($arg2).rgba

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_save(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.save()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_textBaseline(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> enum=BaselineAlignment"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    let baseline = parseEnum[BaselineAlignment]($arg2)

    ctx.textBaseline = baseline

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR


proc pix_ctx_restore(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.restore()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_saveLayer(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.saveLayer()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_strokeSegment(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, x1, y1: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {x1 y1}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates segment
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
      Tcl.SetResult(interp, "wrong # args: argument should be 'x1' 'y1'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x1.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y1.addr) != Tcl.OK:
      return Tcl.ERROR

    let start = vec2(x, y)
    let stop  = vec2(x1, y1)
    ctx.strokeSegment(segment(start, stop))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_strokeRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], width.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], height.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.strokeRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_quadraticCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, cpx, cpy: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {cpx cpy} {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'cpx' 'cpy'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cpx.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], cpy.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.quadraticCurveTo(cpx, cpy, x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR


proc pix_ctx_arc(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, r, a0, a1: cdouble = -1
    let count, clockcw: cint = 0
    var ccw: bool = false
    let elements : Tcl.PPObj = nil

    if objc notin (6..7):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} r a0 a1 ccw=false:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    if Tcl.GetDoubleFromObj(interp, objv[3], r.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, objv[4], a0.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, objv[5], a1.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if objc == 7:
      if Tcl.GetBooleanFromObj(interp, objv[6], clockcw.addr) != Tcl.OK:
        return Tcl.ERROR
      if clockcw.uint8 == 1:
        ccw = true

    ctx.arc(x, y, r, a0, a1, ccw)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_arcTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x1, y1, x2, y2, radius: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    

    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x1 y1} {x2 y2} radius"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
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
      
    if Tcl.GetDoubleFromObj(interp, objv[4], radius.addr) != Tcl.OK:
      return Tcl.ERROR
      

    ctx.arcTo(x1, y1, x2, y2, radius)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_bezierCurveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let cp1x, cp1y, cp2x, cp2y, x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    

    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {cp1x cp1y} {cp2x cp2y} {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'cp1x' 'cp1y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cp1x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], cp1y.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'cp2x' 'cp2y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], cp2x.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[1], cp2y.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR
      
    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR
      

    ctx.bezierCurveTo(vec2(cp1x, cp1y), vec2(cp2x, cp2y), vec2(x, y))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_circle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let cx, cy, r: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {cx cy} r"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    ctx.circle(cx, cy, r)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_clip(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc notin (2..4):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> <path>:optional enum=WindingRule:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_measureText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'text'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Text
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let text = $arg2

    let metrics = ctx.measureText(text)

    let newListobj = Tcl.NewListObj(0, nil)
    discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewStringObj("width", -1))
    discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(metrics.width))

    Tcl.SetObjResult(interp, newListobj);

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_resetTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.resetTransform()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_drawImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4 and objc != 5 and objc != 7:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & """
      <ctx> <img> {dx dy} or
      <ctx> <img> {dx dy} {dWidth dHeight} or
      <ctx> <img> {sx sy} {sWidth sHeight} {dx dy} {dWidth dHeight}
      """
      Tcl.SetResult(interp, mess.cstring , nil)
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
        Tcl.SetResult(interp, "wrong # args: argument should be 'dx' 'dy'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK:
        return Tcl.ERROR

      # Size
      if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'dWidth' 'dHeight'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dWidth.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], dHeight.addr) != Tcl.OK:
        return Tcl.ERROR

      ctx.drawImage(img, dx, dy, dWidth, dHeight)

    elif objc == 7:
      # Source
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'sx' 'sy'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], sx.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], sy.addr) != Tcl.OK:
        return Tcl.ERROR

      # Source Size
      if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'sWidth' 'sHeight'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], sWidth.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], sHeight.addr) != Tcl.OK:
        return Tcl.ERROR

      # Destination
      if Tcl.ListObjGetElements(interp, objv[5], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'dx' 'dy'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK:
        return Tcl.ERROR

      # Destination Size
      if Tcl.ListObjGetElements(interp, objv[6], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'dWidth' 'dHeight'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dWidth.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], dHeight.addr) != Tcl.OK:
        return Tcl.ERROR

      ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)

    else:
      # Destination
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR

      if count != 2:
        Tcl.SetResult(interp, "wrong # args: argument should be 'dx' 'dy'", nil)
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[0], dx.addr) != Tcl.OK:
        return Tcl.ERROR

      if Tcl.GetDoubleFromObj(interp, elements[1], dy.addr) != Tcl.OK:
        return Tcl.ERROR

      ctx.drawImage(img, dx, dy)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_ellipse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, rx, ry: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} rx ry"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
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
    
    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[3], rx.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, objv[4], ry.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.ellipse(x, y, rx, ry)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_setTransform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> matrix3x3"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Matrix 3x3 check
    if matrix3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    ctx.setTransform(matrix3)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_transform(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var matrix3: vmath.Mat3

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> matrix3x3"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    # Matrix 3x3 check
    if matrix3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR

    ctx.transform(matrix3)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_rotate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let angle: cdouble = -1

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> angle"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_translate(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Context
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    ctx.translate(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_lineJoin(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> enum=LineJoin"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc notin (2..4):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> <path>:optional enum=WindingRule:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_rect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    ctx.rect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_fillRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    ctx.fillRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_fillRoundedRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height, radius: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 5:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {width height} radius"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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
      
    if Tcl.GetDoubleFromObj(interp, objv[4], radius.addr) != Tcl.OK:
      return Tcl.ERROR

    let pos = vec2(x, y)
    let wh  = vec2(width, height)
    let r   = radius

    ctx.fillRoundedRect(rect(pos, wh), r)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR


proc pix_ctx_clearRect(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, width, height: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

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

    ctx.clearRect(x, y, width, height)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_fillStyle(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> color|<paint>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    if paintTable.hasKey($arg2):
      let paint = paintTable[$arg2]
      ctx.fillStyle = paint
    else:
      # Color RGBA check
      let color = parseHtmlColor($arg2).rgba
      ctx.fillStyle = color

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_globalAlpha(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let alpha: cdouble = -1

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> color|<paint>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.GetDoubleFromObj(interp, objv[2], alpha.addr) != Tcl.OK:
      return Tcl.ERROR

    if alpha < 0 or alpha > 1:
      Tcl.SetResult(interp, "global alpha must be between 0 and 1" , nil)
      return Tcl.ERROR

    ctx.globalAlpha = alpha

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_moveTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.moveTo(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_isPointInStroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    var val: int = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    if ctx.isPointInStroke(x, y): val = 1
  
    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_isPointInPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    var val: int = 0
    let elements : Tcl.PPObj = nil

    if objc notin (3..4):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y} enum=WindingRule:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    if objc == 4:
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let myEnum = parseEnum[WindingRule]($arg3)
      if ctx.isPointInPath(x, y, windingRule = myEnum): val = 1
    else:
      if ctx.isPointInPath(x, y): val = 1
  
    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_lineTo(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.lineTo(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_stroke(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.stroke()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_scale(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.scale(x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_writeFile(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'file'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let file = Tcl.GetStringFromObj(objv[2], nil)

    ctx.image.writeFile($file)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_beginPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.beginPath()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_closePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    ctx.closePath()

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_resize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let width, height: cint = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " 'ctx|img' {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let str = $arg1

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], width.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK:
      return Tcl.ERROR

    var p: string = ""

    if str[^3..^1] == "ctx":
      let ctx = ctxTable[$str]
      let newimg = ctx.image.resize(width, height)
      let i = cast[pointer](newimg)
      p = ("0x" & cast[uint64](i).toHex & "^img").toLowerAscii
      imgTable[p] = newimg
      Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))
    else:
      let img = imgTable[$str]
      let newimg = img.resize(width, height)
      let i = cast[pointer](newimg)
      p = ("0x" & cast[uint64](i).toHex & "^img").toLowerAscii
      imgTable[p] = newimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_lineWidth(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let width: cdouble = -1

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'width'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    if Tcl.GetDoubleFromObj(interp, objv[2], width.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.lineWidth = width

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_img_get(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    let st  = split($arg1, '^')
    let img = st[0] & "^img"
    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(img), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_font(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'name'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let ctx = ctxTable[$arg1]

    ctx.font = $arg2

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_fontSize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let fsize: cdouble = 1

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'size'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    if Tcl.GetDoubleFromObj(interp, objv[2], fsize.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.fontSize = fsize

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_fillText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'text' {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.fillText($arg2, x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_strokeText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y: cdouble = 1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'text' {x y}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetDoubleFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    ctx.strokeText($arg2, x, y)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_ctx_textAlign(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'enum=HorizontalAlignment'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]
    
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let myEnum = parseEnum[HorizontalAlignment]($arg2)

    ctx.textAlign = myEnum

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_getSize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let ctx = ctxTable[$arg1]

    let newobj = Tcl.NewListObj(0, nil)
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewStringObj("width", -1))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(ctx.image.width))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewStringObj("height", -1))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(ctx.image.height))

    Tcl.SetObjResult(interp, newobj);

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_setLineDash(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let v: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var pattern : seq[float32]

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <ctx> 'list'"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_ctx_fillPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  if objc notin (4..5):
    let cmd = Tcl.GetStringFromObj(objv[0], nil)
    let mess = "wrong # args: " & $cmd & " <ctx> <path|string> color|paint matrix:optional"
    Tcl.SetResult(interp, mess.cstring , nil)
    return Tcl.ERROR

  if pix_image_fillpath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR

proc pix_ctx_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  if objc != 5:
    let cmd = Tcl.GetStringFromObj(objv[0], nil)
    let mess = "wrong # args: " & $cmd & " <ctx> 'pathstring' color {key value key value ...}"
    Tcl.SetResult(interp, mess.cstring , nil)
    return Tcl.ERROR

  if pix_image_strokePath(clientData, interp, objc, objv) != Tcl.OK:
    return Tcl.ERROR
