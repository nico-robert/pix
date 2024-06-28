# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc isColorSimple(obj: Tcl.PObj, colorSimple: var Color): bool =

  let c: cdouble = 0
  let count: cint = 0
  let elements : Tcl.PPObj = nil
  var color : seq[float32]

  if Tcl.ListObjGetElements(nil, obj, count.addr, elements.addr) != Tcl.OK:
    return false

  if count notin (3..4):
    return false

  for i in 0..count-1:
    if Tcl.GetDoubleFromObj(nil, elements[i], c.addr) != Tcl.OK:
      return false
    if c < 0 or c > 1:
      return false
    color.add(c)

  if count == 3:
    colorSimple = color(color[0], color[1], color[2])
  else:
    colorSimple = color(color[0], color[1], color[2], color[3])

  return true

proc isColorRgbx(color: string, colorRgbx: var ColorRGBX): bool =

  var newC: string

  if (color.len < 4) or color[0..3] != "rgbx":
    return false

  newC = color.replace("rgbx(", "")
  newC = newC.replace(")", "")
  let st = split($newC, ",")

  if st.len != 4:
    return false

  colorRgbx = rgbx(
    parseInt(strutils.strip(st[0])).uint8,
    parseInt(strutils.strip(st[1])).uint8,
    parseInt(strutils.strip(st[2])).uint8,
    parseInt(strutils.strip(st[3])).uint8
  )

  return true

proc matrix3x3(interp: Tcl.PInterp, obj: Tcl.PObj, matrix3: var vmath.Mat3): cint =

  try:
    let v: cdouble = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var value : seq[float32]
    
    if Tcl.ListObjGetElements(interp, obj, count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 9:
      Tcl.SetResult(interp, "wrong # args: 'matrix' should be 'Matrix 3x3'", nil)
      return Tcl.ERROR
    
    for i in 0..count-1:
      if Tcl.GetDoubleFromObj(interp, elements[i], v.addr) != Tcl.OK:
        return Tcl.ERROR
      value.add(v)

    matrix3 = vmath.mat3(
      value[0], value[1], value[2],
      value[3], value[4], value[5],
      value[6], value[7], value[8]
    )

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
  
proc pix_colorHTMLtoRGBA(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts an HTML color to an RGBA.
  # 
  # HTMLcolor  - string
  #
  # Returns a tcl list.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "'#xxxxxx'")
      return Tcl.ERROR

    # Parse
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let color = parseHtmlColor($arg1).rgba
    let newobj = Tcl.NewListObj(0, nil)
    
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.r.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.g.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.b.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.a.int))

    Tcl.SetObjResult(interp, newobj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_parsePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse path.
  # 
  # path  - string
  #
  # Returns the parsed path.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "string")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    let parse = parsePath($arg1)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring($parse), -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_toB64(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Convert an image to base64 format.
  # 
  # object - image or context object
  #
  # Returns string.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    if ctxTable.hasKey($arg1):
      let ctx = ctxTable[$arg1]
      let b64 = encode(encodeImage(ctx.image, FileFormat.PngFormat))
      Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(b64), -1))
    else:
      let image = imgTable[$arg1]
      let b64 = encode(encodeImage(image, FileFormat.PngFormat))
      Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(b64), -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
