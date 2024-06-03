# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_draw_surface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var img: Image

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '<img>|<ctx>' 'photo'"
      Tcl.SetResult(interp, mess.cstring , nil)
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
    var imgData = cast[ptr UncheckedArray[uint8]](img.data[0].addr)

    var i = 0
    while i < (img.width * img.height * 4):
      let a = float(imgData[i+3]) / 255.0;
      imgData[i+0] = uint8(float(imgData[i + 0]) / a + 0.5)
      imgData[i+1] = uint8(float(imgData[i + 1]) / a + 0.5)
      imgData[i+2] = uint8(float(imgData[i + 2]) / a + 0.5)
      inc(i, 4)

    pblock.pixelPtr  = imgData
    pblock.width     = int32(img.width)
    pblock.height    = int32(img.height)
    pblock.pitch     = int32(img.width * 4)
    pblock.pixelSize = int32(4)
    pblock.offset    = [0, 1, 2, 3]

    if Tk.PhotoSetSize(interp, source, pblock.width, pblock.height) != Tcl.OK:
      return Tcl.ERROR

    if Tk.PhotoPutBlock(interp, source, pblock.addr, 0, 0, pblock.width, pblock.height, 1) != Tcl.OK:
        return Tcl.ERROR

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
