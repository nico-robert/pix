# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

include "private/tcltypes.inc"

type
  TclStubs {.importc.} = object
    tcl_PkgProvideEx         : proc(interp: PInterp, name: cstring, version: cstring, clientData: TClientData): cint {.cdecl.}
    tcl_GetBooleanFromObj    : proc(interp: PInterp, objPtr: PObj, boolPtr: var cint): cint {.cdecl.}
    tcl_GetDoubleFromObj     : proc(interp: PInterp, objPtr: PObj, doublePtr: var cdouble): cint {.cdecl.}
    tcl_GetIntFromObj        : proc(interp: PInterp, objPtr: PObj, intPtr: var cint): cint {.cdecl.}
    tcl_GetString            : proc(objPtr: PObj): cstring {.cdecl.}
    tcl_ListObjAppendElement : proc(interp: PInterp, listPtr: PObj, objPtr: PObj): cint {.cdecl.}
    tcl_ListObjGetElements   : proc(interp: PInterp, listPtr: PObj, lengthPtr: var Size, objvPtr: var PPObj): cint {.cdecl.}
    tcl_ListObjLength        : proc(interp: PInterp, listPtr: PObj, lengthPtr: var Size): cint {.cdecl.}
    tcl_NewDoubleObj         : proc(doubleValue: cdouble): PObj {.cdecl.}
    tcl_NewWideIntObj        : proc(wideValue: WideInt): PObj {.cdecl.}
    tcl_NewListObj           : proc(objc: Size, objv: PPObj): PObj {.cdecl.}
    tcl_NewStringObj         : proc(bytes: cstring, length: Size): PObj {.cdecl.}
    tcl_CreateObjCommand     : proc(interp: PInterp, cmdName: cstring, callback: PObjCmdProc, clientData: TClientData, deleteProc: PCmdDeleteProc): PCommand {.cdecl.}
    tcl_SetObjResult         : proc(interp: PInterp, resultObjPtr: PObj) {.cdecl.}
    tcl_DictObjPut           : proc(interp: PInterp, dictPtr: PObj, keyPtr: PObj, valuePtr: PObj): cint {.cdecl.}
    tcl_NewDictObj           : proc(): PObj {.cdecl.}
    tcl_CreateNamespace      : proc(interp: PInterp, name: cstring, clientData: TClientData, deleteProc: PNamespaceDeleteProc): PNamespace {.cdecl.}
    tcl_FindNamespace        : proc(interp: PInterp, name: cstring, contextNsPtr: PNamespace, flags: cint): PNamespace {.cdecl.}
    tcl_WrongNumArgs         : proc(interp: PInterp, objc: Size, objv: PPObj, message: cstring) {.cdecl.}
    tcl_GetObjResult         : proc(interp: PInterp): PObj {.cdecl.}
    tcl_NewByteArrayObj      : proc(bytes: cstring, length: Size): PObj {.cdecl.}
    tcl_EvalObjv             : proc(interp: PInterp, objc: Size, objv: PPObj, flags: cint): cint {.cdecl.}
    tcl_Panic                : proc(format: cstring) {.cdecl.}
    tcl_VarEval              : proc(interp: PInterp): cint {.cdecl.}
    tcl_EvalEx               : proc(interp: PInterp, script: cstring, numBytes: Size, flags: cint): cint {.cdecl.}
    when defined(tcl9):
      tcl_IncrRefCount       : proc(objPtr: PObj) {.cdecl.}
      tcl_DecrRefCount       : proc(objPtr: PObj) {.cdecl.}
    when defined(tcl8):
      tcl_NewIntObj          : proc(intValue: cint): PObj {.cdecl.}
      tcl_NewBooleanObj      : proc(intValue: cint): PObj {.cdecl.}
      tcl_Eval               : proc(interp: PInterp, script: cstring): cint {.cdecl.}

var tclStubsPtr {.importc: "tclStubsPtr", header: "tclDecls.h".} : ptr TclStubs

proc PkgProvideEx*(interp: PInterp, name: cstring, version: cstring, clientData: TClientData): cint =
  return tclStubsPtr.tcl_PkgProvideEx(interp, name, version, clientData)

proc GetBooleanFromObj*(interp: PInterp, objPtr: PObj, boolPtr: var cint): cint =
  return tclStubsPtr.tcl_GetBooleanFromObj(interp, objPtr, boolPtr)

proc GetDoubleFromObj*(interp: PInterp, objPtr: PObj, doublePtr: var cdouble): cint =
  return tclStubsPtr.tcl_GetDoubleFromObj(interp, objPtr, doublePtr)

proc GetIntFromObj*(interp: PInterp, objPtr: PObj, intPtr: var cint): cint =
  return tclStubsPtr.tcl_GetIntFromObj(interp, objPtr, intPtr)

proc GetString*(objPtr: PObj): cstring =
  return tclStubsPtr.tcl_GetString(objPtr)

proc ListObjAppendElement*(interp: PInterp, listPtr: PObj, objPtr: PObj): cint =
  return tclStubsPtr.tcl_ListObjAppendElement(interp, listPtr, objPtr)

proc ListObjGetElements*(interp: PInterp, listPtr: PObj, lengthPtr: var Size, objvPtr: var PPObj): cint =
  return tclStubsPtr.tcl_ListObjGetElements(interp, listPtr, lengthPtr, objvPtr)

proc ListObjLength*(interp: PInterp, listPtr: PObj, lengthPtr: var Size): cint =
  return tclStubsPtr.tcl_ListObjLength(interp, listPtr, lengthPtr)

proc NewDoubleObj*(doubleValue: cdouble): PObj =
  return tclStubsPtr.tcl_NewDoubleObj(doubleValue)

proc NewWideIntObj*(wideValue: WideInt): PObj =
  return tclStubsPtr.tcl_NewWideIntObj(wideValue)

proc NewListObj*(objc: Size, objv: PPObj): PObj =
  return tclStubsPtr.tcl_NewListObj(objc, objv)

proc NewStringObj*(bytes: cstring, length: Size): PObj =
  return tclStubsPtr.tcl_NewStringObj(bytes, length)

proc CreateObjCommand*(interp: PInterp, cmdName: cstring, callback: PObjCmdProc, clientData: TClientData, deleteProc: PCmdDeleteProc): PCommand =
  return tclStubsPtr.tcl_CreateObjCommand(interp, cmdName, callback, clientData, deleteProc)

proc SetObjResult*(interp: PInterp, resultObjPtr: PObj) =
  tclStubsPtr.tcl_SetObjResult(interp, resultObjPtr)

proc DictObjPut*(interp: PInterp, dictPtr: PObj, keyPtr: PObj, valuePtr: PObj): cint =
  return tclStubsPtr.tcl_DictObjPut(interp, dictPtr, keyPtr, valuePtr)

proc NewDictObj*(): PObj =
  return tclStubsPtr.tcl_NewDictObj()

proc CreateNamespace*(interp: PInterp, name: cstring, clientData: TClientData, deleteProc: PNamespaceDeleteProc): PNamespace =
  return tclStubsPtr.tcl_CreateNamespace(interp, name, clientData, deleteProc)

proc FindNamespace*(interp: PInterp, name: cstring, contextNsPtr: PNamespace, flags: cint): PNamespace =
  return tclStubsPtr.tcl_FindNamespace(interp, name, contextNsPtr, flags)

proc WrongNumArgs*(interp: PInterp, argc: cint, objv: PPObj, message: cstring) =
  tclStubsPtr.tcl_WrongNumArgs(interp, argc, objv, message)

proc GetObjResult*(interp: PInterp): PObj =
  return tclStubsPtr.tcl_GetObjResult(interp)

proc NewByteArrayObj*(bytes: cstring, length: Size): PObj =
  return tclStubsPtr.tcl_NewByteArrayObj(bytes, length)

proc EvalObjv*(interp: PInterp, objc: Size, objv: PPObj, flags: cint): cint =
  return tclStubsPtr.tcl_EvalObjv(interp, objc, objv, flags)

proc Panic*(format: cstring) {.varargs, noreturn.} =
  tclStubsPtr.tcl_Panic(format)

proc VarEval*(interp: PInterp): cint {.varargs.} =
  return tclStubsPtr.tcl_VarEval(interp)

proc EvalEx*(interp: PInterp, script: cstring, numBytes: Size, flags: cint): cint =
  tclStubsPtr.tcl_EvalEx(interp, script, numBytes, flags)

when defined(tcl8):
  proc NewIntObj*(intValue: cint): PObj =
    return tclStubsPtr.tcl_NewIntObj(intValue)

  proc NewBooleanObj*(intValue: cint): PObj =
    return tclStubsPtr.tcl_NewBooleanObj(intValue)

  proc Eval*(interp: PInterp, script: cstring): cint =
    return tclStubsPtr.tcl_Eval(interp, script)

  proc IncrRefCount*(objPtr: PObj) {.cdecl, importc: "Tcl_IncrRefCount", header: "tcl.h".}
  proc DecrRefCount*(objPtr: PObj) {.cdecl, importc: "Tcl_DecrRefCount", header: "tcl.h".}

when defined(tcl9):
  proc IncrRefCount*(objPtr: PObj) =
    tclStubsPtr.tcl_IncrRefCount(objPtr)

  proc DecrRefCount*(objPtr: PObj) =
    tclStubsPtr.tcl_DecrRefCount(objPtr)

  proc Eval*(interp: PInterp, script: cstring): cint =
    return EvalEx(interp, script, TCL_INDEX_NONE, 0)

  template NewIntObj*(value: untyped)       : untyped = NewWideIntObj(WideInt(value))
  template NewBooleanObj*(intValue: untyped): untyped = NewWideIntObj(WideInt(if intValue != 0: 1 else: 0))

proc GetStringResult*(interp: PInterp): cstring {.cdecl.} =
  return GetString(GetObjResult(interp))

proc tclInitStubs(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tcl_InitStubs", header: "tcl.h".}

proc InitStubs*(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  return tclInitStubs(interp, version, exact)