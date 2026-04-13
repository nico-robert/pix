# Copyright (c) 2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

from pixie import Image, Context
import ../bindings/x11/binding as X
import ../bindings/tcl/binding as Tcl
import ../bindings/tk/binding as Tk
import ./pixtables
import ./pixutils as pixUtils

# Instance shared by Display
type
  PixImageInstance* = object
    master*: ptr PixImageMaster
    displayName*: string        # Tk.DisplayName for identification
    tkwin*: Tk.Window
    refCount*: cint             # Counter for sharing by display
    gc*: X.GC
    pixmap*: X.Pixmap           # Backing store
    convertedBuffer*: pointer   # Persistent BGRA buffer
    bufferWidth*: cint
    bufferHeight*: cint
    nextInstance*: ptr PixImageInstance

  PixImageMaster* = object
    imageKey*: string
    image*: pixie.Image
    width*: cint
    height*: cint
    name*: cstring
    interp*: Tcl.PInterp
    tkMaster*: Tk.ImageMaster
    needflush*: bool            # Flag centralized in the Master
    instances*: ptr PixImageInstance

proc pix_createProc(
  interp: Tcl.PInterp,
  imageName: cstring,
  objc: cint,
  objv: Tcl.PPObj,
  typePtr: ptr Tk.ImageType,
  masterPtr: Tk.ImageMaster,
  clientDataPtr: Tcl.PClientData
): cint {.cdecl.} =

  # Optional validation of arguments
  if objc > 0:
    if objc != 2 or $objv[0] != "-data":
      return pixUtils.errorMSG(interp, "Usage: image create pix ?name? ?-data key?")

  var master = cast[ptr PixImageMaster](alloc0(sizeof(PixImageMaster)))

  if objc == 2:
    master.imageKey = $objv[1]
  else:
    master.imageKey = "" # Empty for now

  master.image = nil
  master.width = 0
  master.height = 0
  master.name = imageName
  master.interp = interp
  master.tkMaster = masterPtr
  master.needflush = false
  master.instances = nil

  clientDataPtr[] = cast[Tcl.TClientData](master)

  return Tcl.OK

proc pix_getProc(tkwin: Tk.Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.} =
  # Instance retrieval or creation (sharing by Display)

  let master = cast[ptr PixImageMaster](masterData)
  let displayName = $Tk.DisplayName(tkwin)

  # Search for existing instance for this Display
  var inst = master.instances
  while inst != nil:
    if inst.displayName == displayName:
      inst.refCount.inc
      return cast[Tcl.TClientData](inst)
    inst = inst.nextInstance

  # New instance
  var instance = cast[ptr PixImageInstance](alloc0(sizeof(PixImageInstance)))
  if instance == nil:
    Tcl.Panic("pix(error): allocation error for PixImageInstance")

  instance.master = master
  instance.tkwin = tkwin
  instance.displayName = displayName
  instance.refCount = 1
  instance.pixmap = 0
  instance.convertedBuffer = nil
  instance.bufferWidth = 0
  instance.bufferHeight = 0

  var gcValues: X.GCValues
  gcValues.graphics_exposures = false
  instance.gc = Tk.GetGC(tkwin, X.GCGraphicsExposures, gcValues)

  # Chaining
  instance.nextInstance = master.instances
  master.instances = instance

  return cast[Tcl.TClientData](instance)

proc updateInstanceBuffer(inst: ptr PixImageInstance, display: ptr X.Display) =
  # Update the converted buffer (only once per modification)

  let master = inst.master
  if master.image == nil or master.image.data.len == 0:
    return

  let newWidth = master.width
  let newHeight = master.height
  let pixelCount = newWidth * newHeight
  let bufferSize = pixelCount * 4

  # Conditional reallocation
  if newWidth != inst.bufferWidth or newHeight != inst.bufferHeight:
    if inst.convertedBuffer != nil:
      dealloc(inst.convertedBuffer)
    inst.convertedBuffer = alloc(bufferSize)
    inst.bufferWidth = newWidth
    inst.bufferHeight = newHeight

    if inst.pixmap != 0:
      Tk.FreePixmap(display, inst.pixmap)
      inst.pixmap = 0

  # RGBA -> BGRA conversion
  let src = cast[ptr UncheckedArray[uint32]](master.image.data[0].addr)
  let dst = cast[ptr UncheckedArray[uint32]](inst.convertedBuffer)

  {.push checks: off.}
  for i in 0..<pixelCount:
    let rgba = src[i]
    dst[i] =  (
      (rgba and 0xFF00FF00'u32) or
      ((rgba and 0x000000FF'u32) shl 16) or
      ((rgba and 0x00FF0000'u32) shr 16)
    )
  {.pop.}

proc pix_displayProc(
  instanceData: Tcl.TClientData,
  display: ptr X.Display,
  drawable: X.Drawable,
  imageX: cint,
  imageY: cint,
  width: cint,
  height: cint,
  drawableX: cint,
  drawableY: cint
) {.cdecl.} =
  # Display with centralized needflush
  let inst = cast[ptr PixImageInstance](instanceData)
  let master = inst.master

  if master == nil or master.image == nil or master.imageKey == "":
    return

  # Check the centralized flag of the Master
  let needsUpdate = master.needflush or inst.pixmap == 0

  if needsUpdate and master.image != nil:
    if master.needflush:
      updateInstanceBuffer(inst, display)
      master.needflush = false  # Reset of the central flag

    # Lazy creation of pixmap
    if inst.pixmap == 0:
      let depth = Tk.Depth(inst.tkwin)
      inst.pixmap = Tk.GetPixmap(display, drawable,
                                 inst.bufferWidth, inst.bufferHeight, depth)

    # Upload to pixmap via temporary XImage
    if inst.pixmap != 0 and inst.convertedBuffer != nil:
      let ximage = X.CreateImage(
        display,
        Tk.Visual(inst.tkwin),
        Tk.Depth(inst.tkwin).cuint,
        X.ZPixmap,
        0,
        cast[cstring](inst.convertedBuffer),
        inst.bufferWidth.cuint,
        inst.bufferHeight.cuint,
        32,
        inst.bufferWidth * 4
      )

      if ximage != nil:
        discard X.PutImage(display, inst.pixmap, inst.gc, ximage,
                          0, 0, 0, 0,
                          inst.bufferWidth.cuint, inst.bufferHeight.cuint)
        ximage.data = nil
        discard X.DestroyImage(ximage)

  # Fast blit from the backing store
  if inst.pixmap != 0:
    discard X.CopyArea(display, inst.pixmap, drawable, inst.gc,
                      imageX, imageY, width.cuint, height.cuint,
                      drawableX, drawableY)
    discard X.Flush(display)

proc pix_freeProc(instanceData: Tcl.TClientData, display: ptr X.Display) {.cdecl.} =
  # Release with refCount management

  let inst = cast[ptr PixImageInstance](instanceData)
  if inst == nil: return

  inst.refCount.dec
  if inst.refCount > 0:
    return  # Still has references

  let master = inst.master

  # Removal from linked list
  if master.instances == inst:
    master.instances = inst.nextInstance
  else:
    var prev = master.instances
    while prev != nil and prev.nextInstance != inst:
      prev = prev.nextInstance
    if prev != nil:
      prev.nextInstance = inst.nextInstance

  # Release of resources
  if inst.pixmap != 0:
    Tk.FreePixmap(display, inst.pixmap)
  if inst.gc != nil:
    Tk.FreeGC(display, inst.gc)
  if inst.convertedBuffer != nil:
    dealloc(inst.convertedBuffer)

  dealloc(inst)

proc pix_deleteProc(instanceData: Tcl.TClientData) {.cdecl.} =
  # Destruction of the Master
  let master = cast[ptr PixImageMaster](instanceData)
  if master == nil: return

  if master.instances != nil:
    Tcl.Panic("pix(error): tried to delete image when instances still exist")

  dealloc(master)

proc createPixImgType*(interp: Tcl.PInterp): ptr Tk.ImageType =
  # Creation of image type

  let imageType = create(Tk.ImageType)

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

proc draw_pix_surface*(clientData: Tcl.TClientData, interp: Tcl.PInterp,
                  objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws object to Tk photo.
  #
  # object - [img], [ctx] object or 'pixphoto' name.
  # photo  - Tk pix photo variable(optional).
  #
  # Returns: Nothing.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<img|ctx|pixPhoto> ?pixPhoto?")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  var key: string
  var pixPhotoName: string
  var dummyImgType: Tk.ImageType

  # Parse arguments
  if objc == 2:
    let arg1 = $objv[1]
    if ptable.hasContext(arg1) or ptable.hasImage(arg1):
      # Argument is a data key
      key = arg1
      pixPhotoName = arg1
    else:
      # Argument is a pixPhoto name
      pixPhotoName = arg1
      let master = cast[ptr PixImageMaster](
        Tk.GetImageMasterData(interp, pixPhotoName.cstring, dummyImgType)
      )
      if master == nil or master.imageKey == "":
        return pixUtils.errorMSG(interp, "pix(error): Unknown pix photo or key: " & arg1)
      key = master.imageKey
  else:
    key = $objv[1]
    pixPhotoName = $objv[2]
    
    if not (ptable.hasContext(key) or ptable.hasImage(key)):
      return pixUtils.errorMSG(interp, "pix(error): Unknown key: " & key)

  # Retrieve the master and image
  let master = cast[ptr PixImageMaster](
    Tk.GetImageMasterData(interp, pixPhotoName.cstring, dummyImgType)
  )
  if master == nil:
    return pixUtils.errorMSG(interp, "pix(error): Unknown pix photo: " & pixPhotoName)

  let img =
    if ptable.hasContext(key):
      ptable.getContext(key).image
    elif ptable.hasImage(key):
      ptable.getImage(key)
    else:
      return pixUtils.errorMSG(interp, "pix(error): Unknown key: " & key)

  # Update master and trigger refresh
  master.image     = img
  master.imageKey  = key
  master.width     = img.width.cint
  master.height    = img.height.cint
  master.needflush = true

  Tk.ImageChanged(master.tkMaster, 0, 0,
                  master.width, master.height,
                  master.width, master.height)
  return Tcl.OK