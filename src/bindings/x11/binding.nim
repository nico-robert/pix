# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

from pixie import Image, Context
import ../../core/xtypes
import ../tcl/binding as Tcl
import ../tk/binding as Tk
import ../../core/pixtables as pixTables

import pretty

# Instance types that depend on previous definitions
type
  PixImageInstance* = object
    master   : ptr PixImageMaster
    tkwin    : Tk.Window
    width    : cint
    height   : cint
    gc       : GC
    ximage   : XImagePtr
    pixmap   : Pixmap
    dr       : Drawable
    refCount : cint

  PixImageMaster* = object
    image     : pixie.Image
    width     : cint
    height    : cint
    name      : cstring
    instance  : PixImageInstance
    cmd       : Tcl.Command
    interp    : Tcl.PInterp
    tkMaster  : Tk.ImageMaster

# proc XDestroyImage(img: XImagePtr) {.cdecl, importc: "XDestroyImage", header: "X11/Xutil.h".}

proc imgCmd (clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint = return Tcl.Ok

proc createImgType*(interp: Tcl.PInterp): PixImageType =

  return PixImageType(
    name: "pix",
    createProc: proc(
      interp: Tcl.PInterp, 
      imageName: cstring, 
      objc: cint, 
      objv: Tcl.PPObj, 
      typePtr: ptr PixImageType, 
      masterPtr: Tk.ImageMaster, 
      clientDataPtr: Tcl.PClientData
      ): int {.cdecl.} =
      #  Image creation logic
      echo "Image1_creation"
      var img: pixie.Image
      
      if objc != 2:
        Tcl.WrongNumArgs(interp, 1, objv, "image create pix ?name -data (image|ctx)")
        return Tcl.ERROR

      if $Tcl.GetString(objv[0]) != "-data":
        let errormsg = "wrong # args: '-data' should present in a command."
        Tcl.SetObjResult(interp, Tcl.NewStringObj(errormsg.cstring, -1))
        return Tcl.ERROR
        
      let arg1 = Tcl.GetString(objv[1])
      
      if pixTables.hasContext($arg1):
        let ctx = pixTables.getContext($arg1)
        img = ctx.image
      elif pixTables.hasImage($arg1):
        img = pixTables.getImage($arg1)
      else:
        return Tcl.ERROR

      var master = cast[ptr PixImageMaster](alloc(sizeof(PixImageMaster)))
      master.width   = int32(img.width)
      master.height  = int32(img.height)
      master.name    = imageName
      master.image   = img
      master.cmd     = Tcl.CreateObjCommand(interp, imageName, imgCmd, nil, nil)
      master.interp  = interp

      clientDataPtr[] = master

      Tk.ImageChanged(masterPtr, 0, 0, int32(img.width), int32(img.height), int32(img.width), int32(img.height))

      return Tcl.Ok
    ,
    getProc: proc(tkwin: Tk.Window, masterData: Tcl.TClientData): Tcl.TClientData {.cdecl.} = 
      # Image recovery logic
      echo "Image2_recovery"
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

      # Add instance to master instance list
      master.instance = instance[]

      return cast[Tcl.TClientData](instance)
    ,
    displayProc: proc(
      instanceData: Tcl.TClientData, 
      display: ptr Display, 
      drawable: Drawable, 
      imageX: cint, 
      imageY: cint, 
      width: cint, 
      height: cint, 
      drawableX: cint, 
      drawableY: cint
      ) {.cdecl.} = 
      # Image display logic
      echo "Image3_displayed"

      let instance = cast[ptr PixImageInstance](instanceData)
      
      if instance == nil:
        echo "Instance NULL"
        return
      
      if instance.pixmap == 0:
        let
          imgData = cast[ptr UncheckedArray[uint8]](instance.master.image.data[0].addr)
          size = instance.width * instance.height * 4
        var tempBuffer = cast[ptr UncheckedArray[uint8]](alloc(size))

        # var attributes: XWindowAttributes
        # discard XGetWindowAttributes(display, Tk.WindowId(Tk.Parent(instance.tkwin)), attributes)
        # let bgColorName = Tk_GetOption(instance.tkwin, "-background", "Background")

        # print attributes

        # Conversion RGBA -> BGRA 
        {.push checks: off.}
        for offset in countup(0, size - 4, 4):
          let alpha = imgData[offset+3]
          tempBuffer[offset+0] = imgData[offset+2]  # B
          tempBuffer[offset+1] = imgData[offset+1]  # G
          tempBuffer[offset+2] = imgData[offset+0]  # R
          tempBuffer[offset+3] = alpha              # A
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

        if instance.ximage == nil:
          echo "XImage creation error"
          return

        # Configuration BGRA
        # instance.ximage.byte_order = LSBFirst
      
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
          
        # discard XSetForeground(display, instance.gc, 0.culong)
        # discard XFillRectangle(display, drawable, instance.gc, 0.cint, 0.cint, instance.width.cuint, instance.height.cuint)
        # discard XSetClipMask(display, instance.gc, instance.pixmap)
          
        # if Tk_PutImage(nil, 0, display, instance.pixmap, instance.gc,
                    # instance.ximage, 0, 0, 0, 0, instance.ximage.width.cuint,
                    # instance.ximage.height.cuint) != 0:
          # echo "erreur Tk_PutImage"
          # return

      # Copy pixmap
      if XCopyArea(display, instance.pixmap, drawable, instance.gc,
                  imageX, imageY, width.cuint, height.cuint,
                  drawableX, drawableY) != 0:
        echo "Error XCopyArea"
        return
        
      discard XFlush(display)

    ,
    freeProc: proc(instanceData: Tcl.TClientData, display: ptr Display) = 
      # Logic of image liberation
      echo "Image4_freed"
      let instance = cast[ptr PixImageInstance](instanceData)
      if instance != nil and instance.ximage != nil:
        dealloc(cast[pointer](instance.ximage.data))
        
      if instance.pixmap != 0:
        Tk.FreePixmap(display, instance.pixmap)
        
      if instance.ximage != nil:
        instance.ximage.data = nil
        
      if instance.gc != nil:
        Tk.FreeGC(display, instance.gc)

    ,
    deleteProc: proc(instanceData: Tcl.TClientData) = 
      # Image removal logic
      echo "Image5_deleted"
    ,
    postscriptProc: nil,
    nextPtr: nil,
    reserved: nil
  )