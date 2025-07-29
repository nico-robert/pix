# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

include "private/tcltypes.inc"

when defined(tcl8):
  type TNewIntObj        = proc(intValue: int): PObj {.cdecl.}
  type TNewBooleanObj    = proc(intValue: int): PObj {.cdecl.}

type
  TPkgProvideEx         = proc(interp: PInterp, name: cstring, version: cstring, clientData: TClientData): cint {.cdecl.}
  TGetBooleanFromObj    = proc(interp: PInterp, objPtr: PObj, boolPtr: var int): cint {.cdecl.}
  TGetDoubleFromObj     = proc(interp: PInterp, objPtr: PObj, doublePtr: var cdouble): cint {.cdecl.}
  TGetIntFromObj        = proc(interp: PInterp, objPtr: PObj, intPtr: var cint): cint {.cdecl.}
  TGetString            = proc(objPtr: PObj): cstring {.cdecl.}
  TListObjAppendElement = proc(interp: PInterp, listPtr: PObj, objPtr: PObj): cint {.cdecl.}
  TListObjGetElements   = proc(interp: PInterp, listPtr: PObj, lengthPtr: var Size, objvPtr: var PPObj): cint {.cdecl.}
  TListObjLength        = proc(interp: PInterp, listPtr: PObj, lengthPtr: var Size): cint {.cdecl.}
  TNewDoubleObj         = proc(doubleValue: cdouble): PObj {.cdecl.}
  TNewWideIntObj        = proc(wideValue: WideInt): PObj {.cdecl.}
  TNewListObj           = proc(objc: Size, objv: PPObj): PObj {.cdecl.}
  TNewStringObj         = proc(bytes: cstring, length: Size): PObj {.cdecl.}
  TCreateObjCommand     = proc(interp: PInterp, cmdName: cstring, callback: PObjCmdProc, clientData: TClientData, deleteProc: PCmdDeleteProc): Command {.cdecl.}
  TSetObjResult         = proc(interp: PInterp, resultObjPtr: PObj) {.cdecl.}
  TDictObjPut           = proc(interp: PInterp, dictPtr: PObj, keyPtr: PObj, valuePtr: PObj): cint {.cdecl.}
  TNewDictObj           = proc(): PObj {.cdecl.}
  TCreateNamespace      = proc(interp: PInterp, name: cstring, clientData: TClientData, deleteProc: PNamespaceDeleteProc): PNamespace {.cdecl.}
  TFindNamespace        = proc(interp: PInterp, name: cstring, contextNsPtr: PNamespace, flags: cint): PNamespace {.cdecl.}
  TWrongNumArgs         = proc(interp: PInterp, objc: Size, objv: PPObj, message: cstring) {.cdecl.}
  TGetObjResult         = proc(interp: PInterp): PObj {.cdecl.}
  TNewByteArrayObj      = proc(bytes: cstring, length: Size): PObj {.cdecl.}
  TEvalObjv             = proc(interp: PInterp, objc: Size, objv: PPObj, flags: cint): cint {.cdecl.}

when defined(tcl9):
  type TIncrRefCount  = proc(objPtr: PObj) {.cdecl.}
  type TDecrRefCount  = proc(objPtr: PObj) {.cdecl.}

var
  PkgProvideEx*        : TPkgProvideEx
  GetBooleanFromObj*   : TGetBooleanFromObj
  GetDoubleFromObj*    : TGetDoubleFromObj
  GetIntFromObj*       : TGetIntFromObj
  GetString*           : TGetString
  ListObjAppendElement*: TListObjAppendElement
  ListObjGetElements*  : TListObjGetElements
  ListObjLength*       : TListObjLength
  NewDoubleObj*        : TNewDoubleObj
  NewWideIntObj*       : TNewWideIntObj
  NewListObj*          : TNewListObj
  NewStringObj*        : TNewStringObj
  CreateObjCommand*    : TCreateObjCommand
  SetObjResult*        : TSetObjResult
  DictObjPut*          : TDictObjPut
  NewDictObj*          : TNewDictObj
  CreateNamespace*     : TCreateNamespace
  FindNamespace*       : TFindNamespace
  WrongNumArgs*        : TWrongNumArgs
  GetObjResult*        : TGetObjResult
  NewByteArrayObj*     : TNewByteArrayObj
  EvalObjv*            : TEvalObjv

when defined(tcl9):
  var IncrRefCount*    : TIncrRefCount
  var DecrRefCount*    : TDecrRefCount

when defined(tcl8):
  var NewIntObj*       : TNewIntObj
  var NewBooleanObj*   : TNewBooleanObj

type TclStubs = object
  tcl_PkgProvideEx         : TPkgProvideEx
  tcl_GetBooleanFromObj    : TGetBooleanFromObj
  tcl_GetDoubleFromObj     : TGetDoubleFromObj
  tcl_GetIntFromObj        : TGetIntFromObj
  tcl_GetString            : TGetString
  tcl_ListObjAppendElement : TListObjAppendElement
  tcl_ListObjGetElements   : TListObjGetElements
  tcl_ListObjLength        : TListObjLength
  tcl_NewDoubleObj         : TNewDoubleObj
  tcl_NewWideIntObj        : TNewWideIntObj
  tcl_NewListObj           : TNewListObj
  tcl_NewStringObj         : TNewStringObj
  tcl_CreateObjCommand     : TCreateObjCommand
  tcl_SetObjResult         : TSetObjResult
  tcl_DictObjPut           : TDictObjPut
  tcl_NewDictObj           : TNewDictObj
  tcl_CreateNamespace      : TCreateNamespace
  tcl_FindNamespace        : TFindNamespace
  tcl_WrongNumArgs         : TWrongNumArgs
  tcl_GetObjResult         : TGetObjResult
  tcl_NewByteArrayObj      : TNewByteArrayObj
  tcl_EvalObjv             : TEvalObjv
  when defined(tcl9):
    tcl_IncrRefCount       : TIncrRefCount
    tcl_DecrRefCount       : TDecrRefCount
  when defined(tcl8):
    tcl_NewIntObj          : TNewIntObj
    tcl_NewBooleanObj      : TNewBooleanObj

when defined(tcl9):
  template NewIntObj*(value: untyped)       : untyped = NewWideIntObj(int(value))
  template NewBooleanObj*(intValue: untyped): untyped = NewWideIntObj(int(intValue != 0))
  
proc GetStringResult*(interp: PInterp): cstring {.cdecl.} =
  return GetString(GetObjResult(interp))

var tclStubsPtr* {.importc: "tclStubsPtr", header: "tclDecls.h".} : ptr TclStubs
proc tclInitStubs(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tcl_InitStubs", header: "tcl.h".}

when defined(tcl8):
  proc IncrRefCount*(objPtr: PObj) {.cdecl, importc: "Tcl_IncrRefCount", header: "tcl.h".}
  proc DecrRefCount*(objPtr: PObj) {.cdecl, importc: "Tcl_DecrRefCount", header: "tcl.h".}

proc InitStubs*(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  result = tclInitStubs(interp, version, exact)
  
  PkgProvideEx         = cast[TPkgProvideEx](tclStubsPtr.tcl_PkgProvideEx)
  GetBooleanFromObj    = cast[TGetBooleanFromObj](tclStubsPtr.tcl_GetBooleanFromObj)
  GetDoubleFromObj     = cast[TGetDoubleFromObj](tclStubsPtr.tcl_GetDoubleFromObj)
  GetIntFromObj        = cast[TGetIntFromObj](tclStubsPtr.tcl_GetIntFromObj)
  GetString            = cast[TGetString](tclStubsPtr.tcl_GetString)
  ListObjAppendElement = cast[TListObjAppendElement](tclStubsPtr.tcl_ListObjAppendElement)
  ListObjGetElements   = cast[TListObjGetElements](tclStubsPtr.tcl_ListObjGetElements)
  ListObjLength        = cast[TListObjLength](tclStubsPtr.tcl_ListObjLength)
  NewDoubleObj         = cast[TNewDoubleObj](tclStubsPtr.tcl_NewDoubleObj)
  NewWideIntObj        = cast[TNewWideIntObj](tclStubsPtr.tcl_NewWideIntObj)
  NewListObj           = cast[TNewListObj](tclStubsPtr.tcl_NewListObj)
  NewStringObj         = cast[TNewStringObj](tclStubsPtr.tcl_NewStringObj)
  CreateObjCommand     = cast[TCreateObjCommand](tclStubsPtr.tcl_CreateObjCommand)
  SetObjResult         = cast[TSetObjResult](tclStubsPtr.tcl_SetObjResult)
  DictObjPut           = cast[TDictObjPut](tclStubsPtr.tcl_DictObjPut)
  NewDictObj           = cast[TNewDictObj](tclStubsPtr.tcl_NewDictObj)
  CreateNamespace      = cast[TCreateNamespace](tclStubsPtr.tcl_CreateNamespace)
  FindNamespace        = cast[TFindNamespace](tclStubsPtr.tcl_FindNamespace)
  WrongNumArgs         = cast[TWrongNumArgs](tclStubsPtr.tcl_WrongNumArgs)
  GetObjResult         = cast[TGetObjResult](tclStubsPtr.tcl_GetObjResult)
  NewByteArrayObj      = cast[TNewByteArrayObj](tclStubsPtr.tcl_NewByteArrayObj)
  EvalObjv             = cast[TEvalObjv](tclStubsPtr.tcl_EvalObjv)
  when defined(tcl9):
    IncrRefCount       = cast[TIncrRefCount](tclStubsPtr.tcl_IncrRefCount)
    DecrRefCount       = cast[TDecrRefCount](tclStubsPtr.tcl_DecrRefCount)
  when defined(tcl8):
    NewIntObj          = cast[TNewIntObj](tclStubsPtr.tcl_NewIntObj)
    NewBooleanObj      = cast[TNewBooleanObj](tclStubsPtr.tcl_NewBooleanObj)