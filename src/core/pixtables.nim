# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
import pixie, pixie/fileformats/svg
import std/tables

var ctxTable*   = initTable[string, pixie.Context]()
var imgTable*   = initTable[string, pixie.Image]()
var pathTable*  = initTable[string, pixie.Path]()
var paintTable* = initTable[string, pixie.Paint]()
var fontTable*  = initTable[string, pixie.Font]()
var tFaceTable* = initTable[string, pixie.Typeface]()
var arrTable*   = initTable[string, pixie.Arrangement]()
var svgTable*   = initTable[string, Svg]()
var spanTable*  = initTable[string, pixie.Span]()

proc getContext*(name: string): pixie.Context =
  return ctxTable[name]

proc hasContext*(name: string): bool =
  return ctxTable.hasKey(name)

proc getImage*(name: string): pixie.Image =
  return imgTable[name]
  
proc hasImage*(name: string): bool =
  return imgTable.hasKey(name)