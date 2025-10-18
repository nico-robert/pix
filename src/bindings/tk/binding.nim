# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

when defined(x11):
  import ../x11/xtypes as X

import ../tcl/binding as Tcl

include "private/tktypes.inc"

when defined(x11):
  type
    # Image types.
    ImageType* = object
      name*           : cstring
      createProc*     : proc(interp: Tcl.PInterp, imageName: cstring, objc: cint, objv: Tcl.PPObj, typePtr: ptr ImageType, masterPtr: ImageMaster, clientDataPtr: Tcl.PClientData): cint {.cdecl.}
      getProc*        : proc(tkwin: Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.}
      displayProc*    : proc(instanceData: Tcl.TClientData, display: ptr X.Display, drawable: X.Drawable, imageX: cint, imageY: cint, width: cint, height: cint, drawableX: cint, drawableY: cint) {.cdecl.}
      freeProc*       : proc(instanceData: Tcl.TClientData, display: ptr X.Display) {.cdecl.}
      deleteProc*     : proc(instanceData: Tcl.TClientData) {.cdecl.}

type 
  TkStubs {.importc.} = object
    tk_FindPhoto       : proc(interp: Tcl.PInterp, imageName: cstring): PhotoHandle {.cdecl.}
    tk_PhotoPutBlock   : proc(interp: Tcl.PInterp, handle: PhotoHandle, blockPtr: ptr PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: cint): cint {.cdecl.}
    tk_PhotoSetSize    : proc(interp: Tcl.PInterp, handle: PhotoHandle, width: cint, height: cint): cint {.cdecl.}
    tk_DisplayName     : proc(tkwin: Window): cstring {.cdecl.}
    when defined(x11):
      tk_GetColor          : proc(interp: Tcl.PInterp, tkwin: Window, name: cstring): X.Color {.cdecl.}
      tk_GetOption         : proc(tkwin: Window, name: cstring, className: cstring): Uid {.cdecl.}
      tk_FreeGC            : proc(display: ptr X.Display, gc: X.GC) {.cdecl.}
      tk_GetPixmap         : proc(display: ptr X.Display, d: X.Drawable, width: cint, height: cint, depth: cint): Pixmap {.cdecl.}
      tk_FreePixmap        : proc(display: ptr X.Display, pixmap: Pixmap) {.cdecl.}
      tk_CreateImageType   : proc(typePtr: ptr ImageType) {.cdecl.}
      tk_GetGC             : proc(tkwin: Window, valueMask: culong, valuePtr: var X.GCValues): X.GC {.cdecl.}
      tk_ImageChanged      : proc(imageMaster: ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint) {.cdecl.}
      tk_NameOfImage       : proc(imageMaster: ImageMaster): cstring {.cdecl.}
      when defined(tcl9):
        tk_GetImageModelData  : proc(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ImageType): Tcl.TClientData {.cdecl.}
      else:
        tk_GetImageMasterData : proc(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ImageType): Tcl.TClientData {.cdecl.}

var tkStubsPtr {.importc: "tkStubsPtr", header: "tkDecls.h".} : ptr TkStubs

proc FindPhoto*(interp: Tcl.PInterp, imageName: cstring): PhotoHandle =
  return tkStubsPtr.tk_FindPhoto(interp, imageName)

proc PhotoPutBlock*(interp: Tcl.PInterp, handle: PhotoHandle, blockPtr: ptr PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: cint): cint =
  return tkStubsPtr.tk_PhotoPutBlock(interp, handle, blockPtr, x, y, width, height, compRule)

proc PhotoSetSize*(interp: Tcl.PInterp, handle: PhotoHandle, width: cint, height: cint): cint =
  return tkStubsPtr.tk_PhotoSetSize(interp, handle, width, height)

proc DisplayName*(tkwin: Window): cstring =
  return tkStubsPtr.tk_DisplayName(tkwin)

proc Depth*   (tkwin: Window): cint   {.cdecl, importc: "Tk_Depth", header: "tk.h".}
proc WindowId*(tkwin: Window): culong {.cdecl, importc: "Tk_WindowId", header: "tk.h".}
proc Parent*  (tkwin: Window): Window {.cdecl, importc: "Tk_Parent", header: "tk.h".}

when defined(x11):

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

  proc XCreateImage*(display: ptr X.Display, v: ptr X.Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): X.PXImage =
    return tkIntXlibStubsPtr.xCreateImage(display, v, ui1, i1, i2, cp, ui2, ui3, i3, i4)

  proc XCreateGC*(display: ptr X.Display, d: X.Drawable, valueMask: culong, valuePtr: var X.GCValues): X.GC =
    return tkIntXlibStubsPtr.xCreateGC(display, d, valueMask, valuePtr)

  proc XPutImage*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, im: X.PXImage, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint =
    return tkIntXlibStubsPtr.xPutImage(display, dr, gc, im, sx, sy, dx, dy, w, h)

  proc XFlush*(display: ptr X.Display): cint =
    return tkIntXlibStubsPtr.xFlush(display)

  proc XSetBackground*(display: ptr X.Display, gc: X.GC, bg: culong): cint =
    return tkIntXlibStubsPtr.xSetBackground(display, gc, bg)

  proc XSetForeground*(display: ptr X.Display, gc: X.GC, fg: culong): cint =
    return tkIntXlibStubsPtr.xSetForeground(display, gc, fg)

  proc XCopyArea*(display: ptr X.Display, dr1: X.Drawable, dr2: X.Drawable, gc: X.GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint =
    return tkIntXlibStubsPtr.xCopyArea(display, dr1, dr2, gc, i1, i2, ui1, ui2, i3, i4)

  proc XFillRectangle*(display: ptr X.Display, dr: X.Drawable, gc: X.GC, x: cint, y: cint, width: cuint, height: cuint): cint =
    return tkIntXlibStubsPtr.xFillRectangle(display, dr, gc, x, y, width, height)

  proc XSetClipMask*(display: ptr X.Display, gc: X.GC, pixmap: X.Pixmap): cint =
    return tkIntXlibStubsPtr.xSetClipMask(display, gc, pixmap)

  proc TkPutImage*(colors: ptr culong, ncolors: cint, display: ptr X.Display, d: X.Drawable, gc: X.GC, image: ptr XImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint =
    return tkIntXlibStubsPtr.tkPutImage(colors, ncolors, display, d, gc, image, src_x, src_y, dest_x, dest_y, width, height)

  proc Visual*(tkwin: Window): ptr X.Visual {.cdecl, importc: "Tk_Visual", header: "tk.h".}

  proc GetColor*(interp: Tcl.PInterp, tkwin: Window, name: cstring): X.Color =
    return tkStubsPtr.tk_GetColor(interp, tkwin, name)

  proc GetOption*(tkwin: Window, name: cstring, className: cstring): Uid =
    return tkStubsPtr.tk_GetOption(tkwin, name, className)

  proc FreeGC*(display: ptr X.Display, gc: X.GC) =
    tkStubsPtr.tk_FreeGC(display, gc)

  proc GetPixmap*(display: ptr X.Display, d: X.Drawable, width: cint, height: cint, depth: cint): Pixmap =
    return tkStubsPtr.tk_GetPixmap(display, d, width, height, depth)

  proc FreePixmap*(display: ptr X.Display, pixmap: Pixmap) =
    tkStubsPtr.tk_FreePixmap(display, pixmap)

  proc CreateImageType*(typePtr: ptr ImageType) =
    tkStubsPtr.tk_CreateImageType(typePtr)

  proc GetGC*(tkwin: Window, valueMask: culong, valuePtr: var X.GCValues): X.GC =
    return tkStubsPtr.tk_GetGC(tkwin, valueMask, valuePtr)

  proc ImageChanged*(imageMaster: ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint) =
    tkStubsPtr.tk_ImageChanged(imageMaster, x, y, width, height, imageWidth, imageHeight)

  proc NameOfImage*(imageMaster: ImageMaster): cstring =
    return tkStubsPtr.tk_NameOfImage(imageMaster)

  when defined(tcl9):
    proc GetImageModelData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ImageType): Tcl.TClientData =
      return tkStubsPtr.tk_GetImageModelData(interp, name, typePtrPtr)
  else:
    proc GetImageMasterData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ImageType): Tcl.TClientData =
      return tkStubsPtr.tk_GetImageMasterData(interp, name, typePtrPtr)

  when defined(tcl9):
    template GetImageMasterData*(args: varargs[untyped]): untyped =
      GetImageModelData(args)

proc TkInitStubs(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tk_InitStubs", header: "tk.h".}

proc InitStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  return TkInitStubs(interp, version, exact)
  