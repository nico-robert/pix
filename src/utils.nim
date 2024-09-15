# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc ERROR_MSG(interp: Tcl.PInterp, errormsg: string): void =
  # Sets the interpreter result to the error message.
  # 
  # interp   - The Tcl interpreter.
  # errormsg - The error message.
  # 
  # Returns None.
  Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))

proc isColorSimple(obj: Tcl.PObj, colorSimple: var Color): bool =
  # Checks if the obj is a color.
  # 
  # obj        - The object to check.
  # colorSimple - The color to fill if the object is a color.
  # 
  # Returns true if the object is a color, false otherwise.
  var c: cdouble = 0
  var count: int = 0
  var elements: Tcl.PPObj
  var color : seq[float32]

  if Tcl.ListObjGetElements(nil, obj, count, elements) != Tcl.OK:
    return false

  if count notin (3..4):
    return false

  for i in 0..count-1:
    if Tcl.GetDoubleFromObj(nil, elements[i], c) != Tcl.OK:
      return false
    if c < 0 or c > 1:
      return false
    color.add(c)

  # Fill the colorSimple with the color.
  if count == 3:
    colorSimple = color(color[0], color[1], color[2])
  else:
    colorSimple = color(color[0], color[1], color[2], color[3])

  return true

proc isColorRgbx(color: string, colorRgbx: var ColorRGBX): bool =
  # Checks if the color is a color in the rgbx format.
  # 
  # color     - The color to check.
  # colorRgbx - The color to fill if the color is in the rgbx format.
  # 
  # Returns true if the color is in the rgbx format, false otherwise.

  if (color.len < 4) or (color[0..3] != "rgbx"):
    return false

  let st = split(color[5..^2], ",")

  if st.len != 4:
    return false

  # Fill the colorRgbx with the color.
  colorRgbx = rgbx(
    parseInt(strutils.strip(st[0])).uint8,
    parseInt(strutils.strip(st[1])).uint8,
    parseInt(strutils.strip(st[2])).uint8,
    parseInt(strutils.strip(st[3])).uint8
  )

  return true

proc matrix3x3(interp: Tcl.PInterp, obj: Tcl.PObj, matrix3: var vmath.Mat3): cint =
# Converts a Tcl list to a matrix 3x3.
# 
# interp  - The Tcl interpreter.
# obj     - The Tcl object.
# matrix3 - The matrix to fill with the values of the Tcl object.
# 
# Returns Tcl.OK if successful, Tcl.ERROR otherwise.
  try:
    var count: int = 0
    var elements: Tcl.PPObj
    var value : seq[cdouble]
    
    if Tcl.ListObjGetElements(interp, obj, count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 9:
      ERROR_MSG(interp, "wrong # args: 'matrix' should be 'Matrix 3x3'")
      return Tcl.ERROR

    value.setlen(count)
    
    for i in 0..count-1:
      if Tcl.GetDoubleFromObj(interp, elements[i], value[i]) != Tcl.OK:
        return Tcl.ERROR

    # Fill the matrix3 with the values of the Tcl object.
    matrix3 = vmath.mat3(
      value[0], value[1], value[2],
      value[3], value[4], value[5],
      value[6], value[7], value[8]
    )

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
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
    let arg1 = Tcl.GetString(objv[1])
    let color = parseHtmlColor($arg1).rgba
    let newobj = Tcl.NewListObj(0, nil)
    
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.r.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.g.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.b.int))
    discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.a.int))

    Tcl.SetObjResult(interp, newobj)

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_pathObjToString(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse path.
  # 
  # path  - path object
  #
  # Returns the parsed path to SVG style path.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<path>")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let parse = pathTable[$arg1]

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring($parse), -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR

proc pix_svgStyleToPathObj(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Transforms a SVG style path to a path object.
  # 
  # path  - string SVG style
  #
  # Returns a 'new' path object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "string")
      return Tcl.ERROR

    # Path
    let arg1 = Tcl.GetString(objv[1])
    let parse = parsePath($arg1)

    let myPtr = cast[pointer](parse)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^path").toLowerAscii

    pathTable[p] = parse

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
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

    let arg1  = Tcl.GetString(objv[1])
    let img   = if ctxTable.hasKey($arg1): ctxTable[$arg1].image else: imgTable[$arg1]
    let data  = encodeImage(img, FileFormat.PngFormat)
    let b64   = encode(data)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(b64.cstring, -1))

    return Tcl.OK
  except Exception as e:
    ERROR_MSG(interp, "pix(error): " & e.msg)
    return Tcl.ERROR
  