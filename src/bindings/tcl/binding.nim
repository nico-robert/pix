# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import ./tcltypes as Tcl
export Tcl

type
  TclStubs {.importc.} = object
    tcl_PkgProvideEx         : proc(interp: Tcl.PInterp, name: cstring, version: cstring, clientData: Tcl.TClientData): cint {.cdecl.}
    tcl_GetBooleanFromObj    : proc(interp: Tcl.PInterp, objPtr: Tcl.PObj, boolPtr: var cint): cint {.cdecl.}
    tcl_GetDoubleFromObj     : proc(interp: Tcl.PInterp, objPtr: Tcl.PObj, doublePtr: var cdouble): cint {.cdecl.}
    tcl_GetIntFromObj        : proc(interp: Tcl.PInterp, objPtr: Tcl.PObj, intPtr: var cint): cint {.cdecl.}
    tcl_GetString            : proc(objPtr: Tcl.PObj): cstring {.cdecl.}
    tcl_ListObjAppendElement : proc(interp: Tcl.PInterp, listPtr: Tcl.PObj, objPtr: Tcl.PObj): cint {.cdecl.}
    tcl_ListObjGetElements   : proc(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size, objvPtr: var Tcl.PPObj): cint {.cdecl.}
    tcl_ListObjLength        : proc(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size): cint {.cdecl.}
    tcl_NewDoubleObj         : proc(doubleValue: cdouble): Tcl.PObj {.cdecl.}
    tcl_NewWideIntObj        : proc(wideValue: WideInt): Tcl.PObj {.cdecl.}
    tcl_NewListObj           : proc(objc: Tcl.Size, objv: Tcl.PPObj): Tcl.PObj {.cdecl.}
    tcl_NewStringObj         : proc(bytes: cstring, length: Tcl.Size): Tcl.PObj {.cdecl.}
    tcl_CreateObjCommand     : proc(interp: Tcl.PInterp, cmdName: cstring, callback: Tcl.PObjCmdProc, clientData: Tcl.TClientData, deleteProc: Tcl.PCmdDeleteProc): Tcl.PCommand {.cdecl.}
    tcl_SetObjResult         : proc(interp: Tcl.PInterp, resultObjPtr: Tcl.PObj) {.cdecl.}
    tcl_DictObjPut           : proc(interp: Tcl.PInterp, dictPtr: Tcl.PObj, keyPtr: Tcl.PObj, valuePtr: Tcl.PObj): cint {.cdecl.}
    tcl_NewDictObj           : proc(): Tcl.PObj {.cdecl.}
    tcl_CreateNamespace      : proc(interp: Tcl.PInterp, name: cstring, clientData: Tcl.TClientData, deleteProc: Tcl.PNamespaceDeleteProc): Tcl.PNamespace {.cdecl.}
    tcl_FindNamespace        : proc(interp: Tcl.PInterp, name: cstring, contextNsPtr: Tcl.PNamespace, flags: cint): Tcl.PNamespace {.cdecl.}
    tcl_WrongNumArgs         : proc(interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj, message: cstring) {.cdecl.}
    tcl_GetObjResult         : proc(interp: Tcl.PInterp): Tcl.PObj {.cdecl.}
    tcl_NewByteArrayObj      : proc(bytes: cstring, length: Tcl.Size): Tcl.PObj {.cdecl.}
    tcl_EvalObjv             : proc(interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj, flags: cint): cint {.cdecl.}
    tcl_Panic                : proc(format: cstring) {.cdecl.}
    tcl_VarEval              : proc(interp: Tcl.PInterp): cint {.cdecl.}
    tcl_EvalEx               : proc(interp: Tcl.PInterp, script: cstring, numBytes: Tcl.Size, flags: cint): cint {.cdecl.}
    tcl_RegisterObjType      : proc(typePtr: Tcl.PObjType) {.cdecl.}
    tcl_InvalidateStringRep  : proc(objPtr: Tcl.PObj) {.cdecl.}
    tcl_NewObj               : proc(): Tcl.PObj {.cdecl.}
    tcl_GetObjType           : proc(typeName: cstring): Tcl.PObjType {.cdecl.}
    tcl_Alloc                : proc(size: Tcl.HASH_TYPE): pointer {.cdecl.}
    when defined(tcl9):
      tcl_IncrRefCount       : proc(objPtr: Tcl.PObj) {.cdecl.}
      tcl_DecrRefCount       : proc(objPtr: Tcl.PObj) {.cdecl.}
      tcl_FetchInternalRep   : proc(objPtr: Tcl.PObj, typePtr: Tcl.PObjType): Tcl.PObjInternalRep {.cdecl.}
      tcl_StoreInternalRep   : proc(objPtr: Tcl.PObj, typePtr: Tcl.PObjType, irPtr: Tcl.PObjInternalRep) {.cdecl.}
    when defined(tcl8):
      tcl_NewIntObj          : proc(intValue: cint): Tcl.PObj {.cdecl.}
      tcl_NewBooleanObj      : proc(intValue: cint): Tcl.PObj {.cdecl.}
      tcl_Eval               : proc(interp: Tcl.PInterp, script: cstring): cint {.cdecl.}

var tclStubsPtr {.importc: "tclStubsPtr", header: "tclDecls.h".} : ptr TclStubs

proc PkgProvideEx*(interp: Tcl.PInterp, name: cstring, version: cstring, clientData: Tcl.TClientData): cint =
  return tclStubsPtr.tcl_PkgProvideEx(interp, name, version, clientData)

proc GetBooleanFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, boolPtr: var cint): cint =
  return tclStubsPtr.tcl_GetBooleanFromObj(interp, objPtr, boolPtr)

proc GetDoubleFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, doublePtr: var cdouble): cint =
  return tclStubsPtr.tcl_GetDoubleFromObj(interp, objPtr, doublePtr)

proc GetIntFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, intPtr: var cint): cint =
  return tclStubsPtr.tcl_GetIntFromObj(interp, objPtr, intPtr)

proc GetString*(objPtr: Tcl.PObj): cstring =
  return tclStubsPtr.tcl_GetString(objPtr)

proc ListObjAppendElement*(interp: Tcl.PInterp, listPtr: Tcl.PObj, objPtr: Tcl.PObj): cint =
  return tclStubsPtr.tcl_ListObjAppendElement(interp, listPtr, objPtr)

proc ListObjGetElements*(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size, objvPtr: var Tcl.PPObj): cint =
  return tclStubsPtr.tcl_ListObjGetElements(interp, listPtr, lengthPtr, objvPtr)

proc ListObjLength*(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size): cint =
  return tclStubsPtr.tcl_ListObjLength(interp, listPtr, lengthPtr)

proc NewDoubleObj*(doubleValue: cdouble): Tcl.PObj =
  return tclStubsPtr.tcl_NewDoubleObj(doubleValue)

proc NewWideIntObj*(wideValue: WideInt): Tcl.PObj =
  return tclStubsPtr.tcl_NewWideIntObj(wideValue)

proc NewListObj*(objc: Tcl.Size, objv: Tcl.PPObj): Tcl.PObj =
  return tclStubsPtr.tcl_NewListObj(objc, objv)

proc NewStringObj*(bytes: cstring, length: Tcl.Size): Tcl.PObj =
  return tclStubsPtr.tcl_NewStringObj(bytes, length)

proc CreateObjCommand*(interp: Tcl.PInterp, cmdName: cstring, callback: Tcl.PObjCmdProc, clientData: Tcl.TClientData, deleteProc: Tcl.PCmdDeleteProc): Tcl.PCommand =
  return tclStubsPtr.tcl_CreateObjCommand(interp, cmdName, callback, clientData, deleteProc)

proc SetObjResult*(interp: Tcl.PInterp, resultObjPtr: Tcl.PObj) =
  tclStubsPtr.tcl_SetObjResult(interp, resultObjPtr)

proc DictObjPut*(interp: Tcl.PInterp, dictPtr: Tcl.PObj, keyPtr: Tcl.PObj, valuePtr: Tcl.PObj): cint =
  return tclStubsPtr.tcl_DictObjPut(interp, dictPtr, keyPtr, valuePtr)

proc NewDictObj*(): Tcl.PObj =
  return tclStubsPtr.tcl_NewDictObj()

proc CreateNamespace*(interp: Tcl.PInterp, name: cstring, clientData: Tcl.TClientData, deleteProc: Tcl.PNamespaceDeleteProc): Tcl.PNamespace =
  return tclStubsPtr.tcl_CreateNamespace(interp, name, clientData, deleteProc)

proc FindNamespace*(interp: Tcl.PInterp, name: cstring, contextNsPtr: Tcl.PNamespace, flags: cint): Tcl.PNamespace =
  return tclStubsPtr.tcl_FindNamespace(interp, name, contextNsPtr, flags)

proc WrongNumArgs*(interp: Tcl.PInterp, argc: cint, objv: Tcl.PPObj, message: cstring) =
  tclStubsPtr.tcl_WrongNumArgs(interp, argc, objv, message)

proc GetObjResult*(interp: Tcl.PInterp): Tcl.PObj =
  return tclStubsPtr.tcl_GetObjResult(interp)

proc NewByteArrayObj*(bytes: cstring, length: Tcl.Size): Tcl.PObj =
  return tclStubsPtr.tcl_NewByteArrayObj(bytes, length)

proc EvalObjv*(interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj, flags: cint): cint =
  return tclStubsPtr.tcl_EvalObjv(interp, objc, objv, flags)

proc Panic*(format: cstring) {.varargs, noreturn.} =
  tclStubsPtr.tcl_Panic(format)

proc VarEval*(interp: Tcl.PInterp): cint {.varargs.} =
  return tclStubsPtr.tcl_VarEval(interp)

proc EvalEx*(interp: Tcl.PInterp, script: cstring, numBytes: Tcl.Size, flags: cint): cint =
  tclStubsPtr.tcl_EvalEx(interp, script, numBytes, flags)

proc RegisterObjType*(typePtr: Tcl.PObjType) =
  tclStubsPtr.tcl_RegisterObjType(typePtr)

proc InvalidateStringRep*(objPtr: Tcl.PObj) =
  tclStubsPtr.tcl_InvalidateStringRep(objPtr)

proc NewObj*(): Tcl.PObj =
  return tclStubsPtr.tcl_NewObj()

proc GetObjType*(typeName: cstring): Tcl.PObjType =
  return tclStubsPtr.tcl_GetObjType(typeName)

proc Alloc*(size: Tcl.HASH_TYPE): pointer =
  return tclStubsPtr.tcl_Alloc(size)

proc GetStringResult*(interp: Tcl.PInterp): cstring {.cdecl.} =
  return GetString(GetObjResult(interp))

proc `$`*(obj: Tcl.PObj): string =
  let s = GetString(obj)
  if s.isNil:
    return ""
  return $s

proc `$`*(interp: Tcl.PInterp): string =
  let s = GetStringResult(interp)
  if s.isNil:
    return ""
  return $s

when defined(tcl8):
  proc NewIntObj*(intValue: cint): Tcl.PObj =
    return tclStubsPtr.tcl_NewIntObj(intValue)

  proc NewBooleanObj*(intValue: cint): Tcl.PObj =
    return tclStubsPtr.tcl_NewBooleanObj(intValue)

  proc Eval*(interp: Tcl.PInterp, script: cstring): cint =
    return tclStubsPtr.tcl_Eval(interp, script)

  proc IncrRefCount*(objPtr: Tcl.PObj) {.cdecl, importc: "Tcl_IncrRefCount", header: "tcl.h".}
  proc DecrRefCount*(objPtr: Tcl.PObj) {.cdecl, importc: "Tcl_DecrRefCount", header: "tcl.h".}

when defined(tcl9):
  proc IncrRefCount*(objPtr: Tcl.PObj) =
    tclStubsPtr.tcl_IncrRefCount(objPtr)

  proc DecrRefCount*(objPtr: Tcl.PObj) =
    tclStubsPtr.tcl_DecrRefCount(objPtr)

  proc FetchInternalRep*(objPtr: Tcl.PObj, typePtr: Tcl.PObjType): Tcl.PObjInternalRep =
    tclStubsPtr.tcl_FetchInternalRep(objPtr, typePtr)

  proc StoreInternalRep*(objPtr: Tcl.PObj, typePtr: Tcl.PObjType, irPtr: Tcl.PObjInternalRep) =
    tclStubsPtr.tcl_StoreInternalRep(objPtr, typePtr, irPtr)

  proc Eval*(interp: Tcl.PInterp, script: cstring): cint =
    return EvalEx(interp, script, TCL.INDEX_NONE, 0)

  template NewIntObj*(value: untyped)       : untyped = NewWideIntObj(WideInt(value))
  template NewBooleanObj*(intValue: untyped): untyped = NewWideIntObj(WideInt(if intValue != 0: 1 else: 0))

proc tclInitStubs(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tcl_InitStubs", header: "tcl.h".}

proc InitStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  return tclInitStubs(interp, version, exact)