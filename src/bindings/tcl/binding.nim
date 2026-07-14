# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import ./types as Tcl
export Tcl

var tclVersion    {.importc: "TCL_VERSION", header: "tcl.h".}: cstring
var tclPatchLevel {.importc: "TCL_PATCH_LEVEL", header: "tcl.h".}: cstring

proc VERSION*(): string     = return $tclVersion
proc PATCH_LEVEL*(): string = return $tclPatchLevel

proc PkgProvideEx*(interp: Tcl.PInterp, name: cstring, version: cstring, clientData: Tcl.TClientData): cint
  {.cdecl, importc: "Tcl_PkgProvideEx", header: "tcl.h".}

proc GetBooleanFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, boolPtr: var cint): cint
  {.cdecl, importc: "Tcl_GetBooleanFromObj", header: "tcl.h".}

proc GetDoubleFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, doublePtr: var cdouble): cint
  {.cdecl, importc: "Tcl_GetDoubleFromObj", header: "tcl.h".}

proc GetIntFromObj*(interp: Tcl.PInterp, objPtr: Tcl.PObj, intPtr: var cint): cint
  {.cdecl, importc: "Tcl_GetIntFromObj", header: "tcl.h".}

proc GetString*(objPtr: Tcl.PObj): cstring
  {.cdecl, importc: "Tcl_GetString", header: "tcl.h".}

proc ListObjAppendElement*(interp: Tcl.PInterp, listPtr: Tcl.PObj, objPtr: Tcl.PObj): cint
  {.cdecl, importc: "Tcl_ListObjAppendElement", header: "tcl.h".}

proc ListObjGetElements*(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size, objvPtr: var Tcl.PPObj): cint
  {.cdecl, importc: "Tcl_ListObjGetElements", header: "tcl.h".}

proc ListObjLength*(interp: Tcl.PInterp, listPtr: Tcl.PObj, lengthPtr: var Tcl.Size): cint
  {.cdecl, importc: "Tcl_ListObjLength", header: "tcl.h".}

proc NewDoubleObj*(doubleValue: cdouble): Tcl.PObj
  {.cdecl, importc: "Tcl_NewDoubleObj", header: "tcl.h".}

proc NewWideIntObj*(wideValue: Tcl.WideInt): Tcl.PObj
  {.cdecl, importc: "Tcl_NewWideIntObj", header: "tcl.h".}

proc NewListObj*(objc: Tcl.Size, objv: Tcl.PPObj): Tcl.PObj
  {.cdecl, importc: "Tcl_NewListObj", header: "tcl.h".}

proc NewStringObj*(bytes: cstring, length: Tcl.Size): Tcl.PObj
  {.cdecl, importc: "Tcl_NewStringObj", header: "tcl.h".}

proc CreateObjCommand*(interp: Tcl.PInterp, cmdName: cstring, callback: Tcl.PObjCmdProc, clientData: Tcl.TClientData, deleteProc: Tcl.PCmdDeleteProc): Tcl.PCommand
  {.cdecl, importc: "Tcl_CreateObjCommand", header: "tcl.h".}

proc SetObjResult*(interp: Tcl.PInterp, resultObjPtr: Tcl.PObj)
  {.cdecl, importc: "Tcl_SetObjResult", header: "tcl.h".}

proc DictObjPut*(interp: Tcl.PInterp, dictPtr: Tcl.PObj, keyPtr: Tcl.PObj, valuePtr: Tcl.PObj): cint
  {.cdecl, importc: "Tcl_DictObjPut", header: "tcl.h".}

proc NewDictObj*(): Tcl.PObj
  {.cdecl, importc: "Tcl_NewDictObj", header: "tcl.h".}

proc CreateNamespace*(interp: Tcl.PInterp, name: cstring, clientData: Tcl.TClientData, deleteProc: Tcl.PNamespaceDeleteProc): Tcl.PNamespace
  {.cdecl, importc: "Tcl_CreateNamespace", header: "tcl.h".}

proc FindNamespace*(interp: Tcl.PInterp, name: cstring, contextNsPtr: Tcl.PNamespace, flags: cint): Tcl.PNamespace
  {.cdecl, importc: "Tcl_FindNamespace", header: "tcl.h".}

proc WrongNumArgs*(interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj, message: cstring)
  {.cdecl, importc: "Tcl_WrongNumArgs", header: "tcl.h".}

proc GetObjResult*(interp: Tcl.PInterp): Tcl.PObj
  {.cdecl, importc: "Tcl_GetObjResult", header: "tcl.h".}

proc NewByteArrayObj*(bytes: pointer, length: Tcl.Size): Tcl.PObj
  {.cdecl, importc: "Tcl_NewByteArrayObj", header: "tcl.h".}

proc EvalObjv*(interp: Tcl.PInterp, objc: Tcl.Size, objv: Tcl.PPObj, flags: cint): cint
  {.cdecl, importc: "Tcl_EvalObjv", header: "tcl.h".}

proc Panic*(format: cstring)
  {.cdecl, varargs, noreturn, importc: "Tcl_Panic", header: "tcl.h".}

proc VarEval*(interp: Tcl.PInterp): cint
  {.cdecl, varargs, importc: "Tcl_VarEval", header: "tcl.h".}

proc EvalEx*(interp: Tcl.PInterp, script: cstring, numBytes: Tcl.Size, flags: cint): cint
  {.cdecl, importc: "Tcl_EvalEx", header: "tcl.h".}

proc RegisterObjType*(typePtr: Tcl.PObjType)
  {.cdecl, importc: "Tcl_RegisterObjType", header: "tcl.h".}

proc InvalidateStringRep*(objPtr: Tcl.PObj)
  {.cdecl, importc: "Tcl_InvalidateStringRep", header: "tcl.h".}

proc NewObj*(): Tcl.PObj
  {.cdecl, importc: "Tcl_NewObj", header: "tcl.h".}

proc GetObjType*(typeName: cstring): Tcl.PObjType
  {.cdecl, importc: "Tcl_GetObjType", header: "tcl.h".}

proc Alloc*(size: Tcl.HASH_TYPE): pointer
  {.cdecl, importc: "Tcl_Alloc", header: "tcl.h".}

proc ObjSetVar2*(interp: Tcl.PInterp, part1Ptr: Tcl.PObj, part2Ptr: Tcl.PObj, newValuePtr: Tcl.PObj, flags: cint): Tcl.PObj
  {.cdecl, importc: "Tcl_ObjSetVar2", header: "tcl.h".}

proc IncrRefCount*(objPtr: Tcl.PObj)
  {.cdecl, importc: "Tcl_IncrRefCount", header: "tcl.h".}

proc DecrRefCount*(objPtr: Tcl.PObj)
  {.cdecl, importc: "Tcl_DecrRefCount", header: "tcl.h".}

when defined(tcl8):
  proc NewIntObj*(intValue: cint): Tcl.PObj
    {.cdecl, importc: "Tcl_NewIntObj", header: "tcl.h".}

  proc NewBooleanObj*(intValue: cint): Tcl.PObj
    {.cdecl, importc: "Tcl_NewBooleanObj", header: "tcl.h".}

  proc Eval*(interp: Tcl.PInterp, script: cstring): cint
    {.cdecl, importc: "Tcl_Eval", header: "tcl.h".}

  proc tclGetByteArrayFromObj(objPtr: Tcl.PObj, lengthPtr: var Tcl.Size): pointer
    {.cdecl, importc: "Tcl_GetByteArrayFromObj", header: "tcl.h".}

when defined(tcl9):
  proc FetchInternalRep*(objPtr: Tcl.PObj, typePtr: Tcl.PObjType): Tcl.PObjInternalRep
    {.cdecl, importc: "Tcl_FetchInternalRep", header: "tcl.h".}

  proc StoreInternalRep*(objPtr: Tcl.PObj, typePtr: Tcl.PObjType, irPtr: Tcl.PObjInternalRep)
    {.cdecl, importc: "Tcl_StoreInternalRep", header: "tcl.h".}

  proc tclGetBytesFromObj(interp: Tcl.PInterp, objPtr: Tcl.PObj, numBytesPtr: var Tcl.Size): pointer
    {.cdecl, importc: "Tcl_GetBytesFromObj", header: "tcl.h".}

  proc Eval*(interp: Tcl.PInterp, script: cstring): cint =
    return EvalEx(interp, script, Tcl.INDEX_NONE, 0)

  template NewIntObj*(value: untyped)       : untyped = NewWideIntObj(Tcl.WideInt(value))
  template NewBooleanObj*(intValue: untyped): untyped = NewWideIntObj(Tcl.WideInt(if intValue != 0: 1 else: 0))

proc GetBytesFromObj*(interp: Tcl.PInterp, obj: Tcl.PObj, length: var Tcl.Size): cstring =
  when defined(tcl9):
    return cast[cstring](tclGetBytesFromObj(interp, obj, length))
  else:
    return cast[cstring](tclGetByteArrayFromObj(obj, length))

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

proc InitStubs*(interp: Tcl.PInterp, version: cstring, exact: cint): cstring
  {.cdecl, importc: "Tcl_InitStubs", header: "tcl.h".}