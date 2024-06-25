# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new paint.
  # 
  # PaintKind - Enum value
  #
  # Returns a 'new' paint object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "enum:PaintKind")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let myEnum = parseEnum[PaintKind]($arg1)

    let paint = newPaint(myEnum)
    let myPtr = cast[pointer](paint)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^paint").toLowerAscii

    paintTable[p] = paint

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
    
proc pix_paint_configure(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Configure paint object parameters.
  # 
  # paint - object
  # args  - dict options described below:
  #   image                   - object
  #   imageMat                - list matrix
  #   color                   - string color
  #   blendMode               - Enum value
  #   opacity                 - double value
  #   gradientHandlePositions - list positions
  #   gradientStops           - list color + positions
  # 
  # Returns nothing.
  try:
    let count, subcount, len: cint = 0
    let x, y, p, opacity: cdouble = 0
    let elements, subelements, position, stop: Tcl.PPObj = nil
    var matrix3: vmath.Mat3
    var cseqColorP: Color

    if objc != 3:
      let msg = """
       <paint> {image? ?value imageMat? ?value color? ?value blendMode? ?value gradientHandlePositions? ?value gradientStops? ?value opacity? ?value}"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR
      
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]

    # Dict
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      Tcl.SetResult(interp, "wrong # args: 'dict options' should be key value ?key1 ?value1", nil)
      return Tcl.ERROR
      
    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "color":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.color = parseHtmlColor($value).color
        of "opacity":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], opacity.addr) != Tcl.OK:
            return Tcl.ERROR
          paint.opacity = opacity
        of "blendMode":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.blendMode = parseEnum[BlendMode]($value)
        of "image":
          let value = Tcl.GetStringFromObj(elements[i+1], nil)
          paint.image = imgTable[$value]
        of "imageMat":
          # Matrix 3x3 check
          if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
            return Tcl.ERROR
          paint.imageMat = matrix3
        of "gradientHandlePositions":
          # Positions
          if Tcl.ListObjGetElements(interp, elements[i+1], subcount.addr, subelements.addr) != Tcl.OK:
            return Tcl.ERROR
          if subcount != 0:
            var positions = newSeq[vmath.Vec2]()
            for j in 0..subcount-1:
              if Tcl.ListObjGetElements(interp, subelements[j], len.addr, position.addr) != Tcl.OK:
                return Tcl.ERROR
              if len != 2:
                Tcl.SetResult(interp, "wrong # args: 'positions' should be 'x' 'y'", nil)
                return Tcl.ERROR

              if Tcl.GetDoubleFromObj(interp, position[0], x.addr) != Tcl.OK: return Tcl.ERROR
              if Tcl.GetDoubleFromObj(interp, position[1], y.addr) != Tcl.OK: return Tcl.ERROR

              positions.add(vec2(x, y))
            paint.gradientHandlePositions = positions
        of "gradientStops":
          if Tcl.ListObjGetElements(interp, elements[i+1], subcount.addr, subelements.addr) != Tcl.OK:
            return Tcl.ERROR
          if subcount != 0:
            var colorstops = newSeq[ColorStop]()
            for j in 0..subcount-1:
              if Tcl.ListObjGetElements(interp, subelements[j], len.addr, stop.addr) != Tcl.OK:
                return Tcl.ERROR
              if len != 2:
                Tcl.SetResult(interp, "wrong # args: 'items' should be 'color' 'position'", nil)
                return Tcl.ERROR
              if isColorSimple(stop[0], cseqColorP) == false:
                let arg2 = Tcl.GetStringFromObj(stop[0], nil)
                cseqColorP = parseHtmlColor($arg2)

              if Tcl.GetDoubleFromObj(interp, stop[1], p.addr) != Tcl.OK:
                return Tcl.ERROR
              
              colorstops.add(ColorStop(color: cseqColorP, position: p))
            paint.gradientStops = colorstops
        else:
          Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
          return Tcl.ERROR
      inc(i, 2)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR 

proc pix_paint_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a new Paint with the same properties.
  # 
  # paint - object
  #
  # Returns a 'new' paint object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<paint>")
      return Tcl.ERROR
    
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]
    
    let copy = paint.copy()

    let myPtr = cast[pointer](copy)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^paint").toLowerAscii

    paintTable[p] = copy

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_paint_fillGradient(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills with the Paint gradient.
  # 
  # paint - object
  # image - object
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<paint> <img>")
      return Tcl.ERROR
    
    # Paint
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let paint = paintTable[$arg1]

    # Image
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let img = imgTable[$arg2]
    
    img.fillGradient(paint)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_paint_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current paint or all paints if special word `all` is specified.
  # 
  # value - paint object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<paint>|string")
      return Tcl.ERROR
    
    # Font
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    if arg1 == "all":
      paintTable.clear()
    else:
      paintTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

