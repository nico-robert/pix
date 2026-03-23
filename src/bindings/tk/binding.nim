# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

when defined(x11):
  import ../x11/types as X

import ../tcl/binding as Tcl
import ./types as Tk
export Tk

type 
  TkStubs {.importc.} = object
    tk_FindPhoto       : proc(interp: Tcl.PInterp, imageName: cstring): Tk.PhotoHandle {.cdecl.}
    tk_PhotoPutBlock   : proc(interp: Tcl.PInterp, handle: Tk.PhotoHandle, blockPtr: ptr Tk.PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: cint): cint {.cdecl.}
    tk_PhotoSetSize    : proc(interp: Tcl.PInterp, handle: Tk.PhotoHandle, width: cint, height: cint): cint {.cdecl.}
    tk_DisplayName     : proc(tkwin: Tk.Window): cstring {.cdecl.}
    when defined(x11):
      tk_GetColor          : proc(interp: Tcl.PInterp, tkwin: Tk.Window, name: cstring): X.Color {.cdecl.}
      tk_GetOption         : proc(tkwin: Tk.Window, name: cstring, className: cstring): Uid {.cdecl.}
      tk_FreeGC            : proc(display: ptr X.Display, gc: X.GC) {.cdecl.}
      tk_GetPixmap         : proc(display: ptr X.Display, d: X.Drawable, width: cint, height: cint, depth: cint): Pixmap {.cdecl.}
      tk_FreePixmap        : proc(display: ptr X.Display, pixmap: Pixmap) {.cdecl.}
      tk_CreateImageType   : proc(typePtr: ptr Tk.ImageType) {.cdecl.}
      tk_GetGC             : proc(tkwin: Tk.Window, valueMask: culong, valuePtr: var X.GCValues): X.GC {.cdecl.}
      tk_ImageChanged      : proc(imageMaster: Tk.ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint) {.cdecl.}
      tk_NameOfImage       : proc(imageMaster: Tk.ImageMaster): cstring {.cdecl.}
      when defined(tcl9):
        tk_GetImageModelData  : proc(interp: Tcl.PInterp, name: cstring, typePtrPtr: var Tk.ImageType): Tcl.TClientData {.cdecl.}
      else:
        tk_GetImageMasterData : proc(interp: Tcl.PInterp, name: cstring, typePtrPtr: var Tk.ImageType): Tcl.TClientData {.cdecl.}

var tkStubsPtr {.importc: "tkStubsPtr", header: "tkDecls.h".} : ptr TkStubs

proc FindPhoto*(interp: Tcl.PInterp, imageName: cstring): Tk.PhotoHandle =
  return tkStubsPtr.tk_FindPhoto(interp, imageName)

proc PhotoPutBlock*(interp: Tcl.PInterp, handle: Tk.PhotoHandle, blockPtr: ptr Tk.PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: cint): cint =
  return tkStubsPtr.tk_PhotoPutBlock(interp, handle, blockPtr, x, y, width, height, compRule)

proc PhotoSetSize*(interp: Tcl.PInterp, handle: Tk.PhotoHandle, width: cint, height: cint): cint =
  return tkStubsPtr.tk_PhotoSetSize(interp, handle, width, height)

proc DisplayName*(tkwin: Tk.Window): cstring =
  return tkStubsPtr.tk_DisplayName(tkwin)

proc Depth*(tkwin: Tk.Window): cint {.cdecl, importc: "Tk_Depth", header: "tk.h".}
proc Parent*(tkwin: Tk.Window): Tk.Window {.cdecl, importc: "Tk_Parent", header: "tk.h".}

when defined(x11):

  proc Display*(tkwin: Tk.Window): ptr X.Display {.cdecl, importc: "Tk_Display", header: "tk.h".}
  proc WindowId*(tkwin: Tk.Window): X.ID {.cdecl, importc: "Tk_WindowId", header: "tk.h".}
  proc Visual*(tkwin: Tk.Window): ptr X.Visual {.cdecl, importc: "Tk_Visual", header: "tk.h".}

  proc GetColor*(interp: Tcl.PInterp, tkwin: Tk.Window, name: cstring): X.Color =
    return tkStubsPtr.tk_GetColor(interp, tkwin, name)

  proc GetOption*(tkwin: Tk.Window, name: cstring, className: cstring): Uid =
    return tkStubsPtr.tk_GetOption(tkwin, name, className)

  proc FreeGC*(display: ptr X.Display, gc: X.GC) =
    tkStubsPtr.tk_FreeGC(display, gc)

  proc GetPixmap*(display: ptr X.Display, d: X.Drawable, width: cint, height: cint, depth: cint): Pixmap =
    return tkStubsPtr.tk_GetPixmap(display, d, width, height, depth)

  proc FreePixmap*(display: ptr X.Display, pixmap: Pixmap) =
    tkStubsPtr.tk_FreePixmap(display, pixmap)

  proc CreateImageType*(typePtr: ptr Tk.ImageType) =
    tkStubsPtr.tk_CreateImageType(typePtr)

  proc GetGC*(tkwin: Tk.Window, valueMask: culong, valuePtr: var X.GCValues): X.GC =
    return tkStubsPtr.tk_GetGC(tkwin, valueMask, valuePtr)

  proc ImageChanged*(imageMaster: Tk.ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint) =
    tkStubsPtr.tk_ImageChanged(imageMaster, x, y, width, height, imageWidth, imageHeight)

  proc NameOfImage*(imageMaster: Tk.ImageMaster): cstring =
    return tkStubsPtr.tk_NameOfImage(imageMaster)

  when defined(tcl9):
    proc GetImageModelData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var Tk.ImageType): Tcl.TClientData =
      return tkStubsPtr.tk_GetImageModelData(interp, name, typePtrPtr)
  else:
    proc GetImageMasterData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var Tk.ImageType): Tcl.TClientData =
      return tkStubsPtr.tk_GetImageMasterData(interp, name, typePtrPtr)

  when defined(tcl9):
    template GetImageMasterData*(args: varargs[untyped]): untyped =
      GetImageModelData(args)

proc TkInitStubs(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tk_InitStubs", header: "tk.h".}

proc InitStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  return TkInitStubs(interp, version, exact)
  