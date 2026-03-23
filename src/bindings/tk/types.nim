when defined(x11):
  import ../tcl/types as Tcl
  import ../x11/types as X

const 
  PHOTO_COMPOSITE_OVERLAY* = 0
  PHOTO_COMPOSITE_SET*     = 1
  
type
  ImageMaster*{.importc: "Tk_ImageMaster", header: "tk.h".} = distinct pointer
  Window*     {.importc: "Tk_Window", header: "tk.h".}      = distinct pointer

when defined(x11):
  type
    ImageType* = object
      name*           : cstring
      createProc*     : proc(interp: Tcl.PInterp, imageName: cstring, objc: cint, objv: Tcl.PPObj, typePtr: ptr ImageType, masterPtr: ImageMaster, clientDataPtr: Tcl.PClientData): cint {.cdecl.}
      getProc*        : proc(tkwin: Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.}
      displayProc*    : proc(instanceData: Tcl.TClientData, display: ptr X.Display, drawable: X.Drawable, imageX: cint, imageY: cint, width: cint, height: cint, drawableX: cint, drawableY: cint) {.cdecl.}
      freeProc*       : proc(instanceData: Tcl.TClientData, display: ptr X.Display) {.cdecl.}
      deleteProc*     : proc(instanceData: Tcl.TClientData) {.cdecl.}

type
  PhotoHandle*     = pointer
  PhotoImageBlock* = TBlock

  TBlock* = object
    pixelPtr* : ptr UncheckedArray[uint8]
    width*    : cint
    height*   : cint
    pitch*    : cint
    pixelSize*: cint
    offset*   : array[4, cint]