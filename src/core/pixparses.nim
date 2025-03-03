# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie
import ./pixutils as pixUtils
import std/strutils

from ../bindings/tcl/binding as Tcl import nil

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
    blur*: cdouble = 1.0
    spread*: cdouble = 1.0
    offset*: Vec2 = vec2(0, 0)
    color*: Color = color(0, 0, 0, 0)

proc shadowOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderShadow) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderShadow' object.
  #
  #  interp - interpreter.
  #  objv   - object options .
  #  opts   - RenderShadow object to populate.
  #
  # Returns nothing or an exception if an error is found.
  var
    count, veccount: Tcl.Size
    elements, vecelements: Tcl.PPObj
    x, y: cdouble
  
  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

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
        if Tcl.ListObjGetElements(interp, value, veccount, vecelements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if veccount != 2:
          raise newException(ValueError, "wrong # args: 'offset' should be 'x' 'y'")

        if Tcl.GetDoubleFromObj(interp, vecelements[0], x) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if Tcl.GetDoubleFromObj(interp, vecelements[1], y) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        opts.offset = vec2(x, y)
      of "color":
          opts.color = pixUtils.getColor(value)
      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")


proc dictOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options .
  #  opts   - RenderOptions object to populate.
  #
  # Returns nothing or an exception if an error is found.
  var
    count, dashescount: Tcl.Size
    elements, dasheselements: Tcl.PPObj
    dashes: cdouble
  
  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

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
        opts.lineCap = parseEnum[LineCap]($Tcl.GetString(value))
      of "miterLimit":
        if Tcl.GetDoubleFromObj(interp, value, opts.miterLimit) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
      of "lineJoin":
        opts.lineJoin = parseEnum[LineJoin]($Tcl.GetString(value))
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        for j in 0..dashescount-1:
          if Tcl.GetDoubleFromObj(interp, dasheselements[j], dashes) != Tcl.OK:
            raise newException(ValueError, $Tcl.GetStringResult(interp))
          opts.dashes.add(dashes)

      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")

proc fontOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options .
  #  opts   - RenderOptions object to populate.
  #
  # Returns nothing or an exception if an error is found.
  var
    count, veccount, dashescount: Tcl.Size
    elements, vecelements, dasheselements: Tcl.PPObj
    x, y, dashes: cdouble
  
  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError, "wrong # args: 'font options' should be :key value ?key1 ?value1 ...")

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
        opts.hAlign = parseEnum[HorizontalAlignment]($Tcl.GetString(value))
      of "vAlign":
        opts.vAlign = parseEnum[VerticalAlignment]($Tcl.GetString(value))
      of "lineCap":
        opts.lineCap = parseEnum[LineCap]($Tcl.GetString(value))
      of "lineJoin":
        opts.lineJoin = parseEnum[LineJoin]($Tcl.GetString(value))
      of "dashes":
        if Tcl.ListObjGetElements(interp, value, dashescount, dasheselements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        for j in 0..dashescount-1:
          if Tcl.GetDoubleFromObj(interp, dasheselements[j], dashes) != Tcl.OK:
            raise newException(ValueError, $Tcl.GetStringResult(interp))
          opts.dashes.add(dashes)

      of "bounds":
        if Tcl.ListObjGetElements(interp, value, veccount, vecelements) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if veccount != 2:
          raise newException(ValueError, "wrong # args: 'bounds' should be 'x' 'y'")

        if Tcl.GetDoubleFromObj(interp, vecelements[0], x) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if Tcl.GetDoubleFromObj(interp, vecelements[1], y) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")

proc typeSetOptions*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderOptions) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderOptions' object.
  #
  #  interp - interpreter.
  #  objv   - object options .
  #  opts   - RenderOptions object to populate.
  #
  # Returns nothing or an exception if an error is found.
  var
    count, veccount: Tcl.Size
    elements, vecelements: Tcl.PPObj
    x, y: cdouble
    wrapB: int

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $Tcl.GetStringResult(interp))

  if count mod 2 != 0:
    raise newException(ValueError, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

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
        opts.hAlign = parseEnum[HorizontalAlignment]($Tcl.GetString(value))
      of "vAlign":
        opts.vAlign = parseEnum[VerticalAlignment]($Tcl.GetString(value))
      of "bounds":
        if Tcl.ListObjGetElements(interp, value, veccount, vecelements) != Tcl.OK: 
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if veccount != 2:
          raise newException(ValueError, "wrong # args: 'bounds' should be 'x' 'y'")

        if Tcl.GetDoubleFromObj(interp, vecelements[0], x) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))
        if Tcl.GetDoubleFromObj(interp, vecelements[1], y) != Tcl.OK:
          raise newException(ValueError, $Tcl.GetStringResult(interp))

        opts.bounds = vec2(x, y)
      else:
        raise newException(ValueError, "wrong # args: Key '" & key & "' not supported.")
