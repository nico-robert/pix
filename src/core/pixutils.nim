# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import std/[strutils, tables, base64]
import ../core/pixtables as pixTables

from ../bindings/tcl/binding as Tcl import nil

proc errorMSG*(interp: Tcl.PInterp, errormsg: string): cint =
  # Sets the interpreter result to the error message.
  #
  # interp   - The Tcl interpreter.
  # errormsg - The error message.
  #
  # Returns: Tcl.ERROR on failure.
  Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))

  return Tcl.ERROR

proc isHexDigit(c: char): bool =
  # Checks whether a character is a hexadecimal digit (0-9, A-F)
  return (c >= '0' and c <= '9') or
         (c >= 'A' and c <= 'F')
         
proc isValidHex(s: string): bool =
  # Checks whether a string is a valid hex format.
  if s.len == 0:
    return false
    
  for c in s:
    if not isHexDigit(c):
      return false
      
    # Only uppercase hex characters are accepted.
    if c >= 'a' and c <= 'f':
      return false
      
  return true
  
proc isHexFormat*(s: string): bool =
  # Checks whether a string is in ‘hex’ format (e.g. FF0000)
  # - Only uppercase hexadecimal characters
  # - Length of 6 characters (typical for an RGB color)
  
  return (s.len == 6) and isValidHex(s)

proc isHexAlphaFormat*(s: string): bool =
  # Checks whether a string is in ‘hexalpha’ format (e.g. FF0000FF)
  # - Only uppercase hexadecimal characters
  # - Length of 8 characters (typical for an RGBA color)
  
  return (s.len == 8) and isValidHex(s)

proc isHexHtmlFormat*(s: string): bool =
  # Checks whether a string is in ‘hexHtml’ format (e.g. #F8D1DD)
  
  return (s.len == 7) and (s[0] == '#')

proc isRGBXFormat*(s: string): bool =
  # Checks if the color is a color in the rgbx 
  # format (e.g. rgbx(x,x,x,x)).

  if (s.len < 4) or (s[0..3] != "rgbx"):
    return false

  var count = 1
  for c in s[5..^2]:
    if c == ',':
      inc count
  
  return count == 4

proc isRGBAFormat*(s: string): bool =
  # Checks if the color is a color in the rgba 
  # format (e.g. rgba(x,x,x,x)).

  if (s.len < 4) or (s[0..3] != "rgba"):
    return false

  var count = 1
  for c in s[5..^2]:
    if c == ',':
      inc count
  
  return count == 4

proc isRGBFormat*(s: string): bool =
  # Checks if the color is a color in the rgb 
  # format (e.g. rgb(x,x,x)).

  if (s.len < 3) or (s[0..2] != "rgb"):
    return false

  var count = 1
  for c in s[4..^2]:
    if c == ',':
      inc count
  
  return count == 3
  
proc isColorSimpleFormat*(obj: Tcl.PObj, colorSimple: var Color): bool =
  # Checks if the obj is a color.
  #
  # obj         - The object to check.
  # colorSimple - The color to fill if the object is a color.
  #
  # Returns: True if the object is a color, false otherwise.
  var
    c: cdouble = 0
    count: Tcl.Size
    elements: Tcl.PPObj
    color : seq[cdouble]

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

  
proc parseColorRGBX*(s: string): ColorRGBX =
  # This procedure attempts to parse a color from a string input.
  #
  # s - The color to check.
  #
  # Returns: A color in ColorRGBX format.
  var
    color: array[4, uint8]
    start = 5  # Position after "rgbx("
    endPos = 0
    
  for i in 0..3:
    while start < s.len and s[start] == ' ':
      inc start

    endPos = start
    while (endPos < s.len) and (s[endPos] != ',') and (s[endPos] != ')'):
      inc endPos
    
    color[i] = parseInt(s[start..<endPos]).uint8
    start = endPos + 1

  return rgbx(color[0],color[1],color[2],color[3])
  
proc getColor*(obj: Tcl.PObj): Color =
  # This procedure attempts to parse a color from a string input.
  # The string can be in various formats such as hexalpha, colorRGBX
  # hex, or HTML color names.
  #
  # obj - The color to check.
  #
  # Returns: A `Color` object.

  let scolor = strip($Tcl.GetString(obj))
  var color: Color

  # Check if the string or object is :
  #
  # in 'rgba' format (e.g. rgba(x,x,x,x))
  if scolor.isRGBAFormat():
    return parseHtmlRgba(scolor)
  # in 'hexHtml' format (e.g. #F8D1DD)
  elif scolor.isHexHtmlFormat():
    return parseHtmlHex(scolor)
  # in 'rgb' format (e.g. rgb(x,x,x))
  elif scolor.isRGBFormat():
    return parseHtmlRgb(scolor)
  # in 'hexalpha' format (e.g. FF0000FF)
  elif scolor.isHexAlphaFormat():
    return parseHexAlpha(scolor)
  # in 'hex' format (e.g. FF0000)
  elif scolor.isHexFormat():
    return parseHex(scolor)
  # in 'rgbx' format (e.g. rgbx(x,x,x,x))
  elif scolor.isRGBXFormat():
    return parseColorRGBX(scolor).color
  # a simple color format (e.g. {0.0 0.0 0.0 0.0})
  elif isColorSimpleFormat(obj, color): 
    return color
  else:
    return parseHtmlColor(scolor)

template toHexPtr*[T](obj: T): string =
  # Converts an object to a hexadecimal string.
  #
  # obj - The object to convert.
  #
  # Returns: A hexadecimal string.

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

proc matrix3x3*(interp: Tcl.PInterp, obj: Tcl.PObj, matrix3: var vmath.Mat3): cint =
# Converts a Tcl list to a matrix 3x3.
#
# interp  - The Tcl interpreter.
# obj     - The Tcl object.
# matrix3 - The matrix to fill with the values of the Tcl object.
#
# Returns: Tcl.OK if successful, Tcl.ERROR otherwise.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    value : seq[cdouble]

  if Tcl.ListObjGetElements(interp, obj, count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 9:
    return pixUtils.errorMSG(interp, "wrong # args: 'matrix' should be 'Matrix 3x3'")

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
  # Converts an HTML color into an RGBA value and returns it as a Tcl list.
  #
  # HTMLcolor - string
  #
  # Returns: A Tcl list.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "color")
    return Tcl.ERROR

  # Parse
  let color = try:
    getColor(objv[1]).rgba
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let newobj = Tcl.NewListObj(0, nil)

  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.r.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.g.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.b.int))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.a.int))

  Tcl.SetObjResult(interp, newobj)

  return Tcl.OK

proc pathObjToString*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse [path] object.
  #
  # path - [path::new]
  #
  # Returns: The parsed [path] to SVG style path (string).
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasPath(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <path> object found '" & arg1 & "'")

  let path = pixTables.getPath(arg1)

  let pathStr = try:
    $path
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pathStr.cstring, -1))

  return Tcl.OK

proc svgStyleToPathObj*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Transforms a SVG style path (string) to a [path::new] object.
  #
  # path - a string in SVG style.
  #
  # Returns: A *new* [path] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "string")
    return Tcl.ERROR

  # Path
  let arg1 = $Tcl.GetString(objv[1])

  let parse = try:
    parsePath(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(parse)
  pixTables.addPath(p, parse)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc toB64*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Convert an [img] object to base 64.
  #
  # object - [img] or [ctx] object.
  #
  # Returns: A string in `base64` format.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
    return Tcl.ERROR

  let arg1= $Tcl.GetString(objv[1])

  let img = if pixTables.hasContext(arg1):
    pixTables.getContext(arg1).image
  elif pixTables.hasImage(arg1):
    pixTables.getImage(arg1)
  else:
    return pixUtils.errorMSG(interp, "pix(error): no key <ctx>|<img> object found '" & arg1 & "'")

  let b64 = try:
    let data = encodeImage(img, FileFormat.PngFormat)
    encode(data)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(b64.cstring, -1))

  return Tcl.OK

proc rotMatrix*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Adds a rotation to the matrix.
  #
  # angle   - double value (radian)
  # matrix  - list (9 values matrix3x3)
  #
  # Returns: The matrix rotation as a list.
  var
    matrix3: vmath.Mat3
    angle: cdouble

  let listobj = Tcl.NewListObj(0, nil)

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "angle 'list (9 values matrix3x3)'")
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