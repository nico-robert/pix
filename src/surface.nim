# Copyright (c) 2024 Nicolas ROBERT.
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

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let str = $arg1

    if str[^3..^1] == "ctx":
      let ctx = ctxTable[$str]
      img = ctx.image
    else:
      img = imgTable[$str]

    let photosource = Tcl.GetStringFromObj(objv[2], nil)
    let source = Tk.FindPhoto(interp, photosource)

    if source == nil:
      Tcl.SetResult(interp, "photo not found", nil)
      return Tcl.ERROR

    var pblock: Tk.PhotoImageBlock
    var imgData  = cast[ptr UncheckedArray[uint8]](alloc(img.width * img.height * 4))
    let imgpixie = cast[ptr UncheckedArray[uint8]](img.data[0].addr)

    var i = 0
    while i < (img.width * img.height * 4):
      let a = float(imgpixie[i+3]) / 255.0
      imgData[i+0] = uint8(float(imgpixie[i+0]) / a + 0.5)
      imgData[i+1] = uint8(float(imgpixie[i+1]) / a + 0.5)
      imgData[i+2] = uint8(float(imgpixie[i+2]) / a + 0.5)
      imgData[i+3] = imgpixie[i+3]
      inc(i, 4)

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
    
    if imgData != nil:
      dealloc(imgData)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
