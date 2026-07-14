# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

const
  OK*    = 0
  ERROR* = 1
  INDEX_NONE* = -1
  GLOBAL_ONLY* = 1

when defined(tcl9):
  type
    Size* {.importc: "Tcl_Size", header: "tcl.h".} = int
    HASH_TYPE* = csize_t
else:
  type
    Size* = cint
    HASH_TYPE* = cuint

type
  TInterp*{.importc: "Tcl_Interp", header: "tcl.h", incompleteStruct.} = object
  PInterp* = ptr TInterp

  TNamespace*{.importc: "Tcl_Namespace", header: "tcl.h", incompleteStruct.} = object
  PNamespace* = ptr TNamespace

  TClientData* = pointer
  PClientData* = ptr TClientData

  PNamespaceDeleteProc* = pointer
  TNamespaceDeleteProc* {.importc: "Tcl_NamespaceDeleteProc", header: "tcl.h".} = proc(
    clientData: TClientData
    ) {.cdecl.}

  TCommand*{.importc: "struct Tcl_Command_", header: "tcl.h", incompleteStruct.} = object
  PCommand* = ptr TCommand

  WideInt* = clonglong

  TwoPtrValue* = object
    ptr1*: pointer
    ptr2*: pointer

  PtrAndLongRep* = object
    ptr1*: pointer
    value*: culong

when defined(tcl9):
  type
    TObjInternalRep* {.importc: "Tcl_ObjInternalRep", header: "tcl.h", union.} = object
      longValue*: clong
      doubleValue*: cdouble
      otherValuePtr*: pointer
      wideValue*: clonglong
      twoPtrValue*: TwoPtrValue
      ptrAndLongRep*: PtrAndLongRep
else:
  type
    TObjInternalRep* {.union.} = object
      longValue*: clong
      doubleValue*: cdouble
      otherValuePtr*: pointer
      wideValue*: clonglong
      twoPtrValue*: TwoPtrValue
      ptrAndLongRep*: PtrAndLongRep

type
  PObjInternalRep* = ptr TObjInternalRep

  ObjType* {.importc: "Tcl_ObjType", header: "tcl.h".} = object
    name*:             cstring
    freeIntRepProc*:   proc(objPtr: PObj) {.cdecl, gcsafe.}
    dupIntRepProc*:    proc(srcPtr: PObj, dupPtr: PObj) {.cdecl, gcsafe.}
    updateStringProc*: proc(objPtr: PObj) {.cdecl, gcsafe.}
    setFromAnyProc*:   proc(interp: PInterp, objPtr: PObj): cint {.cdecl, gcsafe.}
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

  TObj* {.importc: "Tcl_Obj", header: "tcl.h".} = object
    refCount*   : Size
    bytes*      : cstring
    length*     : Size
    typePtr*    : PObjType
    internalRep*: TObjInternalRep

  PObj*  = ptr TObj
  PPObj* = ptr UncheckedArray[PObj]

  PCmdDeleteProc* {.importc: "Tcl_CmdDeleteProc", header: "tcl.h".} = proc(
                  clientData: TClientData
                  ) {.cdecl.}
  PObjCmdProc*    {.importc: "Tcl_ObjCmdProc", header: "tcl.h".} = proc(
                  clientData: TClientData,
                  interp: PInterp,
                  objc: cint,
                  objv: PPObj
                  ): cint {.cdecl.}