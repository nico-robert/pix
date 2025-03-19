# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie, pixie/fileformats/svg
import std/tables

from ../bindings/tk/binding  as Tk import ImageMaster
from ../bindings/tcl/binding as Tcl import PInterp, NewStringObj, SetObjResult, PObj

var 
  ctxTable*    = initTable[string, pixie.Context]()
  imgTable*    = initTable[string, pixie.Image]()
  pathTable*   = initTable[string, pixie.Path]()
  paintTable*  = initTable[string, pixie.Paint]()
  fontTable*   = initTable[string, pixie.Font]()
  tFaceTable*  = initTable[string, pixie.Typeface]()
  arrTable*    = initTable[string, pixie.Arrangement]()
  svgTable*    = initTable[string, Svg]()
  spanTable*   = initTable[string, pixie.Span]()
  masterTable* = initTable[string, Tk.ImageMaster]()

# getXXX = Returns the object associated with the given key.
# hasXXX = Returns true if the table has the given key false otherwise.
# addXXX = Adds the given object to the table with the given key.

proc getContext*(key: string): pixie.Context = 
  result = ctxTable[key]

proc hasContext*(key: string): bool = 
  result = ctxTable.hasKey(key)

proc addContext*(key: string, value: pixie.Context): void = 
  ctxTable[key] = value

proc loadContext*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Context =
# Searches the pixie.Context table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Context object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasContext(key):
    let msg = cstring("pix(error): unknown <ctx> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getContext(key)

proc getImage*(key: string): pixie.Image = 
  result = imgTable[key]

proc hasImage*(key: string): bool = 
  result = imgTable.hasKey(key)

proc addImage*(key: string, value: pixie.Image): void = 
  imgTable[key] = value

proc loadImage*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Image =
# Searches the pixie.Image table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Image object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasImage(key):
    let msg = cstring("pix(error): unknown <img> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getImage(key)

proc getFont*(key: string): pixie.Font = 
  result = fontTable[key]

proc hasFont*(key: string): bool = 
  result = fontTable.hasKey(key)

proc addFont*(key: string, value: pixie.Font): void = 
  fontTable[key] = value

proc loadFont*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Font =
# Searches the pixie.Font table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Font object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasFont(key):
    let msg = cstring("pix(error): unknown <font> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getFont(key)

proc getPaint*(key: string): pixie.Paint = 
  result = paintTable[key]

proc hasPaint*(key: string): bool = 
  result = paintTable.hasKey(key)

proc addPaint*(key: string, value: pixie.Paint): void = 
  paintTable[key] = value

proc loadPaint*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Paint =
# Searches the pixie.Paint table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Paint object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasPaint(key):
    let msg = cstring("pix(error): unknown <paint> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getPaint(key)

proc getPath*(key: string): pixie.Path = 
  result = pathTable[key]

proc hasPath*(key: string): bool = 
  result = pathTable.hasKey(key)

proc addPath*(key: string, value: pixie.Path): void = 
  pathTable[key] = value

proc loadPath*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Path =
# Searches the pixie.Path table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Path object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasPath(key):
    let msg = cstring("pix(error): unknown <path> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getPath(key)

proc getTFace*(key: string): pixie.Typeface = 
  result = tFaceTable[key]

proc hasTFace*(key: string): bool = 
  result = tFaceTable.hasKey(key)

proc addTFace*(key: string, value: pixie.Typeface): void = 
  tFaceTable[key]= value

proc loadTFace*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Typeface =
# Searches the pixie.Typeface table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Typeface object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasTFace(key):
    let msg = cstring("pix(error): unknown <TypeFace> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getTFace(key)

proc getArr*(key: string): pixie.Arrangement = 
  result = arrTable[key]

proc hasArr*(key: string): bool = 
  result = arrTable.hasKey(key)

proc addArr*(key: string, value: pixie.Arrangement): void = 
  arrTable[key] = value

proc loadArr*(interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Arrangement =
# Searches the pixie.Arrangement table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Arrangement object.
# If not found, it sets an error message on the given interp and returns nil.
  let key = $Tcl.GetString(obj)

  if not hasArr(key):
    let msg = cstring("pix(error): unknown <Arrangement> key object found: '" & key & "'.")
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return getArr(key)

proc getMasterTable*(key: string): Tk.ImageMaster = 
  result = masterTable[key]

proc hasMasterTable*(key: string): bool = 
  result = masterTable.hasKey(key)
  
proc addMasterTable*(key: string, value: Tk.ImageMaster): void = 
  masterTable[key] = value

proc getSVG*(key: string): Svg = 
  result = svgTable[key]

proc hasSVG*(key: string): bool = 
  result = svgTable.hasKey(key)

proc addSVG*(key: string, value: Svg): void = 
  svgTable[key] = value

proc getSpan*(key: string): pixie.Span = 
  result = spanTable[key]

proc hasSpan*(key: string): bool = 
  result = spanTable.hasKey(key)

proc addSpan*(key: string, value: pixie.Span): void = 
  spanTable[key] = value