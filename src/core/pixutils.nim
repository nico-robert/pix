# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import ./pixtables
import ./pixparses
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

proc setVar*(interp: Tcl.PInterp, name: string, value: int): cint =
  # Sets a global variable in the interpreter.
  #
  # interp  - The Tcl interpreter.
  # name    - The name of the variable.
  # value   - The value of the variable.
  #
  # Returns: Tcl.OK on success, Tcl.ERROR on failure.

  let obj = Tcl.ObjSetVar2(
    interp,
    Tcl.NewStringObj(name.cstring, -1),
    nil,
    Tcl.NewIntObj(value.cint),
    Tcl.GLOBAL_ONLY
  )

  if obj.isNil: 
    return errorMSG(interp, "pix(error): " & $interp)

  return Tcl.OK

proc addToListObj*(matrix3: vmath.Mat3): Tcl.PObj =
  # Adds a matrix 3x3 to a Tcl list object.
  #
  # matrix3 - matrix.
  #
  # Returns: A Tcl list as object.
  let listMtxobj = Tcl.NewListObj(9, nil)

  for i in 0..2:
    for j in 0..2:
      discard Tcl.ListObjAppendElement(
        nil,
        listMtxobj,
        Tcl.NewDoubleObj(matrix3[i, j])
      )

  return listMtxobj

proc pix_colorHTMLtoRGBA*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Converts an HTML color string into an RGBA value and returns it as a Tcl list.
  #
  # HTMLcolor - A color string
  #
  # Returns: A Tcl list {r g b a}.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "color")
    return Tcl.ERROR

  # Parse
  let color = try:
    objv[1].getColor().rgba
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let listColorObj = Tcl.NewListObj(4, nil)

  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.r.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.g.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.b.cint))
  discard Tcl.ListObjAppendElement(nil, listColorObj, Tcl.NewIntObj(color.a.cint))

  Tcl.SetObjResult(interp, listColorObj)

  return Tcl.OK

proc pix_pathObjToString*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parses a [path] object and returns its SVG path string representation.
  #
  # path - [path] object handle
  #
  # Returns: The parsed [path] as an SVG-style string.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<path>")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let path = ptable.load(interp, objv[1], pixie.Path)
  if path.isNil: return Tcl.ERROR

  Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring($path), -1))

  return Tcl.OK

proc pix_svgStyleToPathObj*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Transforms an SVG-style path string into a [path] object.
  #
  # path - An SVG path data string.
  #
  # Returns: A *new* handle [path] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "string")
    return Tcl.ERROR

  # Path
  let ptable = cast[PixTable](clientData)
  let arg1 = $objv[1]

  let parse = try:
    parsePath(arg1)
  except PixieError as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let pathKey = toHexPtr(parse)
  ptable.add(pathKey, parse)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pathKey.cstring, -1))

  return Tcl.OK

proc pix_getKeys*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Retrieves all registered object keys from both the context and image tables.
  #
  # Returns: A Tcl dictionary containing two keys:
  # #Begintable
  # **ctx**  : A Tcl list of all [ctx] handles.
  # **img**  : A Tcl list of all [img] handles.
  # **font** : A Tcl list of all [font] handles.
  # **path** : A Tcl list of all [path] handles.
  # #EndTable
  let
    dictObj     = Tcl.NewDictObj()
    ptable      = cast[PixTable](clientData)
    newListctx  = Tcl.NewListObj(Tcl.Size(ptable.ctxTable.len), nil)
    newListimg  = Tcl.NewListObj(Tcl.Size(ptable.imgTable.len), nil)
    newListfont = Tcl.NewListObj(Tcl.Size(ptable.fontTable.len), nil)
    newListpath = Tcl.NewListObj(Tcl.Size(ptable.pathTable.len), nil)

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

  for key in ptable.fontTable.keys:
    discard Tcl.ListObjAppendElement(
      interp, newListfont,
      Tcl.NewStringObj(key.cstring, -1)
    )

  for key in ptable.pathTable.keys:
    discard Tcl.ListObjAppendElement(
      interp, newListpath,
      Tcl.NewStringObj(key.cstring, -1)
    )

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("ctx", 3),  newListctx)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("img", 3),  newListimg)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("font", 4), newListfont)
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("path", 4), newListpath)

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_toB64*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Converts an [img] or [ctx] object into a base64-encoded string.
  #
  # object - [img] or [ctx] object handle.
  #
  # Note: On the Nim side, the `base64` module is considered unstable.
  # It is recommended to use the [toBinary] command combined with Tcl's
  # native `binary encode base64` command instead.
  #
  # Returns: A base64-encoded string.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1 = $objv[1]

  let img =
    if ptable.has(arg1, pixie.Context):
      ptable.get(arg1, pixie.Context).image
    elif ptable.has(arg1, pixie.Image):
      ptable.get(arg1, pixie.Image)
    else:
      return errorMSG(interp,
        "pix(error): unknown <image> or <ctx> key object found '" & arg1 & "'"
      )

  let b64 = try:
    encode(encodeImage(img, PngFormat))
  except CatchableError as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(b64.cstring, -1))

  return Tcl.OK

proc pix_toBinary*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Converts an [img] or [ctx] object into raw binary image data.
  #
  # object - [img] or [ctx] object handle.
  # format - Image format string (png, qoi, bmp, ppm) (optional:png).
  #
  # Returns: A byte array string in binary format.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img> ?format?")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1 = $objv[1]

  let img =
    if ptable.has(arg1, pixie.Context):
      ptable.get(arg1, pixie.Context).image
    elif ptable.has(arg1, pixie.Image):
      ptable.get(arg1, pixie.Image)
    else:
      return errorMSG(interp,
        "pix(error): unknown <image> or <ctx> key object found '" & arg1 & "'"
      )

  var fileFormat: FileFormat = PngFormat

  if objc == 3:
    let format = $objv[2]
    fileFormat = case format.toLowerAscii():
      of "png": PngFormat
      of "bmp": BmpFormat
      of "qoi": QoiFormat
      of "ppm": PpmFormat
      else:
        return errorMSG(interp,
          "pix(error): format not supported '" & format & "'."
        )

  let data = try:
    encodeImage(img, fileFormat)
  except PixieError as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewByteArrayObj(data.cstring, Tcl.Size(data.len)))

  return Tcl.OK

proc pix_rotMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a transformation rotation matrix or multiplies an existing one.
  #
  # angle  - Double value (in radians).
  # matrix - Optional Tcl list of 9 numbers representing an input 3x3 matrix (optional:identityMatrix).
  #
  # Returns: The rotated 3x3 matrix as a Tcl list of 9 elements.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "angle ?matrix?")
    return Tcl.ERROR

  var matrix3: vmath.Mat3

  let angle = objv[1].getFloat()

  if objc == 3:
    matrix3 = objv[2].getMtx()
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.rotate(angle)

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_invMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Inverts the specified 3x3 transformation matrix.
  #
  # matrix - Optional Tcl list of 9 numbers representing an input 3x3 matrix (optional:identityMatrix).
  #
  # Returns: The inverted 3x3 matrix as a Tcl list of 9 elements.
  if objc > 2:
    Tcl.WrongNumArgs(interp, 1, objv, "?matrix?")
    return Tcl.ERROR

  var matrix3: vmath.Mat3

  if objc == 2:
    matrix3 = objv[1].getMtx()
  else:
    matrix3 = vmath.mat3()

  let det = matrix3.determinant()
  if abs(det) < 1e-10:
    return errorMSG(interp, "matrix is singular, cannot invert.")

  matrix3 = matrix3.inverse()

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_determinantMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Computes the determinant of a 3x3 matrix.
  #
  # matrix - A Tcl list of 9 numbers representing the 3x3 matrix.
  #
  # Returns: The matrix determinant as a double.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "matrix")
    return Tcl.ERROR

  let matrix3 = objv[1].getMtx()

  Tcl.SetObjResult(
    interp,
    Tcl.NewDoubleObj(matrix3.determinant())
  )

  return Tcl.OK

proc pix_transformMatrixPoint*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Transforms a 2D point using a 3x3 transformation matrix.
  #
  # point  - A Tcl list {x y} representing the point coordinates.
  # matrix - A Tcl list of 9 numbers representing the 3x3 matrix.
  #
  # Returns: A Tcl list {x y} containing the transformed coordinates.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "{x y} matrix")
    return Tcl.ERROR

  # Point
  var x, y: float32

  if getListFloat(interp, objv[1], x, y, 
    "wrong # args: 'point' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  let transformed = objv[2].getMtx() * vec3(x, y, 1.0)

  let lptT = Tcl.NewListObj(2, nil)

  discard Tcl.ListObjAppendElement(interp, lptT, Tcl.NewDoubleObj(transformed.x))
  discard Tcl.ListObjAppendElement(interp, lptT, Tcl.NewDoubleObj(transformed.y))

  Tcl.SetObjResult(interp, lptT)

  return Tcl.OK

proc pix_identityMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a 3x3 identity matrix.
  #
  # Returns: The identity matrix as a Tcl list of 9 elements.
  if objc != 1:
    Tcl.WrongNumArgs(interp, 1, objv, "")
    return Tcl.ERROR

  Tcl.SetObjResult(interp, vmath.mat3().addToListObj())

  return Tcl.OK

proc pix_scaleMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a scaling matrix or multiplies an existing one.
  #
  # scale  - A Tcl list {x y} representing scale factor coordinates.
  # matrix - Optional Tcl list of 9 numbers representing an input 3x3 matrix (optional:identityMatrix).
  #
  # Returns: The scaled 3x3 matrix as a Tcl list of 9 elements.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "{x y} ?matrix?")
    return Tcl.ERROR

  var
    x, y: float32
    matrix3: vmath.Mat3

  if getListFloat(interp, objv[1], x, y, 
    "wrong # args: 'scale' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  if objc == 3:
    matrix3 = objv[2].getMtx()
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.scale(vec2(x, y))

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_transMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a translation matrix or multiplies an existing one.
  #
  # trans  - A Tcl list {x y} representing translation distance coordinates.
  # matrix - Optional Tcl list of 9 numbers representing an input 3x3 matrix (optional:identityMatrix).
  #
  # Returns: The translated 3x3 matrix as a Tcl list of 9 elements.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "{x y} ?matrix?")
    return Tcl.ERROR

  var
    x, y: float32
    matrix3: vmath.Mat3

  if getListFloat(interp, objv[1], x, y, 
    "wrong # args: 'translation' should be {x y}") != Tcl.OK:
    return Tcl.ERROR

  if objc == 3:
    matrix3 = objv[2].getMtx()
  else:
    matrix3 = vmath.mat3()

  matrix3 = matrix3 * vmath.translate(vec2(x, y))

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_mulMatrix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Multiplies a sequence of 3x3 matrices together.
  #
  # args - A variable list of matrices, where each matrix is a Tcl list of 9 numbers.
  #
  # Returns: The resulting multiplied matrix as a Tcl list of 9 elements.
  if objc < 3:
    Tcl.WrongNumArgs(interp, 1, objv, "matrix1 matrix2 ?matrix ...?")
    return Tcl.ERROR

  var lm: seq[vmath.Mat3]

  for c in 1..objc-1:
    lm.add(objv[c].getMtx())

  let matrix3 = lm.foldl(a * b)

  Tcl.SetObjResult(interp, matrix3.addToListObj())

  return Tcl.OK

proc pix_rgba*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates and returns a new RGBA color object.
  #
  # r - Integer value (0 to 255)
  # g - Integer value (0 to 255)
  # b - Integer value (0 to 255)
  # a - Double value (0.0 to 1.0)
  #
  # Returns: A string representation of the [color].
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "r g b a")
    return Tcl.ERROR

  let 
    r = objv[1].getInt()
    g = objv[2].getInt()
    b = objv[3].getInt()
    a = objv[4].getFloat()

  var color: Color

  color.r = min(1.0, r / 255)
  color.g = min(1.0, g / 255)
  color.b = min(1.0, b / 255)
  color.a = min(1.0, a)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_rgb*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates and returns a new RGB color object (alpha defaults to 1.0).
  #
  # r - Integer value (0 to 255)
  # g - Integer value (0 to 255)
  # b - Integer value (0 to 255)
  #
  # Returns: A string representation of the [color].
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "r g b")
    return Tcl.ERROR

  let 
    r = objv[1].getInt()
    g = objv[2].getInt()
    b = objv[3].getInt()

  var color: Color

  color.r = min(1.0, r / 255)
  color.g = min(1.0, g / 255)
  color.b = min(1.0, b / 255)
  color.a = 1.0

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_hexHTML*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates and returns a new hex HTML color object.
  #
  # hex - Hexadecimal color string (e.g., "#xxxxxx").
  #
  # Returns: A string representation of the [color].
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "#xxxxxx")
    return Tcl.ERROR

  let scolor = strip($objv[1])

  if not (isHexHtmlFormat(scolor) and isValidHex(scolor[1..^1])):
    return errorMSG(interp,
      "pix(error): '" & scolor & "' is not a valid hex html color."
    )

  let
    color = chroma.parseHtmlHex(scolor)
    obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
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
  # Returns: A string representation of the [color].
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "h s l")
    return Tcl.ERROR

  let 
    h = objv[1].getFloat()
    s = objv[2].getFloat()
    l = objv[3].getFloat()

  if h notin (0'f32..360'f32):
    return errorMSG(interp,
      "pix(error): 'hue' value must be between 0 and 360."
    )

  if s notin (0'f32..100'f32):
    return errorMSG(interp,
      "pix(error): 'saturation' value must be between 0 and 100."
    )

  if l notin (0'f32..100'f32):
    return errorMSG(interp,
      "pix(error): 'lightness' value must be between 0 and 100."
    )

  let hsl = hsl(h, s, l)
  let obj = pixObj.createColorObj(hsl.color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_nameColor*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new name color object.
  #
  # name  - HTML name
  #
  # Returns: A string representation of the [color].
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "name")
    return Tcl.ERROR

  let color = try:
    chroma.parseHtmlName(strip($objv[1]))
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDarken*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Darkens the color by amount 0-1.
  #
  # color   - A [color] string.
  # amount  - Double value (0-1)
  #
  # Returns: A string representation of the [color].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let amount = objv[2].getFloat()

  if amount notin (0'f32..1'f32):
    return errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = darken(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorLighten*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Lightens the color by amount 0-1.
  #
  # color   - A [color] string.
  # amount  - Double value (0-1)
  #
  # Returns: A string representation of the [color].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let amount = objv[2].getFloat()

  if amount notin (0'f32..1'f32):
    return errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = lighten(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDesaturate*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Desaturate (makes grayer) the color by amount 0-1.
  #
  # color   - A [color] string.
  # amount  - Double value (0-1)
  #
  # Returns: A string representation of the [color].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let amount = objv[2].getFloat()

  if amount notin (0'f32..1'f32):
    return errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = desaturate(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorSaturate*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Saturates (makes brighter) the color by amount 0-1.
  #
  # color   - A [color] string.
  # amount  - Double value (0-1)
  #
  # Returns: A string representation of the [color].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> amount")
    return Tcl.ERROR

  let colorObj = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let amount = objv[2].getFloat()

  if amount notin (0'f32..1'f32):
    return errorMSG(interp,
      "pix(error): 'amount' value must be between 0 and 1."
    )

  let color = saturate(colorObj, amount)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorSpin*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Rotates the hue of the color by degrees (0-360).
  #
  # color   - A [color] string.
  # degrees - Double value (0-360)
  #
  # Returns: Returns: A string representation of the [color].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color> degrees")
    return Tcl.ERROR

  let colorObj = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let degrees = objv[2].getFloat()

  if degrees notin (0'f32..360'f32):
    return errorMSG(interp,
      "pix(error): 'degrees' value must be between 0 and 360."
    )

  let color = spin(colorObj, degrees)
  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK

proc pix_colorDistance*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # A distance function based on CIEDE2000 color difference formula.
  #
  # color1   - A [color] string.
  # color2   - A [color] string.
  #
  # Returns: A distance.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2>")
    return Tcl.ERROR

  let color1 = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    objv[2].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let dist = distance(color1, color2)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(dist))

  return Tcl.OK

proc pix_colorAlmostEqual*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Almost equal colors.
  #
  # color1   - A [color] string.
  # color2   - A [color] string.
  # epsilon  - Double value (optional:0.01)
  #
  # Returns: True if colors are close.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2> ?epsilon?")
    return Tcl.ERROR

  let color1 = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    objv[2].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let equal =
    if objc == 4:
      let epsilon = objv[3].getFloat()
      almostEqual(color1, color2, epsilon)
    else:
      almostEqual(color1, color2)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(equal.cint))

  return Tcl.OK

proc pix_colorMix*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Mixes two colours using simple averaging or
  # simple lerp if the 'lerp' argument is specified.
  #
  # color1   - A [color] string.
  # color2   - A [color] string.
  # lerp     - Double value (optional)
  #
  # Returns: A string representation of the [color].
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<color1> <color2> ?lerp?")
    return Tcl.ERROR

  let color1 = try:
    objv[1].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let color2 = try:
    objv[2].getColor()
  except InvalidColor as e:
    return errorMSG(interp, "pix(error): " & e.msg)

  let color =
    if objc == 4:
      let lerp = objv[3].getFloat()
      mix(color1, color2, lerp)
    else:
      mix(color1, color2)

  let obj = pixObj.createColorObj(color)

  if obj.isNil:
    return errorMSG(interp,
      "pix(error): Failed to create color object."
    )

  Tcl.SetObjResult(interp, obj)

  return Tcl.OK