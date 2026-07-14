# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import ./types as X
export X

const useTkXlibStubs = defined(windows) or defined(macosx)

when useTkXlibStubs:
  const xlibHeader = "tkIntXlibDecls.h"
else:
  const xlibHeader = "X11/Xlib.h"

proc CreateImage*(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage
  {.cdecl, importc: "XCreateImage", header: xlibHeader.}

proc CreateGC*(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC
  {.cdecl, importc: "XCreateGC", header: xlibHeader.}

proc PutImage*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint
  {.cdecl, importc: "XPutImage", header: xlibHeader.}

proc Flush*(display: ptr X.Display): cint
  {.cdecl, importc: "XFlush", header: xlibHeader.}

proc SetBackground*(display: ptr X.Display, gc: X.GC, bg: culong): cint
  {.cdecl, importc: "XSetBackground", header: xlibHeader.}

proc SetForeground*(display: ptr X.Display, gc: X.GC, fg: culong): cint
  {.cdecl, importc: "XSetForeground", header: xlibHeader.}

proc CopyArea*(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint
  {.cdecl, importc: "XCopyArea", header: xlibHeader.}

proc FillRectangle*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint
  {.cdecl, importc: "XFillRectangle", header: xlibHeader.}

proc SetClipMask*(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint
  {.cdecl, importc: "XSetClipMask", header: xlibHeader.}

when useTkXlibStubs:
  proc TkPutImage*(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: X.PXImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint
    {.cdecl, importc: "TkPutImage", header: xlibHeader.}
else:
  proc TkPutImage*(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: X.PXImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint =
    return PutImage(display, d, gc, image, src_x, src_y, dest_x, dest_y, width, height)