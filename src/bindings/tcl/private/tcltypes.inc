const
  OK*    = 0
  ERROR* = 1

when defined(tcl9):
  type Size* {.importc: "Tcl_Size", header: "tcl.h".} = clong
else:
  type Size* = cint

type
  TInterp*{.incompleteStruct.} = object
  PInterp* = ptr TInterp

  TNamespace*{.incompleteStruct.} = object
  PNamespace* = ptr TNamespace

  TClientData* = pointer
  PClientData* = ptr TClientData

  PNamespaceDeleteProc = pointer
  TNamespaceDeleteProc* {.importc: "Tcl_NamespaceDeleteProc", header: "tcl.h".} = proc(
    clientData: TClientData
    ) {.cdecl.}
  
  TCommand*{.incompleteStruct.} = object
  PCommand* = ptr TCommand

  TObjType* {.incompleteStruct.} = object

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

  TObj* = object
    refCount*   : Size
    bytes*      : cstring
    length*     : Size
    typePtr*    : ptr TObjType
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