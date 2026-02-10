# Copyright (c) 2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import ../bindings/tcl/binding as Tcl
import chroma

proc freeColorIntRep(objPtr: Tcl.PObj) {.cdecl.} =
  # Free the internal representation of a color object
  #
  # objPtr - The Tcl object to free.
  #
  # Returns: Nothing.
  if objPtr.isNil: return
  let colorObjType = Tcl.GetObjType("pixcolor")

  if colorObjType.isNil or objPtr.typePtr != colorObjType:
    return

  let color = cast[ptr Color](objPtr.internalRep.otherValuePtr)

  # Free the color object
  if not color.isNil:
    dealloc(color)

proc dupColorIntRep(srcPtr: Tcl.PObj, dupPtr: Tcl.PObj) {.cdecl.} =
  # Duplicate the internal representation of a color object
  #
  # srcPtr - The source Tcl object to duplicate.
  # dupPtr - The destination Tcl object to duplicate into.
  #
  # Returns: Nothing.

  let srcColor = cast[ptr Color](srcPtr.internalRep.otherValuePtr)
  let dupColor = cast[ptr Color](alloc(sizeof(Color)))

  # Copy the color object
  dupColor[] = srcColor[]

  let colorObjType = Tcl.GetObjType("pixcolor")

  # Set the destination object type and internal representation
  dupPtr.typePtr = colorObjType
  dupPtr.internalRep.otherValuePtr = dupColor

proc updateColorString(objPtr: Tcl.PObj) {.cdecl.} =
  # Update the string representation of a color object
  #
  # objPtr - The Tcl object to update.
  #
  # Returns: Nothing.

  let color = cast[ptr Color](objPtr.internalRep.otherValuePtr)
  if color.isNil: return

  let str = $color[]
  let strLen = str.len
  let bytes = cast[cstring](Tcl.Alloc(Tcl.HASH_TYPE(strLen + 1)))
  copyMem(bytes, cstring(str), strLen + 1)

  objPtr.bytes = bytes
  objPtr.length = Tcl.Size(strLen)

proc setColorFromAny(interp: Tcl.PInterp, objPtr: Tcl.PObj): cint {.cdecl.} =
  # Sets a new color object.
  #
  # interp - The Tcl interpreter.
  # objPtr - The Tcl object to set.
  #
  # Returns : Tcl.OK - If the object was successfully set or
  #           Tcl.ERROR - If the object could not be set.
  if objPtr.bytes.isNil:
    return Tcl.ERROR

  try:
    let colorStr = $objPtr.bytes
    # Parse the color string
    let color = parseHex(colorStr)

    if objPtr.typePtr != nil and objPtr.typePtr.freeIntRepProc != nil:
      objPtr.typePtr.freeIntRepProc(objPtr)

    let newColor = cast[ptr Color](alloc(sizeof(Color)))
    newColor[] = color

    # Get the color object type
    let colorObjType = Tcl.GetObjType("pixcolor")
    objPtr.typePtr = colorObjType
    objPtr.internalRep.otherValuePtr = newColor

    return Tcl.OK
  except Exception as e:
    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(e.msg), -1))
    return Tcl.ERROR

proc fetchInternalRep(objPtr: Tcl.PObj, typePtr: Tcl.PObjType): Tcl.PObjInternalRep {.cdecl.} =
  # Fetches the internal representation of a Tcl object.
  #
  # objPtr   - The Tcl object to fetch the internal representation from.
  # typePtr  - The type of the object to fetch the internal representation from.
  #
  # Returns: The internal representation of the object, or nil if
  #          the object type does not match the type pointer.

  when defined(tcl9):
    return Tcl.FetchInternalRep(objPtr, typePtr)
  else:
    if objPtr.typePtr == typePtr:
      return addr objPtr.internalRep
    return nil

proc storeInternalRep(objPtr: Tcl.PObj, typePtr: Tcl.PObjType, irPtr: Tcl.PObjInternalRep) =
  # Store a new internal representation for a Tcl object.
  #
  # objPtr    - The Tcl object to store the internal representation in.
  # typePtr   - The type of the object to store the internal representation in.
  # irPtr     - The internal representation to store.
  #
  # This function is used to store a new internal representation for a Tcl object.
  # If the object already has an internal representation, it is freed.
  # If the object has a string representation, it is invalidated.
  #
  # Returns: Nothing.
  when defined(tcl9):
    Tcl.StoreInternalRep(objPtr, typePtr, irPtr)
  else:
    if objPtr.typePtr != nil and objPtr.typePtr.freeIntRepProc != nil:
      objPtr.typePtr.freeIntRepProc(objPtr)

    if objPtr.bytes != nil:
      Tcl.InvalidateStringRep(objPtr)

    objPtr.typePtr = typePtr
    objPtr.internalRep = irPtr[]

proc createColorObj*(color: Color): Tcl.PObj =
  # Creates a new color object.
  #
  # color - The color to create the object from.
  #
  # Returns: A new color object.
  let obj = Tcl.NewObj()

  let colorObjType = Tcl.GetObjType("pixcolor")
  if colorObjType.isNil:
    return nil

  let colorPtr = cast[ptr Color](alloc(sizeof(Color)))
  colorPtr[] = color

  # Create a new internal representation
  var ir: Tcl.TObjInternalRep
  ir.otherValuePtr = colorPtr
  storeInternalRep(obj, colorObjType, addr ir)

  updateColorString(obj)

  return obj

proc getTypeColor*(objPtr: Tcl.PObj): ptr Color =
  # Gets the internal representation of a color object.
  #
  # objPtr - The Tcl object to retrieve the internal representation of.
  #
  # Returns: A pointer to the internal representation of the color object.
  if objPtr.isNil:
    return nil

  let colorObjType = Tcl.GetObjType("pixcolor")
  if colorObjType.isNil:
    return nil

  let irPtr = fetchInternalRep(objPtr, colorObjType)
  if irPtr.isNil:
    return nil

  let colorPtr = cast[ptr Color](irPtr.otherValuePtr)
  if colorPtr.isNil:
    return nil

  return colorPtr

proc createPixColorObjType*(interp: Tcl.PInterp): Tcl.PObjType =
  # Create the Tcl object type for a color object.
  #
  # interp - The Tcl interpreter.
  #
  # Returns: A pointer to the Tcl object type for a color object.

  # Allocate memory for the Tcl object type
  let colorObjType = cast[Tcl.PObjType](alloc0(sizeof(Tcl.ObjType)))

  if colorObjType == nil:
    let errormsg = "pix(error): Could not allocate memory for Tcl ObjType."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
    return nil

  colorObjType.name = "pixcolor"
  colorObjType.freeIntRepProc = freeColorIntRep
  colorObjType.dupIntRepProc = dupColorIntRep
  colorObjType.updateStringProc = updateColorString
  colorObjType.setFromAnyProc = setColorFromAny

  return colorObjType
