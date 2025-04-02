# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import ./pixutils as pixUtils
import std/strutils
import ../bindings/tcl/binding as Tcl

type
  RenderOptions* = object
    strokeWidth*: cdouble = 1.0
    transform*: Mat3 = mat3()
    lineCap*: LineCap = ButtCap
    lineJoin*: LineJoin = MiterJoin
    miterLimit*: cdouble = pixie.defaultMiterLimit
    dashes*: seq[float32] = @[]
    hAlign*: HorizontalAlignment = LeftAlign
    vAlign*: VerticalAlignment = TopAlign
    bounds*: Vec2 = vec2(0, 0)
    wrap*: bool = true

  RenderShadow* = object
    blur*: cdouble   = 1.0
    spread*: cdouble = 1.0
    offset*: Vec2    = vec2(0, 0)
    color*: Color    = color(0, 0, 0, 0)

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
    return pixUtils.errorMSG(interp, errorMsg)

  if Tcl.GetIntFromObj(interp, elements[0], v1) != Tcl.OK or
     Tcl.GetIntFromObj(interp, elements[1], v2) != Tcl.OK: 
    return Tcl.ERROR

  # Return success.
  return Tcl.OK

proc getListDouble*(interp: Tcl.PInterp, objv: Tcl.PObj, v1, v2: var cdouble, errorMsg: string): cint =
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
    return pixUtils.errorMSG(interp, errorMsg)

  if Tcl.GetDoubleFromObj(interp, elements[0], v1) != Tcl.OK or
     Tcl.GetDoubleFromObj(interp, elements[1], v2) != Tcl.OK: 
    return Tcl.ERROR

  # Return success.
  return Tcl.OK

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
    x, y: cdouble

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError,
    "wrong # args: 'dict options' should be :key value ?key1 ?value1 ..."
    )

  for i in countup(0, count - 1, 2):
    let 
      key = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case key:
      of "blur":
        if Tcl.GetDoubleFromObj(interp, value, opts.blur) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "spread":
        if Tcl.GetDoubleFromObj(interp, value, opts.spread) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "offset":
        if getListDouble(interp, value, x, y, 
          "wrong # args: 'offset' should be 'x' 'y'") != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        opts.offset = vec2(x, y)
      of "color":
        try:
          opts.color = pixUtils.getColor(value)
        except InvalidColor as e:
          raise newException(ValueError, move(e.msg))
      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")

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
    dashes: cdouble

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError,
    "wrong # args: 'dict options' should be :key value ?key1 ?value1 ..."
    )

  for i in countup(0, count - 1, 2):
    let 
      key = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case key:
      of "strokeWidth":
        if Tcl.GetDoubleFromObj(interp, value, opts.strokeWidth) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "transform":
        if pixUtils.matrix3x3(interp, value, opts.transform) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "lineCap":
        try:
          opts.lineCap = parseEnum[LineCap]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "miterLimit":
        if Tcl.GetDoubleFromObj(interp, value, opts.miterLimit) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "lineJoin":
        try:
          opts.lineJoin = parseEnum[LineJoin]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        for j in 0..dashescount-1:
          if Tcl.GetDoubleFromObj(interp, dasheselements[j], dashes) != Tcl.OK:
            raise newException(ValueError, $Tcl.GetStringResult(interp))
          opts.dashes.add(dashes)

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
    x, y, dashes: cdouble

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError,
    "wrong # args: 'font options' should be :key value ?key1 ?value1 ..."
    )

  for i in countup(0, count - 1, 2):
    let 
      key = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case key:
      of "strokeWidth":
        if Tcl.GetDoubleFromObj(interp, value, opts.strokeWidth) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "transform":
        if pixUtils.matrix3x3(interp, value, opts.transform) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "miterLimit":
        if Tcl.GetDoubleFromObj(interp, value, opts.miterLimit) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "hAlign":
        try:
          opts.hAlign = parseEnum[HorizontalAlignment]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "vAlign":
        try:
          opts.vAlign = parseEnum[VerticalAlignment]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "lineCap":
        try:
          opts.lineCap = parseEnum[LineCap]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "lineJoin":
        try:
          opts.lineJoin = parseEnum[LineJoin]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        for j in 0..dashescount-1:
          if Tcl.GetDoubleFromObj(interp, dasheselements[j], dashes) != Tcl.OK:
            raise newException(ValueError, $Tcl.GetStringResult(interp))
          opts.dashes.add(dashes)

        # To get around pixie's problem when my list is not even, 
        # because pixie uses 'dashes.add(dashes)' which is not allowed.
        # With -d:useMalloc enabled, I have an error in particular on MacOs.
        if opts.dashes.len mod 2 != 0:
          var copyOfDashes = opts.dashes
          opts.dashes.add(copyOfDashes)

      of "bounds":
        if getListDouble(interp, value, x, y, 
          "wrong # args: 'bounds' should be 'x' 'y'") != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")

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
    x, y: cdouble
    wrapB: int

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError,
    "wrong # args: 'dict options' should be :key value ?key1 ?value1 ..."
    )

  for i in countup(0, count - 1, 2):
    let
      key = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case key:
      of "wrap":
        if Tcl.GetBooleanFromObj(interp, value, wrapB) != Tcl.OK: 
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        opts.wrap = wrapB.bool
      of "hAlign":
        try:
          opts.hAlign = parseEnum[HorizontalAlignment]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "vAlign":
        try:
          opts.vAlign = parseEnum[VerticalAlignment]($Tcl.GetString(value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "bounds":
        if getListDouble(interp, value, x, y, 
          "wrong # args: 'bounds' should be 'x' 'y'") != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError,
        "wrong # args: Key '" & key & "' not supported."
        )
