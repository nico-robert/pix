# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_image(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new image.
  #
  # size  - list width,height
  #
  # Returns a 'new' img object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "{width height}")
    return Tcl.ERROR

  var width, height: int

  # Size
  if pixParses.getListInt(interp, objv[1], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR
    
  # Create a new image of the specified width and height.
  let img = try:
    newImage(width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(img)
  pixTables.addImage(p, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # New image copy.
  #
  # image - object
  #
  # Returns a 'new' img object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  # Attempt to create a copy of the image object
  let copyimg = try:
    img.copy()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(copyimg)
  pixTables.addImage(p, copyimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_draw(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws one image onto another using a matrix transform and color blending.
  #
  # image     - object
  # image2    - object
  # matrix3   - list (optional:mat3)
  # blendMode - Enum value (optional:NormalBlend)
  #
  # Returns nothing.
  var
    count: Tcl.Size
    matrix3: vmath.Mat3

  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<img1> <img2> ?matrix3:optional ?blendMode:optional")
    return Tcl.ERROR

  # # Get destination image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img1 = pixTables.getImage(arg1)

  # Get source image
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasImage(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg2 & "'")

  let img2 = pixTables.getImage(arg2)

  try:
    if objc == 3:
      img1.draw(img2)
    elif objc == 4:
      # If 4 arguments are provided, draw <img2> onto <img1> with the transformation
      # specified by the 3rd argument. The 4th argument can be either a
      # matrix or a blend mode.
      if Tcl.ListObjLength(interp, objv[3], count) != Tcl.OK:
        return Tcl.ERROR
      if count == 1:
        # Blend mode
        let myEnum = parseEnum[BlendMode]($Tcl.GetString(objv[3]))
        img1.draw(img2, blendMode = myEnum)
      else:
        # Matrix specified as a list
        if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
          return Tcl.ERROR
        img1.draw(img2, transform = matrix3)
    else:
      # If 5 arguments are provided, draw <img2> onto <img1> with the transformation
      # specified by the 3rd argument and the blend mode specified by the 5th
      # argument.
      if pixUtils.matrix3x3(interp, objv[4], matrix3) != Tcl.OK:
        return Tcl.ERROR

      # Blend mode
      let myEnum = parseEnum[BlendMode]($Tcl.GetString(objv[5]))

      img1.draw(img2, transform = matrix3, blendMode = myEnum)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the image with the color.
  #
  # image   - object
  # value   - string color or paint object
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> color|<paint>")
    return Tcl.ERROR

  # Get image object
  let imgName = $Tcl.GetString(objv[1])
  if not pixTables.hasImage(imgName):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & imgName & "'")

  let img = pixTables.getImage(imgName)

  # Get fill value argument
  let fillArg = $Tcl.GetString(objv[2])

  try:
    # Handle paint object or color value
    if pixTables.hasPaint(fillArg):
      img.fill(pixTables.getPaint(fillArg))
    else:
      # Fall back to color parsing.
      img.fill(pixUtils.getColor(objv[2]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_readImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the image with the color.
  #
  # filePath - path file
  #
  # Returns a 'new' img object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "full pathfile")
    return Tcl.ERROR

  let file = $Tcl.GetString(objv[1])

  # Read the image from the file
  # Note: This will throw an exception if the file does not exist,
  # or if the file is not a valid image or supported.
  let img = try:
    readimage(file)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(img)
  pixTables.addImage(p, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_fillpath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills a path.
  #
  # image      - object
  # pathValue  - string path  or path object
  # paintValue - string color or paint object
  # matrix     - list (optional:mat3)
  #
  # Returns nothing.
  var
    img: pixie.Image
    matrix3: vmath.Mat3
    hasMatrix: bool = false

  if objc notin (4..5):
    Tcl.WrongNumArgs(interp, 1, objv, "<img> '<path>|stringPath' 'color|<paint>' ?matrix:optional")
    return Tcl.ERROR

  # Get image object
  let
    cmdName = $Tcl.GetString(objv[0])
    imgName = $Tcl.GetString(objv[1])

  if cmdName == "pix::ctx::fillPath":
    if not pixTables.hasContext(imgName):
      return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & imgName & "'")

    img = pixTables.getContext(imgName).image
  else:
    if not pixTables.hasImage(imgName):
      return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & imgName & "'")

    img = pixTables.getImage(imgName)

  # Get path and paint/color arguments
  let
    pathArg = $Tcl.GetString(objv[2])
    paintArg = $Tcl.GetString(objv[3])

  # Handle optional matrix
  if objc == 5:
    if pixUtils.matrix3x3(interp, objv[4], matrix3) != Tcl.OK:
      return Tcl.ERROR
    hasMatrix = true

  try:
    # Get path object or use string path
    let path = if pixTables.hasPath(pathArg): pixTables.getPath(pathArg)
               else: parsePath(pathArg)

    # Get paint/color object
    let paint = if pixTables.hasPaint(paintArg): pixTables.getPaint(paintArg)
                else: pixUtils.getColor(objv[3]).SomePaint

    # Apply fill with or without matrix
    if hasMatrix:
      img.fillPath(path, paint, matrix3)
    else:
      img.fillPath(path, paint)

  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes a path.
  #
  # image   - object
  # value   - string path
  # color   - string color or paint object
  # options - dict (strokeWidth, transform, lineCap, miterLimit, lineJoin, dashes)
  #
  # Returns nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> 'pathstring' 'color|<paint>' {key value key value ...}")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])
  var img: pixie.Image

  if $Tcl.GetString(objv[0]) == "pix::ctx::strokePath":
    if not pixTables.hasContext(arg1):
      return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg1 & "'")
    img = pixTables.getContext(arg1).image
  else:
    if not pixTables.hasImage(arg1):
      return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")
    img = pixTables.getImage(arg1)

  let
    arg2 = $Tcl.GetString(objv[2])
    arg3 = $Tcl.GetString(objv[3])

  try:
    # Parse the options from the Tcl dict and set the fields of 
    # the 'RenderOptions' object.
    var opts = pixParses.RenderOptions()
    pixParses.dictOptions(interp, objv[4], opts)

    let path  = if pixTables.hasPath(arg2) : pixTables.getPath(arg2)  else: parsePath(arg2)
    let paint = if pixTables.hasPaint(arg3): pixTables.getPaint(arg3) else: SomePaint(pixUtils.getColor(objv[3]))

    img.strokePath(
      path,
      paint,
      transform = opts.transform,
      strokeWidth = opts.strokeWidth,
      lineCap = opts.lineCap,
      lineJoin = opts.lineJoin,
      miterLimit = opts.miterLimit,
      dashes = opts.dashes
    )
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_blur(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Applies Gaussian blur to the image given a radius.
  #
  # image   - object
  # radius  - double value
  # color   - string (optional:transparent)
  #
  # Returns nothing.
  if objc notin (3..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<img> radius ?color:optional")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var radius: cdouble

  # Radius
  if Tcl.GetDoubleFromObj(interp, objv[2], radius) != Tcl.OK:
    return Tcl.ERROR

  # 'blur' blurs the image using a Gaussian blur algorithm.  The blur radius
  # is the distance from the point of the image to the point of the blur
  # effect.  The color is the color of the blur effect.
  try:
    if objc == 4:
      # If the user has provided a color, blur the image with that color.
      let color = pixUtils.getColor(objv[3])
      img.blur(radius, color)
    else:
      img.blur(radius)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_shadow(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a shadow of the image with the offset, spread and blur.
  #
  # image   - object
  # options - dict (offset, spread, blur, color)
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {offset? ?value spread? ?value blur? ?value color? ?value}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    # Parse the options from the Tcl dict and set the fields of 
    # the 'ShadowOptions' object.
    var opts = pixParses.RenderShadow()
    pixParses.shadowOptions(interp, objv[2], opts)

    let shadow = img.shadow(
      offset = opts.offset,
      spread = opts.spread,
      blur   = opts.blur,
      color  = opts.color
    )

    let p = toHexPtr(shadow)
    pixTables.addImage(p, shadow)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_fillText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills image text.
  #
  # image        - object
  # object       - arrangement or font object
  # args         - dict options described below:
  #
  # matrix       - optional list if `object` is arrangement `object`
  # text         - string if `object` is font `object`
  # options      - dict (transform, bounds, hAlign, vAlign) (optional) if `object` is font `object`
  #
  # Returns nothing.
  if objc notin (3..5):
    let errMsg = "<img> <arrangement> ?matrix3:optional or " &
    "<img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let
    img  = pixTables.getImage(arg1)
    arg2 = $Tcl.GetString(objv[2])

  var matrix3: vmath.Mat3

  if pixTables.hasArr(arg2):
    # Arrangement
    let arrangement = pixTables.getArr(arg2)
    if objc == 4:
      if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR
      try:
        # Use the fillText method of the image to render text based on the given arrangement.
        # The arrangement object contains pre-calculated positions and styles for text glyphs.
        # The matrix3 argument is a transformation matrix that will be applied to the text.
        # This allows for transformations such as scaling, rotation, or translation of the text.
        img.fillText(arrangement, matrix3)
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    else:
      try:
        img.fillText(arrangement)
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    if not pixTables.hasFont(arg2):
      return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg2 & "'")

    let font = pixTables.getFont(arg2)
    if objc < 4:
      return pixUtils.errorMSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")

    let text = $Tcl.GetString(objv[3])

    try:
      if objc == 5:
        # Create a new RenderOptions object to store font rendering options.
        var opts = pixParses.RenderOptions()
        pixParses.fontOptions(interp, objv[4], opts)

        img.fillText(
          font,
          text,
          transform = opts.transform,
          bounds = opts.bounds,
          hAlign = opts.hAlign,
          vAlign = opts.vAlign
        )
      else:
        img.fillText(font, text)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_resize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Resize an image to a given height and width
  #
  # image  - object
  # size   - list width,height
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {width height}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var width, height: int

  if pixParses.getListInt(interp, objv[2], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  # We create a new image with the new size
  # This takes care of creating a new image with the correct size
  # and scaling the image.  The `resize` proc is smart enough
  # to scale the image to the new size.
  let newimg = try:
    img.resize(width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newimg)
  pixTables.addImage(p, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_get(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets image size.
  #
  # image - object
  #
  # Returns Tcl dict (width, height).
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let
    img = pixTables.getImage(arg1)
    dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", 5), Tcl.NewIntObj(img.width))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("height", 6), Tcl.NewIntObj(img.height))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_getPixel(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a pixel at (x, y) or returns transparent black if outside of bounds.
  #
  # image        - object
  # coordinates  - list x,y (x column of the pixel, y row of the pixel)
  #
  # Returns Tcl dict (r, g, b, a).
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y: int

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let data = try:
    img[x, y]
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", 1), Tcl.NewIntObj(data.r.int))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", 1), Tcl.NewIntObj(data.g.int))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", 1), Tcl.NewIntObj(data.b.int))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", 1), Tcl.NewIntObj(data.a.int))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_setPixel(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a pixel at (x, y) or does nothing if outside of bounds.
  #
  # image       - object
  # coordinates - list x,y
  # color       - string color
  #
  # Returns nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} color")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y: int

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  try:
    img[x, y] = pixUtils.getColor(objv[3])
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_applyOpacity(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Multiplies alpha of the image by opacity.
  #
  # image    - object
  # opacity  - double value
  #
  # img.applyOpacity multiplies the opacity of the image by the
  # opacity parameter. The opacity parameter is a double between
  # 0 and 1. 0 is fully transparent. 1 is fully opaque. Any value
  # inbetween is a mix of the two.
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> opacity")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var opacity: cdouble

  # opacity
  if Tcl.GetDoubleFromObj(interp, objv[2], opacity) != Tcl.OK:
    return Tcl.ERROR

  try:
    img.applyOpacity(opacity)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_ceil(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # A value of 0 stays 0. Anything else turns into 255.
  #
  # image - object
  #
  # The `ceil` proc takes an image and replaces all pixels that are
  # not fully transparent (i.e. have an alpha of 0) with a pixel that
  # is fully opaque (i.e. has an alpha of 255). This is useful for
  # creating masks from images.
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    img.ceil()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_diff(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Call the `diff` method on the master image, passing the image to
  # compare to the master image. The `diff` method returns a tuple
  # with two elements:
  #
  # masterimage - object
  # image       - object
  #
  # 1. A cdouble representing the difference score between the two
  # images. This score is 0 if the images are identical, and 1 if the
  # images are completely different. The score is a measure of how
  # different the two images are.
  #
  # 2. A new pix image representing the difference between the two
  # images. The difference image is an image that has the same size
  # as the two input images, and the pixels in this image represent
  # the difference between the corresponding pixels in the two
  # images. The difference image will have the same format as the
  # input images.
  #
  # Returns Tcl dict (score, imgdiff object).
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<masterimg> <img>")
    return Tcl.ERROR

  # Image master
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let masterimg = pixTables.getImage(arg1)

  # Image
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasImage(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg2 & "'")

  let img = pixTables.getImage(arg2)

  let (score, newimg) = try:
    masterimg.diff(img)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newimg)
  pixTables.addImage(p, newimg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("score", 5), Tcl.NewDoubleObj(score))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("img", 3), Tcl.NewStringObj(p.cstring, -1))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_flipHorizontal(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # This method modifies the image in place, flipping it around the Y-axis.
  # As a result, the left and right sides of the image are swapped.
  # This operation is useful for creating mirror images or for certain graphical effects.
  #
  # image - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    img.flipHorizontal()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_flipVertical(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # This method modifies the image in place, flipping it around the X-axis.
  #
  # image - object
  #
  # As a result, the top and bottom sides of the image are swapped.
  # This operation is useful for creating mirror images or for certain graphical effects.
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    img.flipVertical()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_getColor(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a color at (x, y) or returns transparent black if outside of bounds.
  #
  # image        - object
  # coordinates  - list x,y
  #
  # Returns Tcl dict (r, g, b, a).
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y: int

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let color = try:
    # Retrieve the color of the pixel at coordinates (x, y) from the image.
    img.getColor(x, y)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", 1), Tcl.NewDoubleObj(color.r))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", 1), Tcl.NewDoubleObj(color.g))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", 1), Tcl.NewDoubleObj(color.b))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", 1), Tcl.NewDoubleObj(color.a))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_inside(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns true if (x, y) is inside the image, false otherwise.
  #
  # image        - object
  # coordinates  - list x,y
  #
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y: int

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let value = try:
    if img.inside(x, y): 1 else: 0
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_image_invert(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Inverts all of the colors and alpha.
  #
  # image - object
  #
  # This will flip the image by changing the color and alpha of every pixel.
  # The result will be a new image where every pixel is the exact opposite of
  # the corresponding pixel in the original image.
  #
  # For example, if the original image is entirely white, the resulting image
  # will be entirely black. If the original image is entirely black, the
  # resulting image will be entirely white.
  # This is useful for things like getting the negative of an image, or
  # creating a "reverse" version of an image.
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    # Invert the image.
    img.invert()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_isOneColor(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if the entire image is the same color.
  #
  # image - object
  #
  # Returns true, false otherwise.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  let value = try:
    if img.isOneColor(): 1 else: 0
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_image_isOpaque(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if the entire image is opaque (alpha values are all 255).
  #
  # image - object
  #
  # Returns true, false otherwise.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  let value = try:
    if img.isOpaque(): 1 else: 0
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_image_isTransparent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if this image is fully transparent or not.
  #
  # image - object
  #
  # Returns true, false otherwise.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  let value = try:
    if img.isTransparent(): 1 else: 0
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value))

  return Tcl.OK

proc pix_image_magnifyBy2(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Scales image up by 2 ^ power.
  #
  # image  - object
  # power  - integer value (optional:1)
  #
  # If only one argument is given (i.e. the image object), just magnify by 2.
  # This is a convenience for the user.
  #
  # Returns a 'new' img object.
  var
    power: int = 1
    newimg: pixie.Image

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<img> ?power:optional")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  if objc == 3:
    if Tcl.GetIntFromObj(interp, objv[2], power) != Tcl.OK:
      return Tcl.ERROR
    try:
      newimg = img.magnifyBy2(power.int)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    try:
      # The result is stored in newimg.
      newimg = img.magnifyBy2()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newimg)
  pixTables.addImage(p, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_minifyBy2(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Scales the image down by an integer scale.
  #
  # image  - object
  # power  - integer value (optional:1)
  #
  # We were given an integer power as an argument, so we call
  # img.minifyBy2() with that power. This will scale the image
  # down by 2^power.
  #
  # Returns a 'new' img object.
  var
    power: int = 1
    newimg: pixie.Image

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<img> ?power:optional")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  if objc == 3:
    if Tcl.GetIntFromObj(interp, objv[2], power) != Tcl.OK:
      return Tcl.ERROR
    try:
      newimg = img.minifyBy2(power.int)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      newimg = img.minifyBy2()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newimg)
  pixTables.addImage(p, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_opaqueBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks the bounds of opaque pixels.
  #
  # image - object
  #
  # Some images have transparency around them,
  # use this to find just the visible part of the image and then use subImage to cut
  # it out. Returns zero rect if whole image is transparent,
  # or just the size of the image if no edge is transparent.
  #
  # Returns Tcl dict (x, y, w, h).
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  let rect = try:
    img.opaqueBounds()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_rotate90(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Rotates the image 90 degrees clockwise.
  #
  # image - object
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  try:
    img.rotate90()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_subImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a sub image from this image.
  #
  # image        - object
  # coordinates  - list x,y
  # size         - list width,height
  #
  # The subImage function extracts a portion of the original image starting at (x, y) 
  # and spanning the width and height specified.
  #
  # Returns a 'new' img object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y, width, height: int

  # Coordinates
  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListInt(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  let subimage = try:
    # Create a subimage from the given image (img) based on specified coordinates and size.
    img.subImage(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(subimage)
  pixTables.addImage(p, subimage)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_superImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Either cuts a sub image or returns a super image with padded transparency.
  #
  # image        - object
  # coordinates  - list x,y
  # size         - list width,height
  #
  # If the coordinates and size of the superImage are within the bounds of the original image,
  # a sub image is cut from the original image.
  #
  # If the coordinates and size of the superImage are outside the bounds of the original image,
  # a super image is created with the original image centered and padded with transparency.
  # The resulting super image is always the size specified in the arguments.
  #
  # If the resulting super image is different from the original image, a new image is created.
  # If the resulting super image is the same as the original image, the original image is returned.
  #
  # Returns a 'new' img object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)
  var x, y, width, height: int

  # Coordinates
  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListInt(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  let subimage = try:
    img.superImage(x, y, width, height)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(subimage)
  pixTables.addImage(p, subimage)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_image_fillGradient(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills with the Paint gradient.
  #
  # image  - object
  # paint  - object
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> <paint>")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img = pixTables.getImage(arg1)

  # Paint
  let arg2 = $Tcl.GetString(objv[2])

  if not pixTables.hasPaint(arg2):
    return pixUtils.errorMSG(interp, "pix(error): no key <paint> object found '" & arg2 & "'")

  let paint = pixTables.getPaint(arg2)

  try:
    img.fillGradient(paint)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_strokeText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strocks image text.
  #
  # image       - object
  # object      - arrangement object or font object
  # text        - string if `object` is font object
  # arroptions  - dict (transform:list, strokeWidth:double, lineCap:enum, lineJoin:enum, miterLimit:double, dashes:list) (optional)
  # fontoptions - dict (transform:list, bounds:list, hAlign:enum, vAlign:enum) (optional)
  #
  # Returns nothing.
  if objc notin (3..5):
    let errMsg = "<img> <arrangement> {?transform ?value ?strokeWidth ?value ?lineCap ?value " &
    "?lineJoin ?value ?miterLimit ?value ?dashes ?value} or " &
    "<img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let
    img  = pixTables.getImage(arg1)
    arg2 = $Tcl.GetString(objv[2])

  if pixTables.hasArr(arg2):
    # Arrangement
    let arrangement = pixTables.getArr(arg2)
    try:
      if objc == 4:
        var opts = pixParses.RenderOptions()
        pixParses.dictOptions(interp, objv[3], opts)

        img.strokeText(
          arrangement,
          transform = opts.transform,
          strokeWidth = opts.strokeWidth,
          lineCap = opts.lineCap,
          lineJoin = opts.lineJoin,
          dashes = opts.dashes,
          miterLimit = opts.miterLimit
        )
      else:
        img.strokeText(arrangement)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    if not pixTables.hasFont(arg2):
      return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg2 & "'")

    let font = pixTables.getFont(arg2)
    if objc < 4:
      return pixUtils.errorMSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")

    let text = $Tcl.GetString(objv[3])
    try:
      if objc == 5:
        var opts = pixParses.RenderOptions()
        pixParses.fontOptions(interp, objv[4], opts)

        img.strokeText(
          font,
          text,
          transform = opts.transform,
          strokeWidth = opts.strokeWidth,
          lineCap = opts.lineCap,
          lineJoin = opts.lineJoin,
          dashes = opts.dashes,
          bounds = opts.bounds,
          hAlign = opts.hAlign,
          vAlign = opts.vAlign,
          miterLimit = opts.miterLimit
        )
      else:
        img.strokeText(font, text)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_writeFile(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Save image file.
  #
  # image    - object
  # filePath - string (\*.png|\*.bmp|\*.qoi|\*.ppm)
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> filePath")
    return Tcl.ERROR

  # Image
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasImage(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <image> object found '" & arg1 & "'")

  let img  = pixTables.getImage(arg1)

  try:
    # Call the writeFile method of the image to save the image to the
    # file specified by filePath.
    img.writeFile($Tcl.GetString(objv[2]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current image or all images if special word `all` is specified.
  #
  # value - image object or string
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:
    # Image
    if arg1 == "all":
      imgTable.clear()
    else:
      imgTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK