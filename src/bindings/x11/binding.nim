# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

from pixie import Image, Context
import ../../core/xtypes as X
import ../tcl/binding as Tcl
import ../tk/binding as Tk
import ../../core/pixtables
import ../../core/pixutils as pixUtils
import ../../core/pixparses as pixParses
import times

template timeBody*(name: string, body: untyped): untyped =
  # Measures the time taken to execute a block of code.
  #
  # name - The name of the block.
  # body - The block of code to execute.
  #
  # Returns: The time taken to execute the block in milliseconds.
  let start = cpuTime()
  body
  let elapsed = cpuTime() - start
  echo name, ": ", elapsed * 1000, "ms"

# Instance types that depend on previous definitions
type
  PixImageInstance* = object
    master   : ptr PixImageMaster
    tkwin    : Tk.Window
    width    : cint
    height   : cint
    gc       : X.GC
    ximage   : X.PXImage
    pixmap   : X.Pixmap
    dr       : X.Drawable
    refCount : cint
    dirty    : bool

  PixImageMaster* = object
    imageKey  : string
    image     : pixie.Image
    width     : cint
    height    : cint
    name      : cstring
    instances : ptr PixImageInstance
    cmd       : Tcl.PCommand
    interp    : Tcl.PInterp
    tkMaster  : Tk.ImageMaster

proc xInfo*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Try to get [ctx] or [img] from `key`
  #
  # context or image - [ctx::new] or [img::new]
  #
  # Returns: The instance size of [ctx] or [img].
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>|<img>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Context
  var img: pixie.Image
  let key = $Tcl.GetString(objv[1])
  let newListobj = Tcl.NewListObj(0, nil)

  if ptable.hasContext(key): 
    let ctx = ptable.getContext(key)
    img = ctx.image
  elif ptable.hasImage(key): 
    img = ptable.getImage(key)
  else:
    let errormsg = "wrong # args: unknown <ctx> or <img> key object found: '" & key & "'."
    return pixUtils.errorMSG(interp, errormsg)

  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewIntObj(img.width.cint))
  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewIntObj(img.height.cint))

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_createProc(
  interp        : Tcl.PInterp,
  imageName     : cstring,
  objc          : cint,
  objv          : Tcl.PPObj,
  typePtr       : ptr Tk.ImageType,
  masterPtr     : Tk.ImageMaster,
  clientDataPtr : Tcl.PClientData
): cint {.cdecl.} =

  #  Image creation logic
  var width, height: cint
  
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "image create pix ?name -data (<img>|<ctx>)")
    return Tcl.ERROR
  
  if $Tcl.GetString(objv[0]) != "-data":
    let errormsg = "wrong # args: '-data' should present in a image create pix command."
    return pixUtils.errorMSG(interp, errormsg)
  
  var cmd: array[2, Tcl.PObj]
  
  cmd[0] = Tcl.NewStringObj("pix::xInfo".cstring, -1)
  cmd[1] = objv[1]
  Tcl.IncrRefCount(cmd[0])
  Tcl.IncrRefCount(cmd[1])
  
  let cmdPtr = cast[Tcl.PPObj](addr cmd[0])
  
  if Tcl.EvalObjv(interp, 2, cmdPtr, 0) != Tcl.OK:
    Tcl.DecrRefCount(cmd[0])
    Tcl.DecrRefCount(cmd[1])
    return pixUtils.errorMSG(interp, $Tcl.GetStringResult(interp))
  
  Tcl.DecrRefCount(cmd[0])
  Tcl.DecrRefCount(cmd[1])
  
  if pixParses.getListInt(interp, Tcl.GetObjResult(interp), width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR
  
  var master = cast[ptr PixImageMaster](alloc0(sizeof(PixImageMaster)))
  
  if master == nil:
    let errormsg = "pix(error): allocation error for PixImageMaster object."
    return pixUtils.errorMSG(interp, errormsg)
  
  master.imageKey = $Tcl.GetString(objv[1])
  master.image    = nil
  master.width    = width
  master.height   = height
  master.name     = imageName
  master.interp   = interp
  master.tkMaster = masterPtr
  
  clientDataPtr[] = master

  Tk.ImageChanged(masterPtr, 0, 0, width, height, width, height)
  
  return Tcl.Ok

proc pix_getProc(tkwin: Tk.Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.} = 
  # Image recovery logic
  let master = cast[ptr PixImageMaster](masterData)

  if master == nil:
    Tcl.Panic("pix(error): masterData is nil")
    
  var gcValues: X.GCValues
  gcValues.graphics_exposures = false

  # Create a new instance that directly references the master image
  var instance = cast[ptr PixImageInstance](alloc0(sizeof(PixImageInstance)))

  if instance == nil:
    Tcl.Panic("pix(error): allocation error for PixImageInstance object.")

  instance.master = master
  instance.tkwin  = tkwin
  instance.width  = master.width
  instance.height = master.height
  instance.gc     = Tk.GetGC(tkwin, X.GCGraphicsExposures, gcValues)
  instance.pixmap = 0
  instance.dirty  = false
  instance.refCount = 1

  # Add instance to master instance list
  master.instances = instance

  return cast[Tcl.TClientData](instance)

proc pix_displayProc(
  instanceData : Tcl.TClientData,
  display      : ptr X.Display,
  drawable     : X.Drawable,
  imageX       : cint,
  imageY       : cint,
  width        : cint,
  height       : cint,
  drawableX    : cint,
  drawableY    : cint) {.cdecl.} = 

  let instance = cast[ptr PixImageInstance](instanceData)
  
  if instance == nil or instance.master.image == nil:
    return
  
  if instance.dirty or instance.pixmap == 0:
    # Clean up any existing pixmap
    if instance.pixmap != 0:
      Tk.FreePixmap(display, instance.pixmap)
      instance.pixmap = 0
  
    # Update the instance size
    instance.width = instance.master.width
    instance.height = instance.master.height
  
    let
      pixelCount = instance.width * instance.height
      bufferSize = pixelCount * 4
  
    # Check if the image data is empty
    if instance.master.image.data.len == 0:
      echo "pix(error): image data is empty"
      return
  
    # Allocate image buffer
    let imageBuffer = cast[ptr UncheckedArray[uint8]](alloc0(bufferSize))
    if imageBuffer == nil:
      Tcl.Panic("pix(error): allocation error for image buffer")
  
    let
      srcPixels = cast[ptr UncheckedArray[uint32]](instance.master.image.data[0].addr)
      dstPixels = cast[ptr UncheckedArray[uint32]](imageBuffer)
  
    {.push checks: off.}
    for i in 0..<pixelCount:
      let rgba = srcPixels[i]
      dstPixels[i] = (rgba and 0xFF00FF00'u32) or
                     ((rgba and 0x000000FF'u32) shl 16) or
                     ((rgba and 0x00FF0000'u32) shr 16)
    {.pop.}
  
    let depth = Tk.Depth(instance.tkwin)
  
    # Create XImage
    let ximage = Tk.XCreateImage(
      display, 
      Tk.Visual(instance.tkwin),
      depth.cuint,
      ZPixmap,
      0,    
      cast[cstring](imageBuffer),
      instance.width.cuint,
      instance.height.cuint,
      32,
      instance.width * 4
    )
  
    # Possible failure on Windows !!
    if instance.ximage != nil:
      instance.ximage.data = nil
      discard X.DestroyImage(instance.ximage)
  
    instance.ximage = ximage
  
    if instance.ximage == nil:
      echo "pix(error): XImage creation error"
      dealloc(imageBuffer)
      return
  
    # Create a pixmap
    let pixmap = Tk.GetPixmap(
      display, 
      drawable, 
      instance.width, 
      instance.height, 
      depth
    )
    
    if pixmap == 0:
      echo "pix(error): Pixmap creation error"
      dealloc(imageBuffer)
      return
  
    instance.pixmap = pixmap
  
    # Put the image
    let putResult = Tk.XPutImage(
      display, instance.pixmap, instance.gc, instance.ximage, 
      0, 0, 0, 0, 
      instance.width.cuint, instance.height.cuint
    )
  
    dealloc(imageBuffer)
  
    if putResult != 0:
      Tcl.Panic("pix(error): Tk.XPutImage failed with code: %i", putResult)
  
    instance.dirty = false

  # Copy the pixmap to the drawable
  discard XCopyArea(display, instance.pixmap, drawable, instance.gc,
    imageX, imageY, width.cuint, height.cuint,
    drawableX, drawableY
  )
  
  discard XFlush(display)
  
proc pix_freeProc(instanceData: Tcl.TClientData, display: ptr X.Display) {.cdecl.} = 
  # Logic of image liberation
  let instance = cast[ptr PixImageInstance](instanceData)
  if instance != nil:
    if instance.pixmap != 0:
      Tk.FreePixmap(display, instance.pixmap)

    if instance.ximage != nil:
      instance.ximage.data = nil
      
    if instance.gc != nil:
      Tk.FreeGC(display, instance.gc)

    dealloc(instance)

proc pix_deleteProc(instanceData: Tcl.TClientData) {.cdecl.} = 
  # Image removal logic
  let master = cast[ptr PixImageMaster](instanceData)
  if master != nil:
    # Free the master image
    dealloc(master)

proc createPixImgType*(interp: Tcl.PInterp): ptr Tk.ImageType =

  let imageType = cast[ptr Tk.ImageType](alloc0(sizeof(Tk.ImageType)))
  if imageType == nil:
    let errormsg = "pix(error): Could not allocate memory for Tk.ImageType."
    Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
    return nil

  imageType.name        = "pix"
  imageType.createProc  = pix_createProc
  imageType.getProc     = pix_getProc
  imageType.displayProc = pix_displayProc
  imageType.freeProc    = pix_freeProc
  imageType.deleteProc  = pix_deleteProc

  return imageType

proc surfXUpdate*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "pix:image")
    return Tcl.ERROR

  let pixImgName = Tcl.GetString(objv[1])
  var img: pixie.Image
  var imageType: Tk.ImageType

  let instanceData = Tk.GetImageMasterData(interp, pixImgName, imageType)

  let master = cast[ptr PixImageMaster](instanceData)
  if master == nil:
    let errormsg = "pix(error): cannot get master data for '" & $pixImgName & "'"
    return pixUtils.errorMSG(interp, errormsg)

  # Table
  let ptable = cast[PixTable](clientData)
  let masterKey = master.imageKey

  if ptable.hasContext(masterKey):
    img = ptable.getContext(masterKey).image
  elif ptable.hasImage(masterKey):
    img = ptable.getImage(masterKey)
  else:
    let errormsg = "pix(error): unknown <image> or <ctx> key object found '" & masterKey & "'"
    return pixUtils.errorMSG(interp, errormsg)

  # Update image + size
  master.image  = img
  master.width  = img.width.cint
  master.height = img.height.cint

  if master.instances != nil:
    master.instances.dirty = true
    master.instances.width = master.width
    master.instances.height = master.height
  
  Tk.ImageChanged(
    master.tkMaster, 
    0, 0, master.width, master.height, 
    master.width, master.height
  )

  return Tcl.OK

proc surfXFlush*(interp: Tcl.PInterp, obj: Tcl.PObj, ctx: pixie.Context): cint =

  let pixImgName = Tcl.GetString(obj)
  var imageType: Tk.ImageType

  let instanceData = Tk.GetImageMasterData(interp, pixImgName, imageType)

  let master = cast[ptr PixImageMaster](instanceData)
  if master == nil:
    let errormsg = "pix(error): cannot get master data for '" & $pixImgName & "'"
    return pixUtils.errorMSG(interp, errormsg)

  # Image
  let img = ctx.image 

  # Update image + size
  master.image  = img
  master.width  = img.width.cint
  master.height = img.height.cint

  if master.instances != nil:
    master.instances.dirty = true
    master.instances.width = master.width
    master.instances.height = master.height
  
  Tk.ImageChanged(
    master.tkMaster, 
    0, 0, master.width, master.height, 
    master.width, master.height
  )

  return Tcl.OK
