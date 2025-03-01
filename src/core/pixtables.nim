# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie, pixie/fileformats/svg
import std/tables

from ../bindings/tk/binding as Tk import ImageMaster

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

proc getMasterTable*(key: string): Tk.ImageMaster = 
  result = masterTable[key]

proc hasMasterTable*(key: string): bool = 
  result = masterTable.hasKey(key)
  
proc addMasterTable*(key: string, value: Tk.ImageMaster): void = 
  masterTable[key] = value

proc getContext*(key: string): pixie.Context = 
  result = ctxTable[key]

proc hasContext*(key: string): bool = 
  result = ctxTable.hasKey(key)

proc addContext*(key: string, value: pixie.Context): void = 
  ctxTable[key] = value

proc getFont*(key: string): pixie.Font = 
  result = fontTable[key]

proc hasFont*(key: string): bool = 
  result = fontTable.hasKey(key)

proc addFont*(key: string, value: pixie.Font): void = 
  fontTable[key] = value

proc getTFace*(key: string): pixie.Typeface = 
  result = tFaceTable[key]

proc hasTFace*(key: string): bool = 
  result = tFaceTable.hasKey(key)

proc addTFace*(key: string, value: pixie.Typeface): void = 
  tFaceTable[key]= value

proc getArr*(key: string): pixie.Arrangement = 
  result = arrTable[key]

proc hasArr*(key: string): bool = 
  result = arrTable.hasKey(key)

proc addArr*(key: string, value: pixie.Arrangement): void = 
  arrTable[key] = value

proc getPaint*(key: string): pixie.Paint = 
  result = paintTable[key]

proc hasPaint*(key: string): bool = 
  result = paintTable.hasKey(key)

proc addPaint*(key: string, value: pixie.Paint): void = 
  paintTable[key] = value

proc getPath*(key: string): pixie.Path = 
  result = pathTable[key]

proc hasPath*(key: string): bool = 
  result = pathTable.hasKey(key)

proc addPath*(key: string, value: pixie.Path): void = 
  pathTable[key] = value

proc getImage*(key: string): pixie.Image = 
  result = imgTable[key]

proc hasImage*(key: string): bool = 
  result = imgTable.hasKey(key)

proc addImage*(key: string, value: pixie.Image): void = 
  imgTable[key] = value

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