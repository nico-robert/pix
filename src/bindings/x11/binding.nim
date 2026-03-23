# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

import ./types as X
export X

type TkIntXlibStubs {.importc.} = object
  xCreateImage    : proc(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage {.cdecl.}
  xCreateGC       : proc(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC {.cdecl.}
  xPutImage       : proc(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint {.cdecl.}
  xFlush          : proc(display: ptr X.Display): cint {.cdecl.}
  xSetBackground  : proc(display: ptr X.Display, gc: X.GC, bg: culong): cint {.cdecl.}
  xSetForeground  : proc(display: ptr X.Display, gc: X.GC, fg: culong): cint {.cdecl.}
  xCopyArea       : proc(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint {.cdecl.}
  xFillRectangle  : proc(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint {.cdecl.}
  xSetClipMask    : proc(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint {.cdecl.}
  tkPutImage      : proc(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: ptr XImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint {.cdecl.}

var tkIntXlibStubsPtr {.importc: "tkIntXlibStubsPtr", header: "tkIntXlibDecls.h".}: ptr TkIntXlibStubs

proc CreateImage*(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage =
  return tkIntXlibStubsPtr.xCreateImage(display, v, ui1, i1, i2, cp, ui2, ui3, i3, i4)

proc CreateGC*(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC =
  return tkIntXlibStubsPtr.xCreateGC(display, d, valueMask, valuePtr)

proc PutImage*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint =
  return tkIntXlibStubsPtr.xPutImage(display, dr, gc, im, sx, sy, dx, dy, w, h)

proc Flush*(display: ptr X.Display): cint =
  return tkIntXlibStubsPtr.xFlush(display)

proc SetBackground*(display: ptr X.Display, gc: X.GC, bg: culong): cint =
  return tkIntXlibStubsPtr.xSetBackground(display, gc, bg)

proc SetForeground*(display: ptr X.Display, gc: X.GC, fg: culong): cint =
  return tkIntXlibStubsPtr.xSetForeground(display, gc, fg)

proc CopyArea*(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint =
  return tkIntXlibStubsPtr.xCopyArea(display, dr1, dr2, gc, i1, i2, ui1, ui2, i3, i4)

proc FillRectangle*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint =
  return tkIntXlibStubsPtr.xFillRectangle(display, dr, gc, x, y, width, height)

proc SetClipMask*(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint =
  return tkIntXlibStubsPtr.xSetClipMask(display, gc, pixmap)

proc TkPutImage*(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: ptr XImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint =
  return tkIntXlibStubsPtr.tkPutImage(colors, ncolors, display, d, gc, image, src_x, src_y, dest_x, dest_y, width, height)