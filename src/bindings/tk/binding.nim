# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

when defined(x11):
  import ../../core/xtypes as X

import ../tcl/binding as Tcl

include "private/tktypes.inc"

type
  TFindPhoto        = proc(interp: Tcl.PInterp, imageName: cstring): PhotoHandle {.cdecl.}
  TPhotoPutBlock    = proc(interp: Tcl.PInterp, handle: PhotoHandle, blockPtr: ptr PhotoImageBlock, x: cint, y: cint, width: cint, height: cint, compRule: int): int {.cdecl.}
  TPhotoSetSize     = proc(interp: Tcl.PInterp, handle: PhotoHandle, width: cint, height: cint): int {.cdecl.}
  TDisplayName      = proc(tkwin: Window): cstring {.cdecl.}

when defined(x11):
  type
    TGetColor          = proc(interp: Tcl.PInterp, tkwin: Window, name: cstring): X.Color {.cdecl.}
    TGetOption         = proc(tkwin: Window, name: cstring, className: cstring): Uid {.cdecl.}
    TFreeGC            = proc(display: ptr Display, gc: GC) {.cdecl.}
    TGetPixmap         = proc(display: ptr Display, d: Drawable, width: cint, height: cint, depth: cint): Pixmap {.cdecl.}
    TFreePixmap        = proc(display: ptr Display, pixmap: Pixmap) {.cdecl.}
    TCreateImageType   = proc(typePtr: ImageType) {.cdecl.}
    TGetGC             = proc(tkwin: Window, valueMask: culong, valuePtr: var XGCValues): GC {.cdecl.}
    TImageChanged      = proc(imageMaster: ImageMaster, x: cint, y: cint, width: cint, height: cint, imageWidth: cint, imageHeight: cint) {.cdecl.}
    TNameOfImage       = proc(imageMaster: ImageMaster): cstring {.cdecl.}
    TGetImageModelData = proc(interp: Tcl.PInterp, name: cstring, typePtrPtr: var ImageType): Tcl.TClientData {.cdecl.}

  var
    Tk_GetColor*       : TGetColor
    Tk_GetOption*      : TGetOption
    FreeGC*            : TFreeGC
    GetPixmap*         : TGetPixmap
    FreePixmap*        : TFreePixmap
    CreateImageType*   : TCreateImageType
    GetGC*             : TGetGC
    ImageChanged*      : TImageChanged
    NameOfImage*       : TNameOfImage

  when defined(tcl9):
    var GetImageModelData*  : TGetImageModelData
  else:
    var GetImageMasterData* : TGetImageModelData

var
  FindPhoto*       : TFindPhoto
  PhotoPutBlock*   : TPhotoPutBlock
  PhotoSetSize*    : TPhotoSetSize
  DisplayName*     : TDisplayName

type TkStubs = object
  tk_FindPhoto       : TFindPhoto
  tk_PhotoPutBlock   : TPhotoPutBlock
  tk_PhotoSetSize    : TPhotoSetSize
  tk_DisplayName     : TDisplayName
  when defined(x11):
    tk_GetColor          : TGetColor
    tk_GetOption         : TGetOption
    tk_GetPixmap         : TGetPixmap
    tk_FreePixmap        : TFreePixmap
    tk_FreeGC            : TFreeGC
    tk_CreateImageType   : TCreateImageType
    tk_GetGC             : TGetGC
    tk_ImageChanged      : TImageChanged
    tk_NameOfImage       : TNameOfImage
    when defined(tcl9):
      tk_GetImageModelData : TGetImageModelData
    else:
      tk_GetImageMasterData : TGetImageModelData

proc Depth*   (tkwin: Window): cint   {.cdecl, importc: "Tk_Depth", header: "tk.h".}
proc WindowId*(tkwin: Window): culong {.cdecl, importc: "Tk_WindowId", header: "tk.h".}
proc Parent*  (tkwin: Window): Window {.cdecl, importc: "Tk_Parent", header: "tk.h".}
proc InitStubs(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tk_InitStubs", header: "tk.h".}

when defined(x11):
  proc Visual*(tkwin: Window): ptr X.Visual {.cdecl, importc: "Tk_Visual", header: "tk.h".}
  var tkIntXlibStubsPtr*{.importc: "tkIntXlibStubsPtr", header: "tkIntXlibDecls.h".}: ptr TkIntXlibStubs

  when defined(tcl9):
    template GetImageMasterData*(args: varargs[untyped]): untyped =
      GetImageModelData(args)

  proc InitImageType*(interp: Tcl.PInterp): int {.cdecl.} =

    XCreateImage   = cast[TXCreateImage](tkIntXlibStubsPtr.xCreateImage)
    XCreateGC      = cast[TXCreateGC](tkIntXlibStubsPtr.xCreateGC)
    XPutImage      = cast[TXPutImage](tkIntXlibStubsPtr.xPutImage)
    XFlush         = cast[TXFlush](tkIntXlibStubsPtr.xFlush)
    XSetBackground = cast[TXSetBackground](tkIntXlibStubsPtr.xSetBackground)
    XSetForeground = cast[TXSetForeground](tkIntXlibStubsPtr.xSetForeground)
    XCopyArea      = cast[TXCopyArea](tkIntXlibStubsPtr.xCopyArea)
    XFillRectangle = cast[TXFillRectangle](tkIntXlibStubsPtr.xFillRectangle)
    XSetClipMask   = cast[TXSetClipMask](tkIntXlibStubsPtr.xSetClipMask)
    TkPutImage     = cast[TPutImage](tkIntXlibStubsPtr.tkPutImage)

    return Tcl.Ok

var tkStubsPtr*{.importc: "tkStubsPtr", header: "tkDecls.h".} : ptr TkStubs

proc InitTkStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  result = InitStubs(interp, version, exact)
  
  FindPhoto       = cast[TFindPhoto](tkStubsPtr.tk_FindPhoto)
  PhotoPutBlock   = cast[TPhotoPutBlock](tkStubsPtr.tk_PhotoPutBlock)
  PhotoSetSize    = cast[TPhotoSetSize](tkStubsPtr.tk_PhotoSetSize)
  DisplayName     = cast[TDisplayName](tkStubsPtr.tk_DisplayName)
  when defined(x11):
    Tk_GetColor       = cast[TGetColor](tkStubsPtr.tk_GetColor)
    Tk_GetOption      = cast[TGetOption](tkStubsPtr.tk_GetOption)
    GetPixmap         = cast[TGetPixmap](tkStubsPtr.tk_GetPixmap)
    FreePixmap        = cast[TFreePixmap](tkStubsPtr.tk_FreePixmap)
    FreeGC            = cast[TFreeGC](tkStubsPtr.tk_FreeGC)
    CreateImageType   = cast[TCreateImageType](tkStubsPtr.tk_CreateImageType)
    GetGC             = cast[TGetGC](tkStubsPtr.tk_GetGC)
    ImageChanged      = cast[TImageChanged](tkStubsPtr.tk_ImageChanged)
    NameOfImage       = cast[TNameOfImage](tkStubsPtr.tk_NameOfImage)
    when defined(tcl9):
      GetImageModelData  = cast[TGetImageModelData](tkStubsPtr.tk_GetImageModelData)
    else:
      GetImageMasterData = cast[TGetImageModelData](tkStubsPtr.tk_GetImageMasterData)

  return result