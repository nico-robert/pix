# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

import ./types as X
export X

const useTkXlibStubs = defined(windows) or defined(macosx)

when useTkXlibStubs:

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

else:
  proc XCreateImage(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage {.importc: "XCreateImage", header: "X11/Xlib.h".}
  proc XCreateGC(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC {.importc: "XCreateGC", header: "X11/Xlib.h".}
  proc XPutImage(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint {.importc: "XPutImage", header: "X11/Xlib.h".}
  proc XFlush(display: ptr X.Display): cint {.importc: "XFlush", header: "X11/Xlib.h".}
  proc XSetBackground(display: ptr X.Display, gc: X.GC, bg: culong): cint {.importc: "XSetBackground", header: "X11/Xlib.h".}
  proc XSetForeground(display: ptr X.Display, gc: X.GC, fg: culong): cint {.importc: "XSetForeground", header: "X11/Xlib.h".}
  proc XCopyArea(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint {.importc: "XCopyArea", header: "X11/Xlib.h".}
  proc XFillRectangle(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint {.importc: "XFillRectangle", header: "X11/Xlib.h".}
  proc XSetClipMask(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint {.importc: "XSetClipMask", header: "X11/Xlib.h".}

proc CreateImage*(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xCreateImage(display, v, ui1, i1, i2, cp, ui2, ui3, i3, i4)
  else:
    return XCreateImage(display, v, ui1, i1, i2, cp, ui2, ui3, i3, i4)

proc CreateGC*(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xCreateGC(display, d, valueMask, valuePtr)
  else:
    return XCreateGC(display, d, valueMask, valuePtr)

proc PutImage*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xPutImage(display, dr, gc, im, sx, sy, dx, dy, w, h)
  else:
    return XPutImage(display, dr, gc, im, sx, sy, dx, dy, w, h)

proc Flush*(display: ptr X.Display): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xFlush(display)
  else:
    return XFlush(display)

proc SetBackground*(display: ptr X.Display, gc: X.GC, bg: culong): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xSetBackground(display, gc, bg)
  else:
    return XSetBackground(display, gc, bg)

proc SetForeground*(display: ptr X.Display, gc: X.GC, fg: culong): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xSetForeground(display, gc, fg)
  else:
    return XSetForeground(display, gc, fg)

proc CopyArea*(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xCopyArea(display, dr1, dr2, gc, i1, i2, ui1, ui2, i3, i4)
  else:
    return XCopyArea(display, dr1, dr2, gc, i1, i2, ui1, ui2, i3, i4)

proc FillRectangle*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xFillRectangle(display, dr, gc, x, y, width, height)
  else:
    return XFillRectangle(display, dr, gc, x, y, width, height)

proc SetClipMask*(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.xSetClipMask(display, gc, pixmap)
  else:
    return XSetClipMask(display, gc, pixmap)

proc TkPutImage*(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: ptr XImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint =
  when useTkXlibStubs:
    return tkIntXlibStubsPtr.tkPutImage(colors, ncolors, display, d, gc, image, src_x, src_y, dest_x, dest_y, width, height)
  else:
    return XPutImage(display, d, gc, image, src_x, src_y, dest_x, dest_y, width, height)