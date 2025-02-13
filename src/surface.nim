# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_draw_surface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws object to Tk photo.
  # 
  # object - image or context
  #
  # Returns nothing.
  try:
    var img: Image

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>|<ctx> 'Tk photo'")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])

    if ctxTable.hasKey($arg1):
      let ctx = ctxTable[$arg1]
      img = ctx.image
    else:
      img = imgTable[$arg1]

    let photosource = Tcl.GetString(objv[2])
    let source = Tk.FindPhoto(interp, photosource)

    if source == nil:
      return ERROR_MSG(interp, "pix(error): photo not found")

    var pblock {.noinit.}: Tk.PhotoImageBlock
    var imgData = cast[ptr UncheckedArray[uint8]](img.data[0].addr)
    let size = img.width * img.height * 4

    {.push checks: off.}
    for offset in countup(0, size - 4, 4):
      let alpha = imgData[offset+3]
      if alpha != 0 and alpha != 255:
        let multiplier = round((255 / alpha.float32) * 255).uint32
        imgData[offset+0] = ((imgData[offset+0].uint32 * multiplier + 127) div 255).uint8
        imgData[offset+1] = ((imgData[offset+1].uint32 * multiplier + 127) div 255).uint8
        imgData[offset+2] = ((imgData[offset+2].uint32 * multiplier + 127) div 255).uint8
    {.pop.}

    pblock.pixelPtr  = imgData
    pblock.width     = int32(img.width)
    pblock.height    = int32(img.height)
    pblock.pitch     = int32(img.width * 4)
    pblock.pixelSize = int32(4)
    pblock.offset    = [0, 1, 2, 3]

    if Tk.PhotoSetSize(interp, source, pblock.width, pblock.height) != Tcl.OK:
      return Tcl.ERROR

    if Tk.PhotoPutBlock(interp, source, pblock.addr, 0, 0, pblock.width, pblock.height, Tk.PHOTO_COMPOSITE_SET) != Tcl.OK:
        return Tcl.ERROR

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)