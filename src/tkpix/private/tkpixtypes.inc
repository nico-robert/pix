{.deadCodeElim: on.}

type
  PhotoImageBlock* = TBlock
  TBlock*{.final.} = object 
    pixelPtr* : ptr UncheckedArray[uint8]
    width*: cint
    height*: cint
    pitch*: cint
    pixelSize*: cint
    offset*: array[4, cint]

  # The following types have not been tested 
  Tk_Image*{.final.} = object
  Tk_Window*{.final.} = object
  Tk_3DBorder*{.final.} = object
  Font* = pointer
  PXColor* = pointer
  PhotoHandle* = pointer
  PTk_OptionSpec* = pointer
  PTk_SavedOptions* = pointer
  Tk_OptionTable*{.final.} = object
  PTk_RestrictProc* = pointer
  PTk_GenericProc* = pointer
  PTk_ImageType* = pointer
  PTk_ItemType* = pointer
  PTk_ConfigSpec* = pointer
  PTk_CanvasTextInfo* = pointer
  PTk_PhotoImageFormat* = pointer
  PTk_ErrorProc* = pointer
  PTk_Anchor* = pointer
  PTk_SelectionProc* = pointer
  PTk_FontMetrics* = pointer
  PTk_Justify* = pointer
  PTk_GeomMgr* = pointer
  PTk_ImageChangedProc* = pointer
  PTk_EventProc* = pointer
  PTk_ClientMessageProc* = pointer
  PTk_ElementSpec* = pointer
  PTk_PhotoImageFormatVersion3* = pointer
  PTk_GetSelProc* = pointer
  PTk_SmoothMethod* = pointer
  PXWindowChanges* = pointer
  PXGCValues* = pointer
  PXSetWindowAttributes* = pointer
  PTk_ClassProcs* = pointer
  PTk_Item* = pointer
  PColormap* = pointer
  PVisual* = pointer
  PTk_LostSelProc* = pointer
  PTk_Dash* = pointer
  PTk_Outline* = pointer
  PTk_ArgvInfo* = pointer
  PDString* = pointer
  PXEvent* = pointer
  HWND* = pointer
  HINSTANCE* = pointer
  GC* = pointer
  PXPoint* = pointer
  PTk_TSOffset* = pointer
  Pixmap* = pointer
  Pshort* = pointer
  Pvoid* = pointer
  PDisplay* = pointer
  PFreeProc* = pointer
  Window* = pointer
  Atom* = pointer
  Tk_TextLayout*{.final.} = object
  Tk_BindingTable*{.final.} = object
  Tk_Canvas*{.final.} = object
  Tk_Font*{.final.} = object
  Tk_PostscriptInfo*{.final.} = object
  Drawable*{.final.} = object
  Tk_Uid* = cstring
  Tk_Justify* = cstring
  Tk_Cursor* = cstring
  Tk_ErrorHandler* = cstring
  Colormap* = cstring
  Tk_ImageModel* = cstring
  Tk_StyleEngine* = cstring
  Tk_Anchor* = cstring
  Tk_Style* = cstring
  Tk_StyledElement* = cstring
  Size* = int