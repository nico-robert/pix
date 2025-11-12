# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import ./pixtables
import ./pixobj as pixObj
import std/[strutils, sequtils, base64, tables]
import ../bindings/tcl/binding as Tcl

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
  # Checks whether a character is a hexadecimal digit (0-9, A-F, a-f).
  return (c >= '0' and c <= '9') or
         (c >= 'A' and c <= 'F') or
         (c >= 'a' and c <= 'f')

proc isValidHex(s: string): bool =
  # Checks whether a string is a valid hex format.

  for c in s:
    if not isHexDigit(c):
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

proc isTinyHexHtmlFormat*(s: string): bool =
  # Checks whether a string is in ‘TinyhexHtml’ format (e.g. #FF6)

  return (s.len == 4) and (s[0] == '#')

proc isColorXRGBAFormat*(s: string, colorType: string): bool =
  # Checks if the color is a color in the rgba
  # or rgbx format.
  # e.g.: rgba(x,x,x,x), rgbx(x,x,x,x).

  if s.len < 9:
    return false

  if s[0..3] != colorType:
    return false

  var count = 1
  for c in s[5..^2]:
    if c == ',':
      inc count

  return count == 4

proc isColorFormat*(s: string, colorType: string): bool =
  # Checks if the color is a color in the rgb, hsl
  # or hsv format.
  # e.g.: rgb(x,x,x), hsl(x,x,x), hsv(x,x,x)

  if s.len < 7:
    return false

  if s[0..2] != colorType:
    return false

  if s[3] != '(' or s[^1] != ')':
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

  if count notin [3, 4]:
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

proc parseColorHSL*(s: string): ColorHSL =
  # This procedure attempts to parse a color from a string input.
  #
  # s - The color to check.
  #
  # Returns: A color in ColorHSL format.
  var
    color: array[3, float32]
    start = 4  # Position after "hsl("
    endPos = 0

  for i in 0..2:
    while start < s.len and s[start] == ' ':
      inc start

    endPos = start
    while (endPos < s.len) and (s[endPos] != ',') and (s[endPos] != ')'):
      inc endPos

    try:
      color[i] = parseFloat(s[start..<endPos])
    except ValueError as e:
      raise newException(InvalidColor, "invalid color format: " & e.msg)

    start = endPos + 1

  return hsl(color[0], color[1], color[2])

proc parseColorHSV*(s: string): ColorHSV =
  # This procedure attempts to parse a color from a string input.
  #
  # s - The color to check.
  #
  # Returns: A color in ColorHSV format.
  var
    color: array[3, float32]
    start = 4  # Position after "hsv("
    endPos = 0

  for i in 0..2:
    while start < s.len and s[start] == ' ':
      inc start

    endPos = start
    while (endPos < s.len) and (s[endPos] != ',') and (s[endPos] != ')'):
      inc endPos

    try:
      color[i] = parseFloat(s[start..<endPos])
    except ValueError as e:
      raise newException(InvalidColor, "invalid color format: " & e.msg)

    start = endPos + 1

  return hsv(color[0], color[1], color[2])

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

    try:
      color[i] = parseInt(s[start..<endPos]).uint8
    except ValueError as e:
      raise newException(InvalidColor, "invalid color format: " & e.msg)

    start = endPos + 1

  return rgbx(color[0], color[1], color[2], color[3])

proc getColor*(obj: Tcl.PObj): Color =
  # This procedure attempts to parse a color from a string input.
  # The string can be in various formats such as hexalpha, colorRGBX
  # hex, or HTML color names.
  #
  # obj - The color to check.
  #
  # Check if the string or object is :
  #
  # in 'rgba' format (e.g. rgba(x,x,x,x))
  # in 'hexHtml' format (e.g. #F8D1DD)
  # in 'rgb' format (e.g. rgb(x,x,x))
  # in 'hexalpha' format (e.g. FF0000FF)
  # in 'hex' format (e.g. FF0000)
  # in 'rgbx' format (e.g. rgbx(x,x,x,x))
  # in 'hsl' format (e.g. hsl(x,x,x))
  # in 'hsv' format (e.g. hsv(x,x,x))
  # in tiny 'hex' format (e.g. #FF6)
  # a simple color format (e.g. {0.0 0.0 0.0 0.0})
  # a simple string html color name (e.g. red)
  #
  # Returns: A `Color` object.

  let colorObj = pixObj.getTypeColor(obj)

  if not colorObj.isNil:
    return colorObj[]
  else:
    let scolor = strip($obj)
    if scolor.len == 0:
      raise newException(InvalidColor, "Empty color string.")

    var color: Color

    if scolor.isColorXRGBAFormat("rgba"):
      return chroma.parseHtmlRgba(scolor)
    elif scolor.isHexHtmlFormat():
      return chroma.parseHtmlHex(scolor)
    elif scolor.isColorFormat("rgb"):
      return chroma.parseHtmlRgb(scolor)
    elif scolor.isHexAlphaFormat():
      return chroma.parseHexAlpha(scolor)
    elif scolor.isHexFormat():
      return chroma.parseHex(scolor)
    elif scolor.isColorXRGBAFormat("rgbx"):
      return parseColorRGBX(scolor).color
    elif scolor.isColorFormat("hsl"):
      return parseColorHSL(scolor).color
    elif scolor.isColorFormat("hsv"):
      return parseColorHSV(scolor).color
    elif scolor.isTinyHexHtmlFormat():
      return chroma.parseHtmlHexTiny(scolor)
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

  if Tcl.ListObjGetElements(interp, obj, count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 9:
    return pixUtils.errorMSG(interp,
      "wrong # args: Matrix 3x3 requires exactly 9 elements."
    )

  for i in 0..count-1:
    var value: cdouble
    if Tcl.GetDoubleFromObj(interp, elements[i], value) != Tcl.OK:
      return Tcl.ERROR
    # Fill the matrix3 with the values of the Tcl object.
    matrix3[i div 3, i mod 3] = value

  return Tcl.OK

proc addToListObj*(matrix3: vmath.Mat3): Tcl.PObj =
  # Adds a matrix 3x3 to a Tcl list object.
  #
  # matrix3 - matrix.
  #
  # Returns: A Tcl list as object.
  let listMtxobj = Tcl.NewListObj(0, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        nil,
        listMtxobj,
        Tcl.NewDoubleObj(matrix3[i, j])
      )

  return listMtxobj

proc pix_colorHTMLtoRGBA*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
    pixUtils.getColor(objv[1]).rgba
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let listColorObj = Tcl.NewListObj(0, nil)

  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.r.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.g.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.b.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.a.cint))

  Tcl.SetObjResult(interp, listColorObj)

  return Tcl.OK

proc pix_pathObjToString*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse [path] object.
  #
  # path - [path::new]
  #
  # Returns: The parsed [path] to SVG style path (string).
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.loadPath(interp, objv[1])
  if path.isNil: return Tcl.ERROR

  Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring($path), -1))

  return Tcl.OK

proc pix_svgStyleToPathObj*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Transforms a SVG style path (string) to a [path::new] object.
  #
  # path - a string in SVG style.
  #
  # Returns: A *new* [path] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "string")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let arg1 = $objv[1]

  let parse = try:
    parsePath(arg1)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(parse)
  ptable.addPath(p, parse)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_getKeys*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Get all objects from the context and the image.
  #
  # Returns: A Tcl dictionary with two keys:
  # `ctx` a Tcl list of all [ctx] keys and
  # `img` a Tcl list of all [img] keys.
  let
    dictObj    = Tcl.NewDictObj()
    newListctx = Tcl.NewListObj(0, nil)
    newListimg = Tcl.NewListObj(0, nil)
    ptable     = cast[PixTable](clientData)

  for key in ptable.ctxTable.keys:
    discard Tcl.ListObjAppendElement(
      interp, newListctx,
      Tcl.NewStringObj(key.cstring, -1)
    )

  for key in ptable.imgTable.keys:
    discard Tcl.ListObjAppendElement(
      interp, newListimg,
      Tcl.NewStringObj(key.cstring, -1)
    )

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("ctx", 3), newListctx)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("img", 3), newListimg)

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_toB64*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Convert an [img] object to base 64.
  #
  # object - [img] or [ctx] object.
  #
  # On the Nim side, `base64` module is considered **unstable**,
  # so use the [toBinary] command instead
  # and then Tcl's binary encode base64 command.
  #
  # Returns string.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1= $objv[1]

  let img = if ptable.hasContext(arg1):
    ptable.getContext(arg1).image
  elif ptable.hasImage(arg1):
    ptable.getImage(arg1)
  else:
    return pixUtils.errorMSG(interp,
      "pix(error): unknown <image> or <ctx> key object found '" & arg1 & "'"
    )

  let data = try:
    encodeImage(img, PngFormat)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let b64 = try:
    encode(data)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(b64.cstring, -1))

  return Tcl.OK

proc pix_toBinary*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Convert an [img] object to binary.
  #
  # object - [img] or [ctx] object.
  # format - string (png, qoi, bmp, ppm) (optional:png).
  #
  # Returns: A string in binary format.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img> ?format:optional")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1= $objv[1]

  let img = if ptable.hasContext(arg1):
    ptable.getContext(arg1).image
  elif ptable.hasImage(arg1):
    ptable.getImage(arg1)
  else:
    return pixUtils.errorMSG(interp,
      "pix(error): unknown <image> or <ctx> key object found '" & arg1 & "'"
    )

  var fileformat: FileFormat = PngFormat

  if objc == 3:
    let format = $objv[2]
    fileFormat = case format.toLowerAscii():
      of "png": PngFormat
      of "bmp": BmpFormat
      of "qoi": QoiFormat
      of "ppm": PpmFormat
      else:
        return pixUtils.errorMSG(interp,
          "pix(error): format not supported '" & format & "'."
        )

  let data = try:
    encodeImage(img, fileformat)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewByteArrayObj(data.cstring, Tcl.Size(data.len)))

  return Tcl.OK

proc pix_rotMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Create rotation matrix.
  #
  # angle   - double value (radian)
  # matrix  - list (9 values) (optional:mat3())
  #
  # Returns: The matrix rotation as a list.
  if objc notin [2 ,3]:
    Tcl.WrongNumArgs(interp, 1, objv, "angle ?matrix:optional")
    return Tcl.ERROR

  var
    angle: cdouble
    matrix3: vmath.Mat3

  if Tcl.GetDoubleFromObj(interp, objv[1], angle) != Tcl.OK:
    return Tcl.ERROR

  if objc == 3:
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.rotate(angle.float32)

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_invMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Create an inverse matrix.
  #
  # matrix  - list (9 values) (optional:mat3())
  #
  # Returns: The matrix inverse as a list.
  if objc > 2:
    Tcl.WrongNumArgs(interp, 1, objv, "?matrix:optional")
    return Tcl.ERROR

  var matrix3: vmath.Mat3

  if objc == 2:
    if matrix3x3(interp, objv[1], matrix3) != Tcl.OK:
      return Tcl.ERROR
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3.inverse()

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_scaleMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Create scale matrix.
  #
  # scale   - list x,y
  # matrix  - list (9 values) (optional:mat3())
  #
  # Returns: The matrix scaled as a list.
  if objc notin [2 ,3]:
    Tcl.WrongNumArgs(interp, 1, objv, "{x y} ?matrix:optional")
    return Tcl.ERROR

  var
    x, y: cdouble
    matrix3: vmath.Mat3
    count: Tcl.Size
    elements: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp,
      "wrong # args: 'scale' should be 'x' 'y'"
    )

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK:
    return Tcl.ERROR

  if objc == 3:
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.scale(vec2(x, y))

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_transMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Create translation matrix.
  #
  # trans   - list x,y
  # matrix  - list (9 values) (optional:mat3())
  #
  # Returns: The matrix translated as a list.
  if objc notin [2 ,3]:
    Tcl.WrongNumArgs(interp, 1, objv, "{x y} ?matrix:optional")
    return Tcl.ERROR

  var
    x, y: cdouble
    matrix3: vmath.Mat3
    count: Tcl.Size
    elements: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    return pixUtils.errorMSG(interp,
      "wrong # args: 'trans' should be 'x' 'y'"
    )

  if Tcl.GetDoubleFromObj(interp, elements[0], x) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[1], y) != Tcl.OK:
    return Tcl.ERROR

  if objc == 3:
    if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.translate(vec2(x, y))

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_mulMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Multiplies matrices.
  #
  # args - matrix (9 values)
  #
  # Returns: The multiplied matrix as a list.
  if objc < 3:
    Tcl.WrongNumArgs(interp, 1, objv, "matrix1 matrix2 matrix...")
    return Tcl.ERROR

  var
    m: vmath.Mat3
    lm: seq[vmath.Mat3]

  for c in 1..objc-1:
    if matrix3x3(interp, objv[c], m) != Tcl.OK:
      return Tcl.ERROR
    lm.add(m)

  let matrix3 = lm.foldl(a * b)

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_rgba*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new rgba color object.
  #
  # r - integer (0-255)
  # g - integer (0-255)
  # b - integer (0-255)
  # a - double (0-1)
  #
  # Returns: A *new* type [color] object.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "r g b a")
    return Tcl.ERROR

  var r, g, b: cint
  var a: cdouble

  if Tcl.GetIntFromObj(interp, objv[1], r) != Tcl.OK or
     Tcl.GetIntFromObj(interp, objv[2], g) != Tcl.OK or
     Tcl.GetIntFromObj(interp, objv[3], b) != Tcl.OK:
    return Tcl.ERROR

  if Tcl.GetDoubleFromObj(interp, objv[4], a) != Tcl.OK:
    return Tcl.ERROR

  var color: Color

  color.r = min(1.0, r / 255)
  color.g = min(1.0, g / 255)
  color.b = min(1.0, b / 255)
  color.a = min(1.0, a)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_rgb*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new rgb color object.
  #
  # r - integer (0-255)
  # g - integer (0-255)
  # b - integer (0-255)
  #
  # Returns: A *new* type [color] object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "r g b")
    return Tcl.ERROR

  var r, g, b: cint

  if Tcl.GetIntFromObj(interp, objv[1], r) != Tcl.OK or
     Tcl.GetIntFromObj(interp, objv[2], g) != Tcl.OK or
     Tcl.GetIntFromObj(interp, objv[3], b) != Tcl.OK:
    return Tcl.ERROR

  var color: Color

  color.r = min(1.0, r / 255)
  color.g = min(1.0, g / 255)
  color.b = min(1.0, b / 255)
  color.a = 1.0

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_hexHTML*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new hex html color object.
  #
  # hex  - hex string
  #
  # Returns: A *new* type [color] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "#xxxxxx")
    return Tcl.ERROR

  let scolor = strip($objv[1])

  if not (isHexHtmlFormat(scolor) and isValidHex(scolor[1..^1])):
    return pixUtils.errorMSG(interp,
      "pix(error): '" & scolor & "' is not a valid hex html color."
    )

  let
    color = chroma.parseHtmlHex(scolor)
    obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_hsl*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new hsl color object.
  #
  # h - hue        (0-360)
  # s - saturation (0-100)
  # l - lightness  (0-100)
  #
  # Returns: A *new* type [color] object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "h s l")
    return Tcl.ERROR

  var h, s, l: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[1], h) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[2], s) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, objv[3], l) != Tcl.OK:
    return Tcl.ERROR

  if not (h >= 0 and h <= 360):
    return pixUtils.errorMSG(interp,
      "pix(error): 'hue' value must be between 0 and 360."
    )

  if not (s >= 0 and s <= 100):
    return pixUtils.errorMSG(interp,
      "pix(error): 'saturation' value must be between 0 and 100."
    )

  if not (l >= 0 and s <= 100):
    return pixUtils.errorMSG(interp,
      "pix(error): 'lightness' value must be between 0 and 100."
    )

  let hsl = hsl(h, s, l)
  let obj = pixObj.createColorObj(hsl.color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_nameColor*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new name color object.
  #
  # name  - HTML name
  #
  # Returns: A *new* type [color] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "name")
    return Tcl.ERROR

  let color = try:
    chroma.parseHtmlName(strip($objv[1]))
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDarken*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Darkens the color by amount 0-1.
  #
  # color   - color or colorObj [color]
  # amount  - double value (0-1)
  #
  # Returns: A *new* type [color] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  var amount: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], amount) != Tcl.OK:
    return Tcl.ERROR

  if not (amount >= 0 and amount <= 1.0):
    return pixUtils.errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = darken(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorLighten*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Lightens the color by amount 0-1.
  #
  # color   - color or colorObj [color]
  # amount  - double value (0-1)
  #
  # Returns: A *new* type [color] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  var amount: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], amount) != Tcl.OK:
    return Tcl.ERROR

  if not (amount >= 0 and amount <= 1.0):
    return pixUtils.errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = lighten(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDesaturate*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Desaturate (makes grayer) the color by amount 0-1.
  #
  # color   - color or colorObj [color]
  # amount  - double value (0-1)
  #
  # Returns: A *new* type [color] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  var amount: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], amount) != Tcl.OK:
    return Tcl.ERROR

  if not (amount >= 0 and amount <= 1.0):
    return pixUtils.errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = desaturate(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorSaturate*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Saturates (makes brighter) the color by amount 0-1. 
  #
  # color   - color or colorObj [color]
  # amount  - double value (0-1)
  #
  # Returns: A *new* type [color] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  var amount: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], amount) != Tcl.OK:
    return Tcl.ERROR

  if not (amount >= 0 and amount <= 1.0):
    return pixUtils.errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = saturate(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorSpin*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Rotates the hue of the color by degrees (0-360).
  #
  # color   - color or colorObj [color]
  # degrees - double value (0-360)
  #
  # Returns: A *new* type [color] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> degrees")
    return Tcl.ERROR

  let colorObj = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  var degrees: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], degrees) != Tcl.OK:
    return Tcl.ERROR

  if not (degrees >= 0 and degrees <= 360):
    return pixUtils.errorMSG(interp,
      "pix(error): 'degrees' value must be between 0 and 360."
    )

  let color = spin(colorObj, degrees)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDistance*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # A distance function based on CIEDE2000 color difference formula.
  #
  # color1   - color or colorObj [color]
  # color2   - color or colorObj [color]
  #
  # Returns: A distance.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2>")
    return Tcl.ERROR

  let color1 = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    pixUtils.getColor(objv[2])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dist = distance(color1, color2)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(dist))

  return Tcl.OK

proc pix_colorAlmostEqual*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Almost equal colors.
  #
  # color1   - color or colorObj [color]
  # color2   - color or colorObj [color]
  # epsilon  - double value (optional:0.01)
  #
  # Returns: True if colors are close.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2> ?epsilon:optional")
    return Tcl.ERROR

  let color1 = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    pixUtils.getColor(objv[2])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let equal =
    if objc == 4:
      var epsilon: cdouble
      if Tcl.GetDoubleFromObj(interp, objv[3], epsilon) != Tcl.OK:
        return Tcl.ERROR
      almostEqual(color1, color2, epsilon)
    else:
      almostEqual(color1, color2)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(equal.cint))

  return Tcl.OK

proc pix_colorMix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Mixes two colours using simple averaging or simple lerp if the “lerp” argument is specified.
  #
  # color1   - color or colorObj [color]
  # color2   - color or colorObj [color]
  # lerp     - double value (optional)
  #
  # Returns: A *new* type [color] object.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2> ?lerp:optional")
    return Tcl.ERROR

  let color1 = try:
    pixUtils.getColor(objv[1])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    pixUtils.getColor(objv[2])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let color =
    if objc == 4:
      var lerp: cdouble
      if Tcl.GetDoubleFromObj(interp, objv[3], lerp) != Tcl.OK:
        return Tcl.ERROR
      mix(color1, color2, lerp)
    else:
      mix(color1, color2)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return pixUtils.errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK