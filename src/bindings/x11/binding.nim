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

template timeBody(name: string, body: untyped): untyped =
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
    ximage   : X.ImagePtr
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
    cmd       : Tcl.Command
    interp    : Tcl.PInterp
    tkMaster  : Tk.ImageMaster

proc xInfo*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
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
    Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
    return Tcl.ERROR

  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewIntObj(img.width))
  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewIntObj(img.height))

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc imgCmd (clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint = return Tcl.Ok

proc createImgType*(interp: Tcl.PInterp): Tk.ImageType =

  return Tk.ImageType(
    name: "pix",
    createProc: proc(
      interp        : Tcl.PInterp,
      imageName     : cstring,
      objc          : cint,
      objv          : Tcl.PPObj,
      typePtr       : ptr Tk.ImageType,
      masterPtr     : Tk.ImageMaster,
      clientDataPtr : Tcl.PClientData
    ): int {.cdecl.} =
      #  Image creation logic
      var width, height: int
      
      if objc != 2:
        Tcl.WrongNumArgs(interp, 1, objv, "image create pix ?name -data (<img>|<ctx>)")
        return Tcl.ERROR

      if $Tcl.GetString(objv[0]) != "-data":
        let errormsg = "wrong # args: '-data' should present in a image create pix command."
        Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
        return Tcl.ERROR
        
      # let arg1 = $Tcl.GetString(objv[1])
      var cmd: array[2, Tcl.PObj]

      cmd[0] = Tcl.NewStringObj("pix::xInfo".cstring, -1)
      cmd[1] = objv[1]
      Tcl.IncrRefCount(cmd[0])
      Tcl.IncrRefCount(cmd[1])

      let cmdPtr = cast[Tcl.PPObj](addr cmd[0])

      if Tcl.EvalObjv(interp, 2, cmdPtr, 0) != Tcl.OK:
        Tcl.DecrRefCount(cmd[0])
        Tcl.DecrRefCount(cmd[1])
        Tcl.SetObjResult(
          interp, 
          Tcl.NewStringObj(Tcl.GetStringResult(interp), -1)
        )
        return Tcl.ERROR

      Tcl.DecrRefCount(cmd[0])
      Tcl.DecrRefCount(cmd[1])

      if pixParses.getListInt(interp, Tcl.GetObjResult(interp), width, height, 
        "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
        return Tcl.ERROR

      var master = cast[ptr PixImageMaster](alloc0(sizeof(PixImageMaster)))

      if master == nil:
        Tcl.SetObjResult(
          interp, 
          Tcl.NewStringObj(
            "pix(error): allocation error for PixImageMaster object.".cstring,
            -1
          )
        )
        return Tcl.ERROR

      master.imageKey = $Tcl.GetString(objv[1])
      master.image    = nil
      master.width    = int32(width)
      master.height   = int32(height)
      master.name     = imageName
      master.cmd      = Tcl.CreateObjCommand(interp, imageName, imgCmd, nil, nil)
      master.interp   = interp
      master.tkMaster = masterPtr

      clientDataPtr[] = master

      Tk.ImageChanged(masterPtr, 0, 0, int32(width), int32(height), int32(width), int32(height))

      return Tcl.Ok
    ,
    getProc: proc(tkwin: Tk.Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.} = 
      # Image recovery logic
      let master = cast[ptr PixImageMaster](masterData)

      if master == nil:
        return nil
        
      var gcValues: XGCValues
      gcValues.graphics_exposures = false

      # Create a new instance that directly references the master image
      var instance = cast[ptr PixImageInstance](alloc(sizeof(PixImageInstance)))
      instance.master = master
      instance.tkwin  = tkwin
      instance.width  = master.width
      instance.height = master.height
      instance.gc     = Tk.GetGC(tkwin, GCGraphicsExposures, gcValues)
      instance.pixmap = 0
      instance.dirty  = false
      instance.refCount = 1

      # Add instance to master instance list
      master.instances = instance

      return cast[Tcl.TClientData](instance)
    ,
    displayProc: proc(
      instanceData : Tcl.TClientData,
      display      : ptr X.Display,
      drawable     : X.Drawable,
      imageX       : cint,
      imageY       : cint,
      width        : cint,
      height       : cint,
      drawableX    : cint,
      drawableY    : cint
    ) {.cdecl.} = 

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
          echo "pix(error): allocation error for image buffer"
          return

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
        let ximage = XCreateImage(
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
          discard XDestroyImage(instance.ximage)

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
        let putResult = XPutImage(
          display, instance.pixmap, instance.gc, instance.ximage, 
          0, 0, 0, 0, 
          instance.width.cuint, instance.height.cuint
        )

        dealloc(imageBuffer)

        if putResult != 0:
          echo "pix(error): XPutImage failed with code: ", putResult
          return

        instance.dirty = false
      timeBody("XCopyArea"):
        # Copy the pixmap to the drawable
        discard XCopyArea(display, instance.pixmap, drawable, instance.gc,
          imageX, imageY, width.cuint, height.cuint,
          drawableX, drawableY
        )

      discard XFlush(display)
    ,
    freeProc: proc(instanceData: Tcl.TClientData, display: ptr X.Display) = 
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
    ,
    deleteProc: proc(instanceData: Tcl.TClientData) = 
      # Image removal logic
      let master = cast[ptr PixImageMaster](instanceData)
      if master == nil:
        return

      # Free the master image
      dealloc(master)
    ,
    postscriptProc: nil,
    nextPtr: nil,
    reserved: nil
  )

proc surfXUpdate*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "pix:image")
    return Tcl.ERROR

  let pixImgName = Tcl.GetString(objv[1])
  var img: pixie.Image
  var imageType: Tk.ImageType

  let instanceData = Tk.GetImageMasterData(interp, pixImgName, imageType)

  let master = cast[ptr PixImageMaster](instanceData)
  if master == nil:
    return pixUtils.errorMSG(
      interp, 
      "pix(error): cannot get master data for '" & $pixImgName & "'"
    )

  # Table
  let ptable = cast[PixTable](clientData)
  let masterKey = master.imageKey

  if ptable.hasContext(masterKey):
    img = ptable.getContext(masterKey).image
  elif ptable.hasImage(masterKey):
    img = ptable.getImage(masterKey)
  else:
    return pixUtils.errorMSG(
      interp, 
      "pix(error): unknown <image> or <ctx> key object found '" & masterKey & "'"
    )

  # Update image + size
  master.image = img
  master.width = int32(img.width)
  master.height = int32(img.height)

  master.instances.dirty = true
  master.instances.width = master.width
  master.instances.height = master.height
  
  Tk.ImageChanged(
    master.tkMaster, 
    0, 0, master.width, master.height, 
    master.width, master.height
  )

  return Tcl.OK