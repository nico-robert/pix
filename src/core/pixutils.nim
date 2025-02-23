# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import std/[strutils, tables, base64]
import ../core/pixtables as pixTables

from ../bindings/tcl/binding as Tcl import nil
    
proc ERROR_MSG*(interp: Tcl.PInterp, errormsg: string): cint =
  # Sets the interpreter result to the error message.
  # 
  # interp   - The Tcl interpreter.
  # errormsg - The error message.
  # 
  # Returns Tcl.ERROR on failure.
  Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))

  return Tcl.ERROR

template toHexPtr*[T](obj: T): string =
  # Converts an object to a hexadecimal string.
  # 
  # obj - The object to convert.
  # 
  # Returns a hexadecimal string.

  let
    myPtr  = cast[pointer](obj)
    hexstr = cast[uint64](myPtr).toHex()

  # Inline strip leading zeros
  let hex = block:
    var i = 0
    while i < hexStr.len and hexStr[i] == '0': inc i
    if i >= hexStr.len: "0"
    else: hexStr[i..^1]

  let typeName = 
    when T is pixie.Context     : "ctx"
    elif T is pixie.Image       : "img"
    elif T is pixie.Font        : "font"
    elif T is pixie.Span        : "span"
    elif T is pixie.Paint       : "paint"
    elif T is pixie.TypeFace    : "TFace"
    elif T is pixie.Path        : "path"
    elif T is Svg               : "svg"
    elif T is pixie.Arrangement : "arr"
    else: {.error: "pix type not supported : " & $T .}
  ("0x" & hex & "^" & typeName).toLowerAscii

proc isColorSimple*(obj: Tcl.PObj, colorSimple: var Color): bool =
  # Checks if the obj is a color.
  # 
  # obj        - The object to check.
  # colorSimple - The color to fill if the object is a color.
  # 
  # Returns true if the object is a color, false otherwise.
  var
    c: cdouble = 0
    count: Tcl.Size
    elements: Tcl.PPObj
    color : seq[float32]

  if Tcl.ListObjGetElements(nil, obj, count, elements) != Tcl.OK:
    return false

  if count notin (3..4):
    return false

  for i in 0..count-1:
    if Tcl.GetDoubleFromObj(nil, elements[i], c) != Tcl.OK: return false
    if (c < 0.0) or (c > 1.0): return false
    color.add(c)

  # Fill the colorSimple with the color.
  if count == 3:
    colorSimple = color(color[0], color[1], color[2])
  else:
    colorSimple = color(color[0], color[1], color[2], color[3])

  return true

proc isColorRgbx*(color: string, colorRgbx: var ColorRGBX): bool =
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

proc matrix3x3*(interp: Tcl.PInterp, obj: Tcl.PObj, matrix3: var vmath.Mat3): cint =
# Converts a Tcl list to a matrix 3x3.
# 
# interp  - The Tcl interpreter.
# obj     - The Tcl object.
# matrix3 - The matrix to fill with the values of the Tcl object.
# 
# Returns Tcl.OK if successful, Tcl.ERROR otherwise.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    value : seq[cdouble]

  if Tcl.ListObjGetElements(interp, obj, count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 9:
    return ERROR_MSG(interp, "wrong # args: 'matrix' should be 'Matrix 3x3'")

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
  
proc colorHTMLtoRGBA*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Converts an HTML color to an RGBA.
  # 
  # HTMLcolor  - string
  #
  # Returns a tcl list.
  let newobj = Tcl.NewListObj(0, nil)
  var color: ColorRGBA

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "'#xxxxxx'")
    return Tcl.ERROR
    
  # Parse
  let arg1 = $Tcl.GetString(objv[1])

  try:
    color = parseHtmlColor(arg1).rgba
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.r.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.g.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.b.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.a.int))

  Tcl.SetObjResult(interp, newobj)

  return Tcl.OK

proc pathObjToString*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse path.
  # 
  # path  - path object
  #
  # Returns the parsed path to SVG style path.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return ERROR_MSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  try:
    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring($path), -1))
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc svgStyleToPathObj*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Transforms a SVG style path to a path object.
  # 
  # path  - string SVG style
  #
  # Returns a 'new' path object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "string")
    return Tcl.ERROR
    
  # Path
  let arg1 = $Tcl.GetString(objv[1])
  var parse: pixie.Path

  try:
    parse = parsePath(arg1)
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(parse)
  pixTables.addPath(p, parse)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))
    
  return Tcl.OK

proc toB64*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Convert an image to base64 format.
  # 
  # object - image or context object
  #
  # Returns string.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
    return Tcl.ERROR
    
  let arg1= $Tcl.GetString(objv[1])

  var 
    img: pixie.Image
    b64: string

  if pixTables.hasContext(arg1):
    img = pixTables.getContext(arg1).image
  elif pixTables.hasImage(arg1):
    img = pixTables.getImage(arg1)
  else:
    return ERROR_MSG(interp, "pix(error): no key <ctx>|<img> object found '" & arg1 & "'")
  try:
    let data = encodeImage(img, FileFormat.PngFormat)
    b64  = encode(data)
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(b64.cstring, -1))
    
  return Tcl.OK

proc rotMatrix*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rotation to the matrix
  # 
  # angle   - double value (radian)
  # matrix  - list
  #
  # Returns the matrix rotation as a list.
  var
    matrix3: vmath.Mat3
    angle: cdouble

  let listobj = Tcl.NewListObj(0, nil)

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "angle 'list'")
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
    return Tcl.ERROR

  matrix3 = matrix3 * vmath.rotate(-angle.float32)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(interp, listobj, Tcl.NewDoubleObj(matrix3[i][j]))

  Tcl.SetObjResult(interp, listobj)
    
  return Tcl.OK