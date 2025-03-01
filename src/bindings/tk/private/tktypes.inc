const 
  PHOTO_COMPOSITE_OVERLAY* = 0
  PHOTO_COMPOSITE_SET*     = 1
  
type
  ImageMaster*{.importc: "Tk_ImageMaster", header: "tk.h".} = distinct pointer
  Window*     {.importc: "Tk_Window", header: "tk.h".}      = distinct pointer

type
  PhotoHandle*     = pointer
  PhotoImageBlock* = TBlock

  TBlock*{.final.} = object 
    pixelPtr* : ptr UncheckedArray[uint8]
    width*    : cint
    height*   : cint
    pitch*    : cint
    pixelSize*: cint
    offset*   : array[4, cint]

  # Image types.
  ImageType*{.final.} = object
    name*           : cstring
    createProc*     : pointer
    getProc*        : pointer
    displayProc*    : pointer
    freeProc*       : pointer
    deleteProc*     : pointer
    postscriptProc* : pointer
    nextPtr*        : pointer
    reserved*       : cstring