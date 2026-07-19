# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_paint(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates and returns a new paint object.
  #
  # paintKind - Enum value (PaintKind)
  #
  # Returns: A *new* handle [paint] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "enum:PaintKind")
    return Tcl.ERROR
  
  let ptable = cast[PixTable](clientData)
  var paint: pixie.Paint

  try:
    paint = newPaint(parseEnum[PaintKind]($objv[1]))
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let paintKey = toHexPtr(paint)
  ptable.add(paintKey, paint)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(paintKey.cstring, -1))

  return Tcl.OK

proc pix_paint_configure(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Configures the parameters of a paint object.
  #
  # paint   - [paint] object handle
  # options - A Tcl list of key-value pairs (see supported options below).
  #
  # #Begintable
  #  **image**                   : [img] object handle.
  #  **imageMat**                : 3x3 transformation matrix (list of 9 numbers).
  #  **color**                   : Color string.
  #  **blendMode**               : Enum value (BlendMode).
  #  **opacity**                 : Double value (0 to 1).
  #  **gradientHandlePositions** : List coordinates {{x y} {x y}}.
  #  **gradientStops**           : List of color stops {{color offset} {color1 offset1}}.
  # #EndTable
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint> {?image value color value ...?}")
    return Tcl.ERROR

  var
    x, y: float32
    count, subcount, len: Tcl.Size
    elements, subelements, stop: Tcl.PPObj

  # Paint
  let ptable = cast[PixTable](clientData)
  let paint = ptable.load(interp, objv[1], pixie.Paint)
  if paint.isNil: return Tcl.ERROR

  # Dict
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp,
      "wrong # args: 'options' should be a list of {?key value key1 value1 ...?}"
    )

  try:
    for i in countup(0, count - 1, 2):
      let
        mkey = $elements[i]
        value = elements[i+1]
      case mkey:
        of "color":
          paint.color = value.getColor()
        of "opacity":
          paint.opacity = getFloat(value, true)
        of "blendMode":
          paint.blendMode = parseEnum[BlendMode]($value)
        of "image":
          paint.image = ptable.get($value, pixie.Image)
        of "imageMat":
          paint.imageMat = getMtx(value, true)
        of "gradientHandlePositions":
          # Positions
          if Tcl.ListObjGetElements(interp, value, subcount, subelements) != Tcl.OK:
            return Tcl.ERROR
          if subcount != 0:
            var positions = newSeq[vmath.Vec2]()
            for j in 0..subcount-1:
              if getListFloat(interp, subelements[j], x, y, 
                "wrong # args: 'gradient positions' should be {x y}") != Tcl.OK:
                return Tcl.ERROR
              positions.add(vec2(x, y))
            paint.gradientHandlePositions = positions
        of "gradientStops":
          if Tcl.ListObjGetElements(interp, value, subcount, subelements) != Tcl.OK:
            return Tcl.ERROR
          if subcount != 0:
            var colorstops = newSeq[ColorStop]()
            for j in 0..subcount-1:
              if Tcl.ListObjGetElements(interp, subelements[j], len, stop) != Tcl.OK:
                return Tcl.ERROR
              if len != 2:
                return pixUtils.errorMSG(interp,
                  "wrong # args: 'items' should be 'color' 'position'"
                )

              colorstops.add(ColorStop(
                  color: stop[0].getColor(), 
                  position: getFloat(stop[1], true)
                )
              )
            paint.gradientStops = colorstops
        else:
          return pixUtils.errorMSG(interp,
            "wrong # args: Key '" & mkey & "' not supported."
          )
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_copy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a copy of the specified paint object.
  #
  # paint - [paint] object handle
  #
  # Returns: A *new* copied type [paint] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>")
    return Tcl.ERROR

  # Paint
  let ptable = cast[PixTable](clientData)
  let paint = ptable.load(interp, objv[1], pixie.Paint)
  if paint.isNil: return Tcl.ERROR

  let copy = paint.copy()

  let paintKey = toHexPtr(copy)
  ptable.add(paintKey, copy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(paintKey.cstring, -1))

  return Tcl.OK

proc pix_paint_fillGradient(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills an entire image using the gradient settings of the paint object.
  #
  # paint - [paint] object handle
  # image - [img] object handle
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint> <img>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Paint
  let paint = ptable.load(interp, objv[1], pixie.Paint)
  if paint.isNil: return Tcl.ERROR

  # Image
  let img = ptable.load(interp, objv[2], pixie.Image)
  if img.isNil: return Tcl.ERROR

  try:
    img.fillGradient(paint)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy the [paint] or all paints if special word `all` is specified.
  #
  # value - [paint] object or string.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $objv[1]

  # Paint
  if key == "all":
    ptable.clear(pixie.Paint)
  else:
    ptable.delKey(key, pixie.Paint)

  return Tcl.OK