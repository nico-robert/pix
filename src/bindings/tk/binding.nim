# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

when defined(x11):
  import ../x11/types as X

import ../tcl/binding as Tcl
import ./types as Tk
export Tk

proc FindPhoto*(interp: Tcl.PInterp, imageName: cstring): Tk.PhotoHandle
  {.cdecl, importc: "Tk_FindPhoto", header: "tk.h".}

proc PhotoPutBlock*(interp: Tcl.PInterp, handle: Tk.PhotoHandle, blockPtr: ptr Tk.PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: cint): cint
  {.cdecl, importc: "Tk_PhotoPutBlock", header: "tk.h".}

proc PhotoSetSize*(interp: Tcl.PInterp, handle: Tk.PhotoHandle, width: cint, height: cint): cint
  {.cdecl, importc: "Tk_PhotoSetSize", header: "tk.h".}

proc DisplayName*(tkwin: Tk.Window): cstring
  {.cdecl, importc: "Tk_DisplayName", header: "tk.h".}

proc Depth*(tkwin: Tk.Window): cint
  {.cdecl, importc: "Tk_Depth", header: "tk.h".}

proc Parent*(tkwin: Tk.Window): Tk.Window
  {.cdecl, importc: "Tk_Parent", header: "tk.h".}

when defined(x11):

  proc Display*(tkwin: Tk.Window): ptr X.Display
    {.cdecl, importc: "Tk_Display", header: "tk.h".}

  proc WindowId*(tkwin: Tk.Window): X.ID
    {.cdecl, importc: "Tk_WindowId", header: "tk.h".}

  proc Visual*(tkwin: Tk.Window): ptr X.Visual
    {.cdecl, importc: "Tk_Visual", header: "tk.h".}

  proc GetColor*(interp: Tcl.PInterp, tkwin: Tk.Window, name: cstring): ptr X.Color
    {.cdecl, importc: "Tk_GetColor", header: "tk.h".}

  proc GetOption*(tkwin: Tk.Window, name: cstring, className: cstring): Uid
    {.cdecl, importc: "Tk_GetOption", header: "tk.h".}

  proc FreeGC*(display: ptr X.Display, gc: X.GC)
    {.cdecl, importc: "Tk_FreeGC", header: "tk.h".}

  proc GetPixmap*(display: ptr X.Display, d: X.Drawable, width: cint, height: cint, depth: cint): Pixmap
    {.cdecl, importc: "Tk_GetPixmap", header: "tk.h".}

  proc FreePixmap*(display: ptr X.Display, pixmap: Pixmap)
    {.cdecl, importc: "Tk_FreePixmap", header: "tk.h".}

  proc CreateImageType*(typePtr: ptr Tk.ImageType)
    {.cdecl, importc: "Tk_CreateImageType", header: "tk.h".}

  proc GetGC*(tkwin: Tk.Window, valueMask: culong, valuePtr: var X.GCValues): X.GC
    {.cdecl, importc: "Tk_GetGC", header: "tk.h".}

  proc ImageChanged*(imageMaster: Tk.ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint)
    {.cdecl, importc: "Tk_ImageChanged", header: "tk.h".}

  proc NameOfImage*(imageMaster: Tk.ImageMaster): cstring
    {.cdecl, importc: "Tk_NameOfImage", header: "tk.h".}

  when defined(tcl9):
    proc GetImageModelData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ptr Tk.ImageType): Tcl.TClientData
      {.cdecl, importc: "Tk_GetImageModelData", header: "tk.h".}

    template GetImageMasterData*(args: varargs[untyped]): untyped =
      GetImageModelData(args)
  else:
    proc GetImageMasterData*(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ptr Tk.ImageType): Tcl.TClientData
      {.cdecl, importc: "Tk_GetImageMasterData", header: "tk.h".}

proc InitStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring
  {.cdecl, importc: "Tk_InitStubs", header: "tk.h".}