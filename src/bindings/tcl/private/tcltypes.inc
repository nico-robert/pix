const
  OK*    = 0
  ERROR* = 1
  
when defined(tcl9):
  const VERSION* = "9.0"
  type Size* = int
else:
  const VERSION* = "8.6"
  type Size* = int32 

type
  PInterp* = ptr TInterp
  TInterp*{.final.} = object
  TClientData* = pointer
  PNamespaceDeleteProc = pointer
  TNamespaceDeleteProc* = proc (clientData: TClientData){.cdecl.}
  PNamespace* = ptr TNamespace

  TNamespace*{.final.} = object 
    name*: cstring
    fullName*: cstring
    clientData*: TClientData
    deleteProc*: TNamespaceDeleteProc
    parentPtr*: PNamespace
  
  PObj* = ptr TObj
  PPObj* = ptr UncheckedArray[PObj]

  TObj*{.final.} = object
    refCount*: int

  WideInt*         = clonglong
  Command*         = pointer
  PObjCmdProc*     = pointer
  PCmdDeleteProc*  = pointer
  PClientData*     = ptr TClientData