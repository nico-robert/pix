# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie, pixie/fileformats/svg
import std/tables

from ../bindings/tk/binding as Tk import ImageMaster
from ../bindings/tcl/binding as Tcl import PInterp, NewStringObj, SetObjResult, PObj, GetString, `$`

type
  PixTable* = ref object
    ctxTable*    : Table[string, pixie.Context]
    imgTable*    : Table[string, pixie.Image]
    pathTable*   : Table[string, pixie.Path]
    paintTable*  : Table[string, pixie.Paint]
    fontTable*   : Table[string, pixie.Font]
    tFaceTable*  : Table[string, pixie.Typeface]
    arrTable*    : Table[string, pixie.Arrangement]
    svgTable*    : Table[string, Svg]
    spanTable*   : Table[string, pixie.Span]
    masterTable* : Table[string, Tk.ImageMaster]

proc createPixTable*(): PixTable =
  result = PixTable()
  result.ctxTable     = initTable[string, pixie.Context]()
  result.imgTable     = initTable[string, pixie.Image]()
  result.pathTable    = initTable[string, pixie.Path]()
  result.paintTable   = initTable[string, pixie.Paint]()
  result.fontTable    = initTable[string, pixie.Font]()
  result.tFaceTable   = initTable[string, pixie.Typeface]()
  result.arrTable     = initTable[string, pixie.Arrangement]()
  result.svgTable     = initTable[string, Svg]()
  result.spanTable    = initTable[string, pixie.Span]()
  result.masterTable  = initTable[string, Tk.ImageMaster]()

# Context functions
proc getContext*(pTable: PixTable, key: string): pixie.Context = 
  result = pTable.ctxTable[key]

proc hasContext*(pTable: PixTable, key: string): bool = 
  result = pTable.ctxTable.hasKey(key)

proc addContext*(pTable: PixTable, key: string, value: pixie.Context): void = 
  pTable.ctxTable[key] = value

proc clearContext*(pTable: PixTable): void = 
  pTable.ctxTable.clear()

proc delKeyContext*(pTable: PixTable, key: string): void = 
  pTable.ctxTable.del(key)

proc loadContext*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Context =
# Searches the pixie.Context table for a key that matches the given obj.
#
# Returns:
# If found, it returns the associated pixie.Context object.
# If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasContext(key):
    let msg = "pix(error): unknown <ctx> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getContext(key)

# Image functions
proc getImage*(pTable: PixTable, key: string): pixie.Image = 
  result = pTable.imgTable[key]

proc hasImage*(pTable: PixTable, key: string): bool = 
  result = pTable.imgTable.hasKey(key)

proc addImage*(pTable: PixTable, key: string, value: pixie.Image): void = 
  pTable.imgTable[key] = value

proc clearImage*(pTable: PixTable): void = 
  pTable.imgTable.clear()

proc delKeyImage*(pTable: PixTable, key: string): void = 
  pTable.imgTable.del(key)

proc loadImage*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Image =
  # Searches the pixie.Image table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Image object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasImage(key):
    let msg = "pix(error): unknown <img> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getImage(key)

# Font functions
proc getFont*(pTable: PixTable, key: string): pixie.Font = 
  result = pTable.fontTable[key]

proc hasFont*(pTable: PixTable, key: string): bool = 
  result = pTable.fontTable.hasKey(key)

proc addFont*(pTable: PixTable, key: string, value: pixie.Font): void = 
  pTable.fontTable[key] = value

proc clearFont*(pTable: PixTable): void = 
  pTable.fontTable.clear()

proc delKeyFont*(pTable: PixTable, key: string): void = 
  pTable.fontTable.del(key)

proc loadFont*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Font =
  # Searches the pixie.Font table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Font object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasFont(key):
    let msg = "pix(error): unknown <font> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getFont(key)

# Paint functions
proc getPaint*(pTable: PixTable, key: string): pixie.Paint = 
  result = pTable.paintTable[key]

proc hasPaint*(pTable: PixTable, key: string): bool = 
  result = pTable.paintTable.hasKey(key)

proc addPaint*(pTable: PixTable, key: string, value: pixie.Paint): void = 
  pTable.paintTable[key] = value

proc clearPaint*(pTable: PixTable): void = 
  pTable.paintTable.clear()

proc delKeyPaint*(pTable: PixTable, key: string): void = 
  pTable.paintTable.del(key)

proc loadPaint*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Paint =
  # Searches the pixie.Paint table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Paint object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasPaint(key):
    let msg = "pix(error): unknown <paint> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getPaint(key)

# Path functions
proc getPath*(pTable: PixTable, key: string): pixie.Path = 
  result = pTable.pathTable[key]

proc hasPath*(pTable: PixTable, key: string): bool = 
  result = pTable.pathTable.hasKey(key)

proc addPath*(pTable: PixTable, key: string, value: pixie.Path): void = 
  pTable.pathTable[key] = value

proc clearPath*(pTable: PixTable): void = 
  pTable.pathTable.clear()

proc delKeyPath*(pTable: PixTable, key: string): void = 
  pTable.pathTable.del(key)

proc loadPath*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Path =
  # Searches the pixie.Path table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Path object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasPath(key):
    let msg = "pix(error): unknown <path> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getPath(key)

# Typeface functions
proc getTFace*(pTable: PixTable, key: string): pixie.Typeface = 
  result = pTable.tFaceTable[key]

proc hasTFace*(pTable: PixTable, key: string): bool = 
  result = pTable.tFaceTable.hasKey(key)

proc addTFace*(pTable: PixTable, key: string, value: pixie.Typeface): void = 
  pTable.tFaceTable[key] = value

proc loadTFace*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Typeface =
  # Searches the pixie.Typeface table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Typeface object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasTFace(key):
    let msg = "pix(error): unknown <TypeFace> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getTFace(key)

# Arrangement functions
proc getArr*(pTable: PixTable, key: string): pixie.Arrangement = 
  result = pTable.arrTable[key]

proc hasArr*(pTable: PixTable, key: string): bool = 
  result = pTable.arrTable.hasKey(key)

proc addArr*(pTable: PixTable, key: string, value: pixie.Arrangement): void = 
  pTable.arrTable[key] = value

proc loadArr*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): pixie.Arrangement =
  # Searches the pixie.Arrangement table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated pixie.Arrangement object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasArr(key):
    let msg = "pix(error): unknown <Arrangement> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getArr(key)

# SVG functions
proc getSVG*(pTable: PixTable, key: string): Svg = 
  result = pTable.svgTable[key]

proc hasSVG*(pTable: PixTable, key: string): bool = 
  result = pTable.svgTable.hasKey(key)

proc addSVG*(pTable: PixTable, key: string, value: Svg): void = 
  pTable.svgTable[key] = value

proc clearSVG*(pTable: PixTable): void = 
  pTable.svgTable.clear()

proc delKeySVG*(pTable: PixTable, key: string): void = 
  pTable.svgTable.del(key)

proc loadSVG*(pTable: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj): Svg =
  # Searches the Svg table for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated Svg object.
  # If not found, it sets an error message on the given interp and returns nil.

  let key = $obj

  if not pTable.hasSVG(key):
    let msg = "pix(error): unknown <svg> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    # We return nil to indicate that an error occurred.
    return nil

  return pTable.getSVG(key)

# Master table functions
proc getMasterTable*(pTable: PixTable, key: string): Tk.ImageMaster = 
  result = pTable.masterTable[key]

proc hasMasterTable*(pTable: PixTable, key: string): bool = 
  result = pTable.masterTable.hasKey(key)

proc addMasterTable*(pTable: PixTable, key: string, value: Tk.ImageMaster): void = 
  pTable.masterTable[key] = value

# Span functions
proc getSpan*(pTable: PixTable, key: string): pixie.Span = 
  result = pTable.spanTable[key]

proc hasSpan*(pTable: PixTable, key: string): bool = 
  result = pTable.spanTable.hasKey(key)

proc addSpan*(pTable: PixTable, key: string, value: pixie.Span): void = 
  pTable.spanTable[key] = value