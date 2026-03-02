# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_draw_surface(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws object to Tk photo.
  # 
  # object - [img] or [ctx] object.
  # photo  - Tk photo variable.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>|<ctx> 'Tk photo'")
    return Tcl.ERROR
  
  let ptable = cast[PixTable](clientData)
  let key = $objv[1]

  let img =
    if ptable.hasContext(key):
      ptable.getContext(key).image
    elif ptable.hasImage(key):
      ptable.getImage(key)
    else:
      return pixUtils.errorMSG(interp,
        "pix(error): unknown <image> or <ctx> key object found: '" & key & "'"
      ) 

  let 
    photosource = Tcl.GetString(objv[2])
    source = Tk.FindPhoto(interp, photosource)

  if source == nil:
    return pixUtils.errorMSG(interp, "pix(error): photo not found")

  let
    size = img.width * img.height * 4
    imgDataCopy = img.data

  var
    pblock : Tk.PhotoImageBlock
    imgData = cast[ptr UncheckedArray[uint8]](imgDataCopy[0].addr)

  {.push checks: off.}
  for offset in countup(0, size - 4, 4):
    let alpha = imgData[offset+3]
    if alpha != 0 and alpha != 255:
      let m = UNMULTIPLY_LUT[alpha]
      imgData[offset+0] = ((imgData[offset+0].uint32 * m + 127) div 255).uint8
      imgData[offset+1] = ((imgData[offset+1].uint32 * m + 127) div 255).uint8
      imgData[offset+2] = ((imgData[offset+2].uint32 * m + 127) div 255).uint8
  {.pop.}

  pblock.pixelPtr  = imgData
  pblock.width     = img.width.cint
  pblock.height    = img.height.cint
  pblock.pitch     = img.width.cint * 4
  pblock.pixelSize = 4
  pblock.offset    = [0, 1, 2, 3]

  if Tk.PhotoSetSize(interp, source, pblock.width, pblock.height) != Tcl.OK:
    return Tcl.ERROR

  if Tk.PhotoPutBlock(
    interp, source, pblock.addr, 0, 0, pblock.width, pblock.height,
    Tk.PHOTO_COMPOSITE_SET
  ) != Tcl.OK:
    return Tcl.ERROR

  return Tcl.OK