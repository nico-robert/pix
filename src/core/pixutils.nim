# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import ./pixtables
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

proc isHSLFormat*(s: string): bool =
  # Checks if the color is a color in the hsl 
  # format (e.g. hsl(x,x,x)).

  if (s.len < 3) or (s[0..2] != "hsl"):
    return false

  var count = 1
  for c in s[4..^2]:
    if c == ',':
      inc count

  return count == 3

proc isHSVFormat*(s: string): bool =
  # Checks if the color is a color in the hsv
  # format (e.g. hsv(x,x,x)).

  if (s.len < 3) or (s[0..2] != "hsv"):
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
  # a simple color format (e.g. {0.0 0.0 0.0 0.0})
  # a simple string html color name (e.g. red)
  #
  # Returns: A `Color` object.

  let scolor = strip($obj)
  var color: Color

  if scolor.isRGBAFormat():
    return parseHtmlRgba(scolor)
  elif scolor.isHexHtmlFormat():
    return parseHtmlHex(scolor)
  elif scolor.isRGBFormat():
    return parseHtmlRgb(scolor)
  elif scolor.isHexAlphaFormat():
    return parseHexAlpha(scolor)
  elif scolor.isHexFormat():
    return parseHex(scolor)
  elif scolor.isRGBXFormat():
    return parseColorRGBX(scolor).color
  elif scolor.isHSLFormat():
    return parseColorHSL(scolor).color
  elif scolor.isHSVFormat():
    return parseColorHSV(scolor).color
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
    return pixUtils.errorMSG(interp,
    "wrong # args: 'matrix' should be 'Matrix 3x3'"
    )

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

proc colorHTMLtoRGBA*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let newobj = Tcl.NewListObj(0, nil)

  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.r.cint))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.g.cint))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.b.cint))
  discard Tcl.ListObjAppendElement(interp, newobj, Tcl.NewIntObj(color.a.cint))

  Tcl.SetObjResult(interp, newobj)

  return Tcl.OK

proc pathObjToString*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc svgStyleToPathObj*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc getKeys*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc toB64*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc toBinary*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc rotMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  let listobj = Tcl.NewListObj(0, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        interp,
        listobj, 
        Tcl.NewDoubleObj(matrix3[i][j])
      )

  Tcl.SetObjResult(interp, listobj)

  return Tcl.OK

proc scaleMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  let listobj = Tcl.NewListObj(0, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        interp,
        listobj, 
        Tcl.NewDoubleObj(matrix3[i][j])
      )

  Tcl.SetObjResult(interp, listobj)

  return Tcl.OK
  
proc transMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  let listobj = Tcl.NewListObj(0, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        interp,
        listobj, 
        Tcl.NewDoubleObj(matrix3[i][j])
      )

  Tcl.SetObjResult(interp, listobj)

  return Tcl.OK
  
proc mulMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  let 
    matrix3 = lm.foldl(a * b)
    listobj = Tcl.NewListObj(0, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        interp,
        listobj, 
        Tcl.NewDoubleObj(matrix3[i][j])
      )

  Tcl.SetObjResult(interp, listobj)

  return Tcl.OK