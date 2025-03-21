# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new paint.
  #
  # paintKind - Enum value
  #
  # Returns: A *new* [paint] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "enum:PaintKind")
    return Tcl.ERROR

  var paint: pixie.Paint

  try:
    let myEnum = parseEnum[PaintKind]($Tcl.GetString(objv[1]))
    paint = newPaint(myEnum)
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(paint)
  pixTables.addPaint(p, paint)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_paint_configure(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Configure paint object parameters.
  #
  # paint   - [paint]
  # options - A Tcl dict (options described below)
  #
  # #Begintable
  #  **image**                   : A object [img].
  #  **imageMat**                : A list matrix.
  #  **color**                   : A string [color].
  #  **blendMode**               : A Enum value.
  #  **opacity**                 : A double value.
  #  **gradientHandlePositions** : A list positions {{x y} {x y}}.
  #  **gradientStops**           : A list [color] + color position (double value).
  # #EndTable
  #
  # Returns: Nothing.
  if objc != 3:
    let errMsg = "wrong # args: <paint> {image? ?value imageMat? ?value color? ?value blendMode? " &
    "?value gradientHandlePositions? ?value gradientStops? ?value opacity? ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  var
    x, y, p, opacity: cdouble
    count, subcount, len: Tcl.Size
    elements, subelements, stop: Tcl.PPObj
    matrix3: vmath.Mat3

  # Paint
  let paint = pixTables.loadPaint(interp, objv[1])
  if paint.isNil: return Tcl.ERROR

  # Dict
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp,
    "wrong # args: 'dict options' should be key value ?key1 ?value1"
    )

  try:
    for i in countup(0, count - 1, 2):
      let
        mkey = $Tcl.GetString(elements[i])
        value = elements[i+1]
      case mkey:
        of "color":
          paint.color = pixUtils.getColor(value)
        of "opacity":
          if Tcl.GetDoubleFromObj(interp, value, opacity) != Tcl.OK: return Tcl.ERROR
          paint.opacity = opacity
        of "blendMode":
          paint.blendMode = parseEnum[BlendMode]($Tcl.GetString(value))
        of "image":
          paint.image = pixTables.getImage($Tcl.GetString(value))
        of "imageMat":
          # Matrix 3x3 check
          if pixUtils.matrix3x3(interp, value, matrix3) != Tcl.OK: return Tcl.ERROR
          paint.imageMat = matrix3
        of "gradientHandlePositions":
          # Positions
          if Tcl.ListObjGetElements(interp, value, subcount, subelements) != Tcl.OK:
            return Tcl.ERROR
          if subcount != 0:
            var positions = newSeq[vmath.Vec2]()
            for j in 0..subcount-1:
              if pixParses.getListDouble(interp, subelements[j], x, y, 
                "wrong # args: 'gradient positions' should be 'x' 'y'") != Tcl.OK:
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

              if Tcl.GetDoubleFromObj(interp, stop[1], p) != Tcl.OK: 
                return Tcl.ERROR

              colorstops.add(ColorStop(color: pixUtils.getColor(stop[0]), position: p))
            paint.gradientStops = colorstops
        else:
          return pixUtils.errorMSG(interp,
          "wrong # args: Key '" & mkey & "' not supported."
          )
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a new Paint with the same properties.
  #
  # paint - [paint::new]
  #
  # Returns: A *new* [paint] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>")
    return Tcl.ERROR

  # Paint
  let paint = pixTables.loadPaint(interp, objv[1])
  if paint.isNil: return Tcl.ERROR

  let copy = paint.copy()

  let p = toHexPtr(copy)
  pixTables.addPaint(p, copy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_paint_fillGradient(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills with the Paint gradient.
  #
  # paint - [paint::new]
  # image - [img::new]
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint> <img>")
    return Tcl.ERROR

  # Paint
  let paint = pixTables.loadPaint(interp, objv[1])
  if paint.isNil: return Tcl.ERROR

  # Image
  let img = pixTables.loadImage(interp, objv[2])
  if img.isNil: return Tcl.ERROR

  try:
    img.fillGradient(paint)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current [paint] or all paints if special word `all` is specified.
  #
  # value - [paint::new] object or string.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>|string('all')")
    return Tcl.ERROR

  let key = $Tcl.GetString(objv[1])
  # Paint
  if key == "all":
    pixTables.clearPaint()
  else:
    pixTables.delKeyPaint(key)

  return Tcl.OK