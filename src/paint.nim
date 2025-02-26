# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new paint.
  #
  # PaintKind - Enum value
  #
  # Returns a 'new' paint object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "enum:PaintKind")
    return Tcl.ERROR

  var paint: pixie.Paint

  try:
    let myEnum = parseEnum[PaintKind]($Tcl.GetString(objv[1]))
    paint = newPaint(myEnum)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(paint)
  pixTables.addPaint(p, paint)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

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
  var
    x, y, p, opacity: cdouble
    count, subcount, len: Tcl.Size
    elements, subelements, position, stop: Tcl.PPObj
    matrix3: vmath.Mat3

  if objc != 3:
    let errMsg = "wrong # args: <paint> {image? ?value imageMat? ?value color? ?value blendMode? " &
    "?value gradientHandlePositions? ?value gradientStops? ?value opacity? ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Paint
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPaint(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <paint> object found '" & arg1 & "'")

  let paint = pixTables.getPaint(arg1)

  # Dict
  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp, "wrong # args: 'dict options' should be key value ?key1 ?value1")

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
              if Tcl.ListObjGetElements(interp, subelements[j], len, position) != Tcl.OK:
                return Tcl.ERROR
              if len != 2:
                return pixUtils.errorMSG(interp, "wrong # args: 'positions' should be 'x' 'y'")

              if Tcl.GetDoubleFromObj(interp, position[0], x) != Tcl.OK: return Tcl.ERROR
              if Tcl.GetDoubleFromObj(interp, position[1], y) != Tcl.OK: return Tcl.ERROR

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
                return pixUtils.errorMSG(interp, "wrong # args: 'items' should be 'color' 'position'")

              if Tcl.GetDoubleFromObj(interp, stop[1], p) != Tcl.OK: 
                return Tcl.ERROR

              colorstops.add(ColorStop(color: pixUtils.getColor(stop[0]), position: p))
            paint.gradientStops = colorstops
        else:
          return pixUtils.errorMSG(interp, "wrong # args: Key '" & mkey & "' not supported.")
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a new Paint with the same properties.
  #
  # paint - object
  #
  # Returns a 'new' paint object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>")
    return Tcl.ERROR

  # Paint
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPaint(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <paint> object found '" & arg1 & "'")

  let paint = pixTables.getPaint(arg1)

  let copy = try:
    paint.copy()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(copy)
  pixTables.addPaint(p, copy)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_paint_fillGradient(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills with the Paint gradient.
  #
  # paint - object
  # image - object
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint> <img>")
    return Tcl.ERROR

  # Paint
  let arg1 = $Tcl.GetString(objv[1])
  # Image
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasPaint(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <paint> object found '" & arg1 & "'")

  if not pixTables.hasImage(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg2 & "'")

  let
    paint = pixTables.getPaint(arg1)
    img   = pixTables.getImage(arg2)

  try:
    img.fillGradient(paint)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_paint_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current paint or all paints if special word `all` is specified.
  #
  # value - paint object or string
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<paint>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:
    # Paint
    if arg1 == "all":
      paintTable.clear()
    else:
      paintTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK