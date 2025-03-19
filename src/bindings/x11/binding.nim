# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

from pixie import Image, Context
import ../../core/xtypes as X
import ../tcl/binding as Tcl
import ../tk/binding as Tk
import ../../core/pixtables as pixTables
import ../../core/pixutils as pixUtils

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
    image     : pixie.Image
    width     : cint
    height    : cint
    name      : cstring
    instances : ptr PixImageInstance
    cmd       : Tcl.Command
    interp    : Tcl.PInterp
    tkMaster  : Tk.ImageMaster

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
      var img: pixie.Image
      
      if objc != 2:
        Tcl.WrongNumArgs(interp, 1, objv, "image create pix ?name -data (<img>|<ctx>)")
        return Tcl.ERROR

      if $Tcl.GetString(objv[0]) != "-data":
        let errormsg = "wrong # args: '-data' should present in a image create pix command."
        Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
        return Tcl.ERROR
        
      let arg1 = $Tcl.GetString(objv[1])
      
      if pixTables.hasContext(arg1):
        let ctx = pixTables.getContext(arg1)
        img = ctx.image
      elif pixTables.hasImage(arg1):
        img = pixTables.getImage(arg1)
      else:
        return Tcl.ERROR

      var master = cast[ptr PixImageMaster](alloc(sizeof(PixImageMaster)))
      master.width    = int32(img.width)
      master.height   = int32(img.height)
      master.name     = imageName
      master.image    = img
      master.cmd      = Tcl.CreateObjCommand(interp, imageName, imgCmd, nil, nil)
      master.interp   = interp
      master.tkMaster = masterPtr

      clientDataPtr[] = master

      Tk.ImageChanged(masterPtr, 0, 0, int32(img.width), int32(img.height), int32(img.width), int32(img.height))

      pixTables.addMasterTable(arg1, master.tkMaster)

      return Tcl.Ok
    ,
    getProc: proc(tkwin: Tk.Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.} = 
      # Image recovery logic
      let master = cast[ptr PixImageMaster](masterData)

      if master == nil:
        echo "oui"
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
      # Image display logic
      let instance = cast[ptr PixImageInstance](instanceData)
      
      if instance == nil:
        echo "Instance NULL"
        return
      
      if instance.dirty or instance.pixmap == 0:
        if instance.pixmap != 0:
          Tk.FreePixmap(display, instance.pixmap)
          instance.pixmap = 0

        if instance.ximage != nil:
          if instance.ximage.data != nil:
            instance.ximage.data = nil
          discard XDestroyImage(instance.ximage)
          instance.ximage = nil

        # S'assurer que les dimensions sont à jour
        instance.width = instance.master.width
        instance.height = instance.master.height

        let
          imgData = cast[ptr UncheckedArray[uint8]](instance.master.image.data[0].addr)
          size = instance.width * instance.height * 4

        var tempBuffer = cast[ptr UncheckedArray[uint8]](alloc(size))

        # Conversion RGBA -> BGRA 
        {.push checks: off.}
        for offset in countup(0, size - 4, 4):
          tempBuffer[offset+0] = imgData[offset+2]  # B
          tempBuffer[offset+1] = imgData[offset+1]  # G
          tempBuffer[offset+2] = imgData[offset+0]  # R
          tempBuffer[offset+3] = imgData[offset+3]  # A
        {.pop.}

        let depth = Tk.Depth(instance.tkwin)

        instance.ximage = XCreateImage(
          display, 
          Tk.Visual(instance.tkwin),
          depth.cuint,
          ZPixmap,    
          0,          
          cast[cstring](tempBuffer),
          instance.width.cuint,
          instance.height.cuint,
          32,
          instance.width * 4
        )

        if tempBuffer != nil:
          dealloc(tempBuffer)
          tempBuffer = nil

        if instance.ximage == nil:
          echo "XImage creation error"
          return
      
        instance.pixmap = Tk.GetPixmap(display, drawable, instance.width, instance.height, depth)
        
        if instance.pixmap == 0:
          echo "Pixmap creation error"
          return

        # Copy image to pixmap with GC configured
        if XPutImage(display, instance.pixmap, instance.gc, instance.ximage, 
                    0, 0, 0, 0, 
                    instance.width.cuint, instance.height.cuint) != 0:
          echo "Error XPutImage"
          return

        instance.dirty = false

      # Copy pixmap
      discard XCopyArea(display, instance.pixmap, drawable, instance.gc,
                  imageX, imageY, width.cuint, height.cuint,
                  drawableX, drawableY)
        
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

    ,
    deleteProc: proc(instanceData: Tcl.TClientData) = 
      # Image removal logic
      discard
    ,
    postscriptProc: nil,
    nextPtr: nil,
    reserved: nil
  )

proc surfXUpdate*(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  var img: pixie.Image

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>|<ctx>")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  if pixTables.hasContext(arg1):
    img = pixTables.getContext(arg1).image
  elif pixTables.hasImage(arg1):
    img = pixTables.getImage(arg1)
  else:
    return pixUtils.errorMSG(interp, "pix(error): unknown <image> or <ctx> key object found '" & arg1 & "'")

  if not pixTables.hasMasterTable(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no table found for '" & arg1 & "'")

  let masterPtr = pixTables.getMasterTable(arg1)
    
  # Gets name
  let name = Tk.NameOfImage(masterPtr)
  if name == nil:
    return pixUtils.errorMSG(interp, "pix(error): no image name found for '" & arg1 & "'")

  var imageType: Tk.ImageType
  let instanceData = Tk.GetImageMasterData(interp, name, imageType)
  let master = cast[ptr PixImageMaster](instanceData)
  if master == nil:
    return pixUtils.errorMSG(interp, "pix(error): cannot get master data for '" & arg1 & "'")

  # Update image + size
  master.image = img
  master.width = int32(img.width)
  master.height = int32(img.height)

  master.instances.dirty = true
  master.instances.width = master.width
  master.instances.height = master.height
  
  Tk.ImageChanged(master.tkMaster, 0, 0, master.width, master.height, master.width, master.height)
  
  return Tcl.OK