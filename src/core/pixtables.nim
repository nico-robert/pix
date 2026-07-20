# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie, pixie/fileformats/svg
import std/tables

when defined(resvg): import ../bindings/resvg/types
when defined(pixGL): import boxy

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
    when defined(pixGL):
      boxyTable*   : Table[string, Boxy]
    when defined(resvg):
      resvgTable*  : Table[string, Resvg]

proc createPixTable*(): PixTable =
  result = PixTable()

#'tbl' selects the underlying table for a given type,
proc tbl(pt: PixTable, T: typedesc[pixie.Context]): var Table[string, pixie.Context] = pt.ctxTable
proc tbl(pt: PixTable, T: typedesc[pixie.Image]): var Table[string, pixie.Image] = pt.imgTable
proc tbl(pt: PixTable, T: typedesc[pixie.Path]): var Table[string, pixie.Path] = pt.pathTable
proc tbl(pt: PixTable, T: typedesc[pixie.Paint]): var Table[string, pixie.Paint] = pt.paintTable
proc tbl(pt: PixTable, T: typedesc[pixie.Font]): var Table[string, pixie.Font] = pt.fontTable
proc tbl(pt: PixTable, T: typedesc[pixie.Typeface]): var Table[string, pixie.Typeface] = pt.tFaceTable
proc tbl(pt: PixTable, T: typedesc[pixie.Arrangement]): var Table[string, pixie.Arrangement] = pt.arrTable
proc tbl(pt: PixTable, T: typedesc[Svg]): var Table[string, Svg] = pt.svgTable
proc tbl(pt: PixTable, T: typedesc[pixie.Span]): var Table[string, pixie.Span] = pt.spanTable

# 'label' provides the tag used in error messages.
proc label(T: typedesc[pixie.Context]): string     = "Context"
proc label(T: typedesc[pixie.Image]): string       = "Image"
proc label(T: typedesc[pixie.Path]): string        = "Path"
proc label(T: typedesc[pixie.Paint]): string       = "Paint"
proc label(T: typedesc[pixie.Font]): string        = "Font"
proc label(T: typedesc[pixie.Typeface]): string    = "TypeFace"
proc label(T: typedesc[pixie.Arrangement]): string = "Arrangement"
proc label(T: typedesc[Svg]): string               = "Svg"
proc label(T: typedesc[pixie.Span]): string        = "Span"

when defined(pixGL):
  proc tbl(pt: PixTable, T: typedesc[Boxy]): var Table[string, Boxy] = pt.boxyTable
  proc label(T: typedesc[Boxy]): string = "Boxy"

when defined(resvg):
  proc tbl(pt: PixTable, T: typedesc[Resvg]): var Table[string, Resvg] = pt.resvgTable
  proc label(T: typedesc[Resvg]): string = "Resvg"

# Generic operations, written once for all types.
proc get*(pt: PixTable, key: string, T: typedesc): T =
  result = pt.tbl(T)[key]

proc has*(pt: PixTable, key: string, T: typedesc): bool =
  result = pt.tbl(T).hasKey(key)

proc add*[T](pt: PixTable, key: string, value: T) =
  pt.tbl(T)[key] = value

proc clear*(pt: PixTable, T: typedesc) =
  pt.tbl(T).clear()

proc delKey*(pt: PixTable, key: string, T: typedesc) =
  pt.tbl(T).del(key)

proc load*(pt: PixTable, interp: Tcl.PInterp, obj: Tcl.PObj, T: typedesc): T =
  # Searches the table associated with T for a key that matches the given obj.
  #
  # Returns:
  # If found, it returns the associated object.
  # If not found, it sets an error message on the given interp and returns nil.
  let key = $obj

  if not pt.tbl(T).hasKey(key):
    let msg = "pix(error): unknown <" & label(T) & "> key object found: '" & key & "'."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(msg.cstring, -1))
    return nil

  return pt.tbl(T)[key]