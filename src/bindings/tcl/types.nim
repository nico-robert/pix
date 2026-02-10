const
  OK*    = 0
  ERROR* = 1
  INDEX_NONE* = -1

when defined(tcl9):
  type
    Size* {.importc: "Tcl_Size", header: "tcl.h".} = clong
    HASH_TYPE* = csize_t
else:
  type
    Size* = cint
    HASH_TYPE* = cuint

type
  TInterp*{.incompleteStruct.} = object
  PInterp* = ptr TInterp

  TNamespace*{.incompleteStruct.} = object
  PNamespace* = ptr TNamespace

  TClientData* = pointer
  PClientData* = ptr TClientData

  PNamespaceDeleteProc* = pointer
  TNamespaceDeleteProc* {.importc: "Tcl_NamespaceDeleteProc", header: "tcl.h".} = proc(
    clientData: TClientData
    ) {.cdecl.}

  TCommand*{.incompleteStruct.} = object
  PCommand* = ptr TCommand

  ObjType* = object
    name*:             cstring
    freeIntRepProc*:   proc(objPtr: PObj) {.cdecl.}
    dupIntRepProc*:    proc(srcPtr: PObj, dupPtr: PObj) {.cdecl.}
    updateStringProc*: proc(objPtr: PObj) {.cdecl.}
    setFromAnyProc*:   proc(interp: PInterp, objPtr: PObj): cint {.cdecl.}
    when defined(tcl9):
      version*: csize_t
      lengthProc*: pointer      # TODO: Tcl_ObjTypeLengthProc
      indexProc*: pointer       # TODO: Tcl_ObjTypeIndexProc
      sliceProc*: pointer       # TODO: Tcl_ObjTypeSliceProc
      reverseProc*: pointer     # TODO: Tcl_ObjTypeReverseProc
      getElementsProc*: pointer # TODO: Tcl_ObjTypeGetElements
      setElementProc*: pointer  # TODO: Tcl_ObjTypeSetElement
      replaceProc*: pointer     # TODO: Tcl_ObjTypeReplaceProc
      inOperProc*: pointer      # TODO: Tcl_ObjTypeInOperatorProc

  PObjType* = ptr ObjType

  TwoPtrValue* = object
    ptr1*: pointer
    ptr2*: pointer

  PtrAndLongRep* = object
    ptr1*: pointer
    value*: culong

  TObjInternalRep* {.union.} = object
    longValue*: clong
    doubleValue*: cdouble
    otherValuePtr*: pointer
    wideValue*: clonglong
    twoPtrValue*: TwoPtrValue
    ptrAndLongRep*: PtrAndLongRep

  PObjInternalRep*  = ptr TObjInternalRep

  TObj* = object
    refCount*   : Size
    bytes*      : cstring
    length*     : Size
    typePtr*    : PObjType
    internalRep*: TObjInternalRep

  PObj*  = ptr TObj
  PPObj* = ptr UncheckedArray[PObj]

  WideInt*        = clonglong
  PCmdDeleteProc* {.importc: "Tcl_CmdDeleteProc", header: "tcl.h".} = proc(
                  clientData: TClientData
                  ) {.cdecl.}
  PObjCmdProc*    {.importc: "Tcl_ObjCmdProc", header: "tcl.h".} = proc(
                  clientData: TClientData,
                  interp: PInterp,
                  objc: cint,
                  objv: PPObj
                  ): cint {.cdecl.}