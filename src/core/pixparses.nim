# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import std/strutils
import ./pixobj as pixObj
import ../bindings/tcl/binding as Tcl

type
  RenderOptions* = object
    strokeWidth*: float32        = 1.0
    transform*: Mat3             = mat3()
    lineCap*: LineCap            = ButtCap
    lineJoin*: LineJoin          = MiterJoin
    miterLimit*: float32         = pixie.defaultMiterLimit
    dashes*: seq[float32]        = @[]
    hAlign*: HorizontalAlignment = LeftAlign
    vAlign*: VerticalAlignment   = TopAlign
    bounds*: Vec2                = vec2(0, 0)
    wrap*: bool                  = true

  RenderShadow* = object
    blur*: float32   = 1.0
    spread*: float32 = 1.0
    offset*: Vec2    = vec2(0, 0)
    color*: Color    = color(0, 0, 0, 0)

template getFloat*(obj: Tcl.PObj, raiseOnError: static bool = false): float32 =
  # Gets a double value from a Tcl object.
  #
  # obj          - The Tcl object to get the double value from.
  # raiseOnError - If true, raises ValueError on failure.
  #                If false, returns Tcl.ERROR on failure.
  #
  # Returns: The double value or an error if the object is not a double.
  var val: cdouble
  if Tcl.GetDoubleFromObj(interp, obj, val) != Tcl.OK:
    when raiseOnError:
      raise newException(ValueError, $interp)
    else:
      return Tcl.ERROR
  val.float32

template getBool*(obj: Tcl.PObj, raiseOnError: static bool = false): bool =
  # Gets a boolean value from a Tcl object.
  #
  # obj          - The Tcl object to get the boolean value from.
  # raiseOnError - If true, raises ValueError on failure.
  #                If false, returns Tcl.ERROR on failure.
  #
  # Returns: The boolean value or an error if the object is not a boolean.
  var val: cint
  if Tcl.GetBooleanFromObj(interp, obj, val) != Tcl.OK:
    when raiseOnError:
      raise newException(ValueError, $interp)
    else:
      return Tcl.ERROR
  val.bool

template getInt*(obj: Tcl.PObj, raiseOnError: static bool = false): int =
  ## Gets an integer value from a Tcl object.
  ##
  ## obj          - The Tcl object to get the integer value from.
  ## raiseOnError - If true, raises ValueError on failure.
  ##               If false, returns Tcl.ERROR on failure.
  var val: cint
  if Tcl.GetIntFromObj(interp, obj, val) != Tcl.OK:
    when raiseOnError:
      raise newException(ValueError, $interp)
    else:
      return Tcl.ERROR
  val.int


template getOptEnum*[T: enum](val: string): T =
  # Parses an enum value from a string.
  #
  # T   - The enum type to parse.
  # val - The string value to parse.
  #
  # Returns: The enum value or an error if the string 
  # is not a valid enum value.
  try:
    parseEnum[T](val)
  except ValueError:
    raise newException(ValueError, "Invalid value '" & val & "' for type " & $T)

proc getListInt*(interp: Tcl.PInterp, objv: Tcl.PObj, v1, v2: var int, errorMsg: string): cint =
  # Parse a list of two integers from a Tcl object.
  #
  # interp    - The Tcl interpreter.
  # objv      - The Tcl object to parse.
  # v1, v2    - The two integers to populate from the object.
  # errorMsg  - The error message to return if the object is not equal to 2.
  #
  # Returns: if the object is a list of two integers, returns Tcl.OK (0).
  # Otherwise, returns Tcl.ERROR (1).
  var
    count: Tcl.Size
    elements: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    Tcl.SetObjResult(interp, Tcl.NewStringObj(errorMsg.cstring, -1))
    return Tcl.ERROR

  v1 = elements[0].getInt()
  v2 = elements[1].getInt()

  return Tcl.OK

proc getListFloat*(interp: Tcl.PInterp, objv: Tcl.PObj, v1, v2: var float32, errorMsg: string): cint =
  # Parse a list of two doubles from a Tcl object.
  #
  # interp    - The Tcl interpreter.
  # objv      - The Tcl object to parse.
  # v1, v2    - The two doubles to populate from the object.
  # errorMsg  - The error message to return if the object is not equal to 2.
  #
  # Returns: if the object is a list of two doubles, returns Tcl.OK (0).
  # Otherwise, returns Tcl.ERROR (1).
  var
    count: Tcl.Size
    elements: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count != 2:
    Tcl.SetObjResult(interp, Tcl.NewStringObj(errorMsg.cstring, -1))
    return Tcl.ERROR

  v1 = elements[0].getFloat()
  v2 = elements[1].getFloat()

  return Tcl.OK

template getMtx*(obj: Tcl.PObj, raiseOnError: static bool = false): vmath.Mat3 =
  # Parses a 3x3 matrix from a Tcl object.
  #
  # obj          - The Tcl object to parse.
  # raiseOnError - If true, raises ValueError on failure.
  #                If false, returns Tcl.ERROR on failure.
  #
  # Returns: A 3x3 matrix.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    matrix3: vmath.Mat3

  if Tcl.ListObjGetElements(interp, obj, count, elements) != Tcl.OK:
    when raiseOnError:
      raise newException(ValueError, $interp)
    else:
      return Tcl.ERROR
  elif count != 9:
    let msg = "wrong # args: Matrix 3x3 requires exactly 9 elements."
    when raiseOnError:
      raise newException(ValueError, msg)
    else:
      Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
      return Tcl.ERROR
  else:
    for i in 0 ..< count:
      matrix3[i div 3, i mod 3] = getFloat(elements[i], raiseOnError)

  matrix3

proc toDictObj*(rect: bumpy.Rect): Tcl.PObj =
  # Converts a bumpy rectangle to a Tcl dict.
  #
  # rect - The rectangle to convert.
  #
  # Returns: A Tcl dict with the rectangle properties.

  let dict = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))
  
  return dict

proc toDictObj*(img: pixie.Image): Tcl.PObj =
  # Converts an image size to a Tcl dict.
  #
  # img - The image to convert.
  #
  # Returns: A Tcl dict with the size properties.

  let dict = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("width", 5),  Tcl.NewIntObj(img.width.cint))
  discard Tcl.DictObjPut(nil, dict, Tcl.NewStringObj("height", 6), Tcl.NewIntObj(img.height.cint))
  
  return dict

func isHexDigit*(c: char): bool =
  # Checks whether a character is a hexadecimal digit (0-9, A-F, a-f).
  return (c >= '0' and c <= '9') or
         (c >= 'A' and c <= 'F') or
         (c >= 'a' and c <= 'f')

func isValidHex*(s: string): bool =
  # Checks whether a string is a valid hex format.

  for c in s:
    if not isHexDigit(c):
      return false

  return true

func isHexFormat*(s: string): bool =
  # Checks whether a string is in ‘hex’ format (e.g. FF0000)
  # - Only hexadecimal characters
  # - Length of 6 characters (typical for an RGB color)

  return (s.len == 6) and isValidHex(s)

func isHexAlphaFormat*(s: string): bool =
  # Checks whether a string is in ‘hexalpha’ format (e.g. FF0000FF)
  # - Only hexadecimal characters
  # - Length of 8 characters (typical for an RGBA color)

  return (s.len == 8) and isValidHex(s)

func isHexHtmlFormat*(s: string): bool =
  # Checks whether a string is in ‘hexHtml’ format (e.g. #F8D1DD)

  return (s.len == 7) and (s[0] == '#')

func isTinyHexHtmlFormat*(s: string): bool =
  # Checks whether a string is in ‘TinyhexHtml’ format (e.g. #FF6)

  return (s.len == 4) and (s[0] == '#')

func fmtHexPtr*[T](obj: T): string =
  # Converts an object to a hexadecimal string.
  #
  # obj - The object to convert.
  #
  # Returns: Hex string like '0x12345'.
  let
    myPtr  = cast[pointer](obj)
    hexStr = cast[uint64](myPtr).toHex()

  # Inline strip leading zeros
  result = block:
    var i = 0
    while i < hexStr.len and hexStr[i] == '0': inc i
    if i >= hexStr.len: "0" else: hexStr[i..^1]

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
    count: Tcl.Size
    elements: Tcl.PPObj
    components : array[4, float32]
    interp: Tcl.PInterp = nil  # set by the caller

  if Tcl.ListObjGetElements(nil, obj, count, elements) != Tcl.OK:
    return false

  if count notin [3, 4]:
    return false

  for i in 0..count-1:
    let val = try:
      getFloat(elements[i], true)
    except ValueError:
      return false
    if val notin (0.0'f32..1.0'f32): 
      return false
    components[i] = val

  # Fill the colorSimple with the color.
  colorSimple =
    if count == 3:
      color(components[0], components[1], components[2])
    else:
      color(components[0], components[1], components[2], components[3])

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

    let value = try:
       parseInt(s[start..<endPos]).uint8
    except ValueError as e:
      raise newException(InvalidColor, "invalid color format: " & e.msg)

    if not (value >= 0 and value <= 255):
      raise newException(InvalidColor, "the value must be between 0 and 255: " & s)

    color[i] = value
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

    var myColor: Color

    result =
      if scolor.isColorXRGBAFormat("rgba"):
       chroma.parseHtmlRgba(scolor)
      elif scolor.isHexHtmlFormat():
        chroma.parseHtmlHex(scolor)
      elif scolor.isColorFormat("rgb"):
        chroma.parseHtmlRgb(scolor)
      elif scolor.isHexAlphaFormat():
        chroma.parseHexAlpha(scolor)
      elif scolor.isHexFormat():
        chroma.parseHex(scolor)
      elif scolor.isColorXRGBAFormat("rgbx"):
        parseColorRGBX(scolor).color
      elif scolor.isColorFormat("hsl"):
        parseColorHSL(scolor).color
      elif scolor.isColorFormat("hsv"):
        parseColorHSV(scolor).color
      elif scolor.isTinyHexHtmlFormat():
        chroma.parseHtmlHexTiny(scolor)
      elif isColorSimpleFormat(obj, myColor):
        myColor
      else:
        chroma.parseHtmlName(scolor)

proc shadowOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderShadow) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderShadow' object.
  #
  #  interp - interpreter.
  #  objv   - object options .
  #  opts   - RenderShadow object to populate.
  #
  # Returns: Nothing or an exception if an error is found.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    x, y: float32

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $interp)

  if count mod 2 != 0:
    raise newException(ValueError,
      "wrong # args: 'shadow options' should be :?key value key1 value1 ...?"
    )

  for i in countup(0, count - 1, 2):
    let
      key = $elements[i]
      value = elements[i+1]
    case key:
      of "blur":
        opts.blur = getFloat(value, true)
      of "spread":
        opts.spread = getFloat(value, true)
      of "offset":
        if getListFloat(interp, value, x, y,
          "wrong # args: 'offset' should be {x y}") != Tcl.OK:
          raise newException(ValueError, $interp)
        opts.offset = vec2(x, y)
      of "color":
        opts.color = value.getColor()
      else:
        raise newException(ValueError,
          "wrong # args: Key '" & key & "' not supported."
        )

proc dictOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options.
  #  opts   - RenderOptions object to populate.
  #
  # Returns: Nothing or an exception if an error is found.
  var
    count, dashescount: Tcl.Size
    elements, dasheselements: Tcl.PPObj

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $interp)

  if count mod 2 != 0:
    raise newException(ValueError,
      "wrong # args: 'options' should be :key value ?key1 ?value1 ...?"
    )

  for i in countup(0, count - 1, 2):
    let
      key = $elements[i]
      value = elements[i+1]
    case key:
      of "strokeWidth":
        opts.strokeWidth = getFloat(value, true)
      of "transform":
        opts.transform = getMtx(value, true)
      of "lineCap":
          opts.lineCap = getOptEnum[LineCap]($value)
      of "miterLimit":
        opts.miterLimit = getFloat(value, true)
      of "lineJoin":
          opts.lineJoin = getOptEnum[LineJoin]($value)
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $interp)
        for j in 0..dashescount-1:
          opts.dashes.add(getFloat(dasheselements[j], true))
        # To get around pixie's problem when my list is not even,
        # because pixie uses 'dashes.add(dashes)' which is not allowed.
        # With -d:useMalloc enabled, I have an error in particular on MacOs.
        if opts.dashes.len mod 2 != 0:
          var copyOfDashes = opts.dashes
          opts.dashes.add(copyOfDashes)

      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")

proc fontOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options.
  #  opts   - RenderOptions object to populate.
  #
  # Returns: Nothing or an exception if an error is found.
  var
    count, dashescount: Tcl.Size
    elements, dasheselements: Tcl.PPObj
    x, y: float32

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $interp)

  if count mod 2 != 0:
    raise newException(ValueError,
      "wrong # args: 'font options' should be :?key value key1 value1 ...?"
    )

  for i in countup(0, count - 1, 2):
    let
      key = $elements[i]
      value = elements[i+1]
    case key:
      of "strokeWidth":
        opts.strokeWidth = getFloat(value, true)
      of "transform":
        opts.transform = getMtx(value, true)
      of "miterLimit":
        opts.miterLimit = getFloat(value, true)
      of "hAlign":
          opts.hAlign = getOptEnum[HorizontalAlignment]($value)
      of "vAlign":
          opts.vAlign = getOptEnum[VerticalAlignment]($value)
      of "lineCap":
          opts.lineCap = getOptEnum[LineCap]($value)
      of "lineJoin":
          opts.lineJoin = getOptEnum[LineJoin]($value)
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $interp)

        for j in 0..dashescount-1:
          opts.dashes.add(getFloat(dasheselements[j], true))

        # To get around pixie's problem when my list is not even,
        # because pixie uses 'dashes.add(dashes)' which is not allowed.
        # With -d:useMalloc enabled, I have an error in particular on MacOs.
        if opts.dashes.len mod 2 != 0:
          var copyOfDashes = opts.dashes
          opts.dashes.add(copyOfDashes)

      of "bounds":
        if getListFloat(interp, value, x, y,
          "wrong # args: 'bounds' should be {x y}") != Tcl.OK:
          raise newException(ValueError, $interp)

        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError,
          "wrong # args: Key '" & key & "' not supported."
        )

proc typeSetOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options.
  #  opts   - RenderOptions object to populate.
  #
  # Returns: Nothing or an exception if an error is found.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    x, y: float32

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $interp)

  if count mod 2 != 0:
    raise newException(ValueError,
      "wrong # args: 'typeSet options' should be :?key value key1 value1 ...?"
    )

  for i in countup(0, count - 1, 2):
    let
      key = $elements[i]
      value = elements[i+1]
    case key:
      of "wrap":
        opts.wrap = getBool(value, true)
      of "hAlign":
          opts.hAlign = getOptEnum[HorizontalAlignment]($value)
      of "vAlign":
          opts.vAlign = getOptEnum[VerticalAlignment]($value)
      of "bounds":
        if getListFloat(interp, value, x, y,
          "wrong # args: 'bounds' should be {x y}") != Tcl.OK:
          raise newException(ValueError, $interp)
        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError,
          "wrong # args: Key '" & key & "' not supported."
        )
