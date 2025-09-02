# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_image(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a new image.
  #
  # size  - list width,height
  #
  # Returns: A *new* [img] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "{width height}")
    return Tcl.ERROR

  var width, height: cint
  let ptable = cast[PixTable](clientData)

  # Size
  if pixParses.getListInt(interp, objv[1], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  # Create a new image of the specified width and height.
  let img = try:
    newImage(width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(img)
  ptable.addImage(imgKey, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_copy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # This procedure creates a new image by copying the contents 
  # of the given image object.
  #
  # image - [img::new]
  #
  # Returns: A *new* [img] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Attempt to create a copy of the image object
  let copyimg = img.copy()

  let imgKey = toHexPtr(copyimg)
  ptable.addImage(imgKey, copyimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_draw(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Draws one image onto another using a matrix transform and color blending.
  #
  # image     - [img::new]
  # image2    - [img::new]
  # matrix3   - list (optional:mat3)
  # blendMode - Enum value (optional:NormalBlend)
  #
  # Returns: Nothing.
  if objc notin (3..5):
    Tcl.WrongNumArgs(interp, 1, objv,
    "<img1> <img2> ?matrix3:optional ?blendMode:optional"
    )
    return Tcl.ERROR

  var
    count: Tcl.Size
    matrix3: vmath.Mat3
  
  let ptable = cast[PixTable](clientData)

  # Get destination image
  let img1 = ptable.loadImage(interp, objv[1])
  if img1.isNil: return Tcl.ERROR

  # Get source image
  let img2 = ptable.loadImage(interp, objv[2])
  if img2.isNil: return Tcl.ERROR

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
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_fill(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills the image with the color.
  #
  # image   - [img::new]
  # value   - string [color] or [paint] object
  #
  # This proc takes an image object and a color or paint object as arguments.
  # It will fill the image with the specified color or paint object.
  # The color or paint object can be specified as a string or as an object.
  # If a string is specified, it should be a valid color string.
  # If a paint object is specified, it should be a valid paint object.
  # The paint object can be created using the *pix::paint::new* proc.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> color|<paint>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Get fill value argument
  let fillArg = $Tcl.GetString(objv[2])

  # Handle paint object or color value
  if ptable.hasPaint(fillArg):
    img.fill(ptable.getPaint(fillArg))
  else:
    try:
      # Fall back to color parsing.
      img.fill(pixUtils.getColor(objv[2]))
    except InvalidColor as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_readImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Read image file.
  #
  # filePath - path file
  #
  # This proc will attempt to read the image file and create a new image
  # object from it.
  #
  # Returns: A *new* [img] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "full pathfile")
    return Tcl.ERROR

  let file = $Tcl.GetString(objv[1])
  let ptable = cast[PixTable](clientData)

  # Read the image from the file
  # Note: This will throw an exception if the file does not exist,
  # or if the file is not a valid image or supported.
  let img = try:
    readimage(file)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(img)
  ptable.addImage(imgKey, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_fillpath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills a path with a color or paint object.
  #
  # image      - The [img::new] object to draw on.
  # pathValue  - A string containing a path or a path object.
  #             The path can be specified as a string like this:
  #             **M 0 0 L 100 0 L 100 100 Z**
  #             or as a path object created with the *pix::path::new* proc.
  # paintValue - A string containing a [color] or a [paint] object.
  #             The color can be specified as a string like this:
  #             **#FF0000** or as a paint object created with the
  #             *pix::paint::new* proc.
  # matrix     - A (optional:mat3idendity) matrix to transform the path with.
  #             The matrix should be a **3x3** matrix specified as a list of 9
  #             numbers.
  #
  # Returns: Nothing.
  if objc notin [4, 5]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<img> '<path>|stringPath' 'color|<paint>' ?matrix:optional"
    )
    return Tcl.ERROR

  var
    img: pixie.Image
    matrix3: vmath.Mat3
    hasMatrix: bool = false

  let ptable = cast[PixTable](clientData)

  if $Tcl.GetString(objv[0]) == "pix::ctx::fillPath":
    # Context
    let ctx = ptable.loadContext(interp, objv[1])
    if ctx.isNil: return Tcl.ERROR
    img = ctx.image
  else:
    # Image
    img = ptable.loadImage(interp, objv[1])
    if img.isNil: return Tcl.ERROR

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
    let path = if ptable.hasPath(pathArg): ptable.getPath(pathArg)
               else: parsePath(pathArg)

    # Get paint/color object
    let paint = if ptable.hasPaint(paintArg): ptable.getPaint(paintArg)
                else: pixUtils.getColor(objv[3]).SomePaint

    # Apply fill with or without matrix
    if hasMatrix:
      img.fillPath(path, paint, matrix3)
    else:
      img.fillPath(path, paint)
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_strokePath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Strokes a path with a color or a paint object and optional
  # stroke and line join options.
  #
  # image   - The [img::new] object to draw on.
  # value   - A string path or a [path] object created with the
  #          *pix::path::new* Tcl proc.
  # color   - A string [color] or a [paint] object created with the
  #          *pix::paint::new* Tcl proc.
  # options - A Tcl dict, see attributes below.
  #
  #  * A dictionary of options to customize the stroke. The options are:<br>
  #  #Begintable
  #  **strokeWidth** : The width of the stroke.
  #  **transform**   : The transformation matrix to apply to the path.
  #  **lineCap**     : The line cap style (Enum).
  #  **miterLimit**  : The miter limit for the line join.
  #  **lineJoin**    : The line join style (Enum).
  #  **dashes**      : The dashes to apply to the stroke.
  #  #EndTable
  #
  # Returns: Nothing.
  if objc != 5:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<img> 'pathstring' 'color|<paint>' {?strokeWidth ?value ?transform ?value ...}"
    )
    return Tcl.ERROR

  var img: pixie.Image
  let ptable = cast[PixTable](clientData)

  if $Tcl.GetString(objv[0]) == "pix::ctx::strokePath":
    # Context
    let ctx = ptable.loadContext(interp, objv[1])
    if ctx.isNil: return Tcl.ERROR
    img = ctx.image
  else:
    # Image
    img = ptable.loadImage(interp, objv[1])
    if img.isNil: return Tcl.ERROR

  let
    somepath = $Tcl.GetString(objv[2])
    somepaint = $Tcl.GetString(objv[3])

  # Parse the options from the Tcl dict and set the fields of 
  # the 'RenderOptions' object.
  var opts = pixParses.RenderOptions()

  try:
    pixParses.dictOptions(interp, objv[4], opts)

    let path = 
      if ptable.hasPath(somepath):
        ptable.getPath(somepath)
      else: 
        parsePath(somepath)
    let paint = 
      if ptable.hasPaint(somepaint): 
        ptable.getPaint(somepaint) 
      else:
        SomePaint(pixUtils.getColor(objv[3]))

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
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_blur(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Applies Gaussian blur to the image given a radius.
  #
  # image   - [img::new]
  # radius  - double value
  # color   - string [color] (optional:transparent)
  #
  # Returns: Nothing.
  if objc notin [3, 4]:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> radius ?color:optional")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Radius
  var radius: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], radius) != Tcl.OK:
    return Tcl.ERROR

  # 'blur' blurs the image using a Gaussian blur algorithm. The blur radius
  # is the distance from the point of the image to the point of the blur
  # effect.  The color is the color of the blur effect.
  try:
    if objc == 4:
      # If the user has provided a color, blur the image with that color.
      let color = pixUtils.getColor(objv[3])
      img.blur(radius, color)
    else:
      img.blur(radius)
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_shadow(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Create a shadow of the image with the offset, spread and blur.
  #
  # image   - [img::new]
  # options - dict (offset, spread, blur, [color])
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<img> {offset? ?value spread? ?value blur? ?value color? ?value}"
    )
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  var shadow: pixie.Image
  # Parse the options from the Tcl dict and set the fields of 
  # the 'ShadowOptions' object.
  var opts = pixParses.RenderShadow()

  try:
    pixParses.shadowOptions(interp, objv[2], opts)

    shadow = img.shadow(
      offset = opts.offset,
      spread = opts.spread,
      blur   = opts.blur,
      color  = opts.color
    )
  except ValueError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(shadow)
  ptable.addImage(imgKey, shadow)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_fillText(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills the image with the rendered text.
  #
  # image  - [img::new]
  # object - [font::typeset] or [font::readFont] object
  # args   - A Tcl dict (options described below)
  #
  # There are two ways to use this proc:
  #
  # 1. With an [font::typeset] object:<br>
  #    * `$img arrangement {?matrix3 ?value}`<br>
  #    This will render the arrangement onto the image. If the matrix3 optional
  #    argument is provided, it will be used to transform the arrangement before
  #    rendering.
  #
  # 2. With a [font] object and a `text` string:<br>
  #    * `$img font text options`<br>
  #    This will render the text string onto the image using the font object.
  #    The options dict can be used to specify the following:
  #      #Begintable
  #      **transform** : A list transform to apply to the text.
  #      **bounds**    : A list bounds to use for the text.
  #      **hAlign**    : A Enum horizontal alignment of the text.
  #      **vAlign**    : A Enum vertical alignment of the text.
  #     #EndTable
  #
  # In either case, the [img] object is the first argument, and the [font::typeset]
  # or [font::readFont] object is the second argument.
  #
  # Returns: Nothing.
  if objc notin (3..5):
    let errMsg = "<img> <arrangement> ?matrix3:optional or " &
    "<img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Font or arrangement.
  let arg2 = $Tcl.GetString(objv[2])

  var matrix3: vmath.Mat3

  if ptable.hasArr(arg2):
    # Arrangement
    let arrangement = ptable.getArr(arg2)
    if objc == 4:
      if pixUtils.matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
        return Tcl.ERROR
      try:
        # Use the fillText method of the image to render text based on the given arrangement.
        # The arrangement object contains pre-calculated positions and styles for text glyphs.
        # The matrix3 argument is a transformation matrix that will be applied to the text.
        # This allows for transformations such as scaling, rotation, or translation of the text.
        img.fillText(arrangement, matrix3)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    else:
      try:
        img.fillText(arrangement)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # Font
    let font = ptable.loadFont(interp, objv[2])
    if font.isNil: return Tcl.ERROR

    if objc < 4:
      return pixUtils.errorMSG(interp,
      "pix(error): If <font> is present, a 'text' must be associated."
      )

    let text = $Tcl.GetString(objv[3])
    # Create a new RenderOptions object to store font rendering options.
    var opts = pixParses.RenderOptions()

    try:
      if objc == 5:
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
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_resize(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Resize an image to a given height and width
  #
  # image  - [img::new]
  # size   - list width,height
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {width height}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets size.
  var width, height: cint

  if pixParses.getListInt(interp, objv[2], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  # We create a new image with the new size
  # This takes care of creating a new image with the correct size
  # and scaling the image.  The *pix::img::resize* proc is smart enough
  # to scale the image to the new size.
  let newimg = try:
    img.resize(width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(newimg)
  ptable.addImage(imgKey, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_get(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets image size.
  #
  # image - [img::new]
  #
  # Returns: A Tcl dictionary with keys containing the width and the 
  # height of the [img].
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", 5), Tcl.NewIntObj(img.width.cint))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("height", 6), Tcl.NewIntObj(img.height.cint))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_getPixel(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets a pixel at (x, y) or returns transparent black if outside of bounds.
  #
  # image        - [img::new]
  # coordinates  - list x,y (x column of the pixel, y row of the pixel)
  #
  # Returns: A Tcl dictionary with keys (r, g, b, a) representing 
  # the red, green, blue, and alpha (opacity) values of the pixel color.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets coordinates.
  var x, y: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let 
    data = img[x, y]
    dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", 1), Tcl.NewIntObj(data.r.cint))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", 1), Tcl.NewIntObj(data.g.cint))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", 1), Tcl.NewIntObj(data.b.cint))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", 1), Tcl.NewIntObj(data.a.cint))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_setPixel(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets a pixel at (x, y) or does nothing if outside of bounds.
  #
  # image       - [img::new]
  # coordinates - list x,y
  # color       - string [color]
  #
  # Returns: Nothing.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} color")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets coordinates.
  var x, y: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  try:
    img[x, y] = pixUtils.getColor(objv[3])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_applyOpacity(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Multiplies alpha of the image by opacity.
  #
  # image    - [img::new]
  # opacity  - double value
  #
  # Image *pix::img::applyOpacity* multiplies the opacity of the image by the
  # opacity parameter. The opacity parameter is a double between
  # 0 and 1. 0 is fully transparent. 1 is fully opaque.<br> Any value
  # inbetween is a mix of the two.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> opacity")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets opacity.
  var opacity: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], opacity) != Tcl.OK:
    return Tcl.ERROR

  img.applyOpacity(opacity)

  return Tcl.OK

proc pix_image_ceil(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # A value of 0 stays 0. Anything else turns into 255.
  #
  # image - [img::new]
  #
  # The *pix::img::ceil* proc takes an image and replaces all pixels that are
  # not fully transparent (i.e. have an alpha of 0) with a pixel that
  # is fully opaque (i.e. has an alpha of 255). This is useful for
  # creating masks from images.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  img.ceil()

  return Tcl.OK

proc pix_image_diff(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Call this proc on the master image, passing the image to
  # compare to the master image. The *pix::img::diff* method returns a dict
  # with two elements.
  #
  # masterimage - [img::new]
  # image       - [img::new]
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
  # Returns: A Tcl dictionary with keys (score, imgdiff).
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<masterimg> <img>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Image master
  let masterimg = ptable.loadImage(interp, objv[1])
  if masterimg.isNil: return Tcl.ERROR

  # Image
  let img = ptable.loadImage(interp, objv[2])
  if img.isNil: return Tcl.ERROR

  let (score, newimg) = try:
    masterimg.diff(img)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newimg)
  ptable.addImage(p, newimg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("score", 5), Tcl.NewDoubleObj(score))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("img", 3), Tcl.NewStringObj(p.cstring, -1))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_flipHorizontal(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # This method modifies the image in place, flipping it around the Y-axis.
  # As a result, the left and right sides of the image are swapped.
  # This operation is useful for creating mirror images or for certain graphical effects.
  #
  # image - [img::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  img.flipHorizontal()

  return Tcl.OK

proc pix_image_flipVertical(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # This method modifies the image in place, flipping it around the X-axis.
  #
  # image - [img::new]
  #
  # As a result, the top and bottom sides of the image are swapped.
  # This operation is useful for creating mirror images or for certain graphical effects.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  img.flipVertical()

  return Tcl.OK

proc pix_image_getColor(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets a color at (x, y) or returns transparent black if outside of bounds.
  #
  # image        - [img::new]
  # coordinates  - list x,y
  #
  # Returns: A Tcl dictionary with keys (r, g, b, a) representing
  # the red, green, blue, and alpha (opacity) values of the pixel color.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets coordinates.
  var x, y: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Retrieve the color of the pixel at coordinates (x, y) from the image.
  let color = img.getColor(x, y)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", 1), Tcl.NewDoubleObj(color.r))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", 1), Tcl.NewDoubleObj(color.g))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", 1), Tcl.NewDoubleObj(color.b))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", 1), Tcl.NewDoubleObj(color.a))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_inside(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Returns true if (x, y) is inside the image, false otherwise.
  #
  # image        - [img::new]
  # coordinates  - list x,y
  #
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Gets coordinates.
  var x, y: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  let value = if img.inside(x, y): 1 else: 0

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_image_invert(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Inverts all of the colors and alpha.
  #
  # image - [img::new]
  #
  # This will flip the image by changing the color and alpha of every pixel.
  # The result will be a new image where every pixel is the exact opposite of
  # the corresponding pixel in the original image.
  #
  # For example, if the original image is entirely white, the resulting image
  # will be entirely black. If the original image is entirely black, the
  # resulting image will be entirely white.
  # This is useful for things like getting the negative of an image, or
  # creating a **reverse** version of an image.
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Invert the image.
  img.invert()

  return Tcl.OK

proc pix_image_isOneColor(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks if the entire image is the same color.
  #
  # image - [img::new]
  #
  # Returns: A Tcl boolean value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  let value = if img.isOneColor(): 1 else: 0

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_image_isOpaque(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks if the entire image is opaque (alpha values are all 255).
  #
  # image - [img::new]
  #
  # Returns: A Tcl boolean value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  let value = if img.isOpaque(): 1 else: 0

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_image_isTransparent(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks if this image is fully transparent or not.
  #
  # image - [img::new]
  #
  # Returns true, false otherwise.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  let value = if img.isTransparent(): 1 else: 0

  Tcl.SetObjResult(interp, Tcl.NewIntObj(value.cint))

  return Tcl.OK

proc pix_image_magnifyBy2(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Scales image up by 2 ^ power.
  #
  # image  - [img::new]
  # power  - integer value (optional:1)
  #
  # If only one argument is given (i.e. the image object), just magnify by 2.
  # This is a convenience for the user.
  #
  # Returns: A *new* [img] object.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> ?power:optional")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  var
    power: cint = 1
    newimg: pixie.Image

  if objc == 3:
    if Tcl.GetIntFromObj(interp, objv[2], power) != Tcl.OK:
      return Tcl.ERROR
    try:
      newimg = img.magnifyBy2(power)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      # The result is stored in newimg.
      newimg = img.magnifyBy2()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(newimg)
  ptable.addImage(imgKey, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_minifyBy2(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Scales the image down by an integer scale.
  #
  # image  - [img::new]
  # power  - integer value (optional:1)
  #
  # We were given an integer power as an argument, so we call
  # img.minifyBy2() with that power. This will scale the image
  # down by 2^power.
  #
  # Returns: A *new* [img] object.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> ?power:optional")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  var
    power: cint = 1
    newimg: pixie.Image

  if objc == 3:
    if Tcl.GetIntFromObj(interp, objv[2], power) != Tcl.OK:
      return Tcl.ERROR
    try:
      newimg = img.minifyBy2(power)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      newimg = img.minifyBy2()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(newimg)
  ptable.addImage(imgKey, newimg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_opaqueBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Checks the bounds of opaque pixels.
  #
  # image - [img::new]
  #
  # Some images have transparency around them,
  # use this to find just the visible part of the image and then use subImage to cut
  # it out. Returns zero rect if whole image is transparent,
  # or just the size of the image if no edge is transparent.
  #
  # Returns A Tcl dictionary with keys *(x, y, w, h)*.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  let
    rect = img.opaqueBounds()
    dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_image_rotate90(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Rotates the image 90 degrees clockwise.
  #
  # image - [img::new]
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  try:
    img.rotate90()
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_subImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets a sub image from this image.
  #
  # image        - [img::new]
  # coordinates  - list x,y
  # size         - list width,height
  #
  # The subImage function extracts a portion of the original image starting at (x, y) 
  # and spanning the width and height specified.
  #
  # Returns: A *new* [img] object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListInt(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  # Create a subimage from the given image (img) based on specified 
  # coordinates and size.
  let subimage = try:
    img.subImage(x, y, width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(subimage)
  ptable.addImage(imgKey, subimage)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_superImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Either cuts a sub image or returns a super image with padded transparency.
  #
  # image        - [img::new]
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
  # Returns: A *new* [img] object.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Coordinates
  var x, y, width, height: cint

  if pixParses.getListInt(interp, objv[2], x, y, 
    "wrong # args: 'coordinates' should be 'x' 'y'") != Tcl.OK:
    return Tcl.ERROR

  # Size
  if pixParses.getListInt(interp, objv[3], width, height, 
    "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
    return Tcl.ERROR

  let subimage = try:
    img.superImage(x, y, width, height)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(subimage)
  ptable.addImage(imgKey, subimage)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_image_fillGradient(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills with the Paint gradient.
  #
  # image  - [img::new]
  # paint  - [paint::new]
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> <paint>")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Paint
  let paint = ptable.loadPaint(interp, objv[2])
  if paint.isNil: return Tcl.ERROR

  try:
    img.fillGradient(paint)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_strokeText(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # This procedure is responsible for rendering text onto an image with various styling options.
  #
  # image       - [img].
  # object      - This can either be a 'arrangement' or a [font] object.
  # text        - If the object is a [font] object, this parameter is the text string that needs to be rendered on the image.
  # options     - Check out the description below.
  #
  # * *arroptions*  : (Optional) A Tcl dictionary that contains various attributes for styling the text stroke. 
  #                 These attributes include:<br>
  #                 #Begintable
  #                 **transform**   : A list representing a transformation matrix to apply.
  #                 **strokeWidth** : A double value specifying the width of the stroke.
  #                 **lineCap**     : An enumeration value describing the shape of the stroke's end caps.
  #                 **lineJoin**    : An enumeration value for the shape of the corners in joined lines.
  #                 **miterLimit**  : A double value that limits the length of the miter when lineJoin is set to 'MiterJoin'.
  #                 **dashes**      : A list indicating the pattern for dashed lines.
  #                 #EndTable
  # * *fontoptions* : (Optional) A Tcl dictionary that provides additional styling options specific to the font rendering process:<br>
  #                 #Begintable
  #                 **transform** : A list for a transformation matrix to apply to the text.
  #                 **bounds**    : A list defining the bounding box for the text rendering region.
  #                 **hAlign**    : An enumeration for horizontal alignment of the text.
  #                 **vAlign**    : An enumeration for vertical alignment of the text.
  #                 #EndTable
  #
  # Returns: Nothing.
  if objc notin (3..5):
    let errMsg = "<img> <arrangement> {?transform ?value ?strokeWidth ?value ?lineCap ?value " &
    "?lineJoin ?value ?miterLimit ?value ?dashes ?value} or " &
    "<img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  # Font or Arrangement.
  let arg2 = $Tcl.GetString(objv[2])

  # Arrangement
  if ptable.hasArr(arg2):
    let arrangement = ptable.getArr(arg2)
    var opts = pixParses.RenderOptions()

    try:
      if objc == 4:
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
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # Font
    let font = ptable.loadFont(interp, objv[2])
    if font.isNil: return Tcl.ERROR

    if objc < 4:
      return pixUtils.errorMSG(interp,
      "pix(error): If <font> is present, a 'text' must be associated."
      )

    let text = $Tcl.GetString(objv[3])
    var opts = pixParses.RenderOptions()

    try:
      if objc == 5:
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
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_writeFile(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Save image file.
  #
  # image    - [img::new]
  # filePath - string (\*.png|\*.bmp|\*.qoi|\*.ppm)
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<img> filePath")
    return Tcl.ERROR

  # Image
  let ptable = cast[PixTable](clientData)
  let img = ptable.loadImage(interp, objv[1])
  if img.isNil: return Tcl.ERROR

  try:
    # Call the writeFile method of the image to save the image to the
    # file specified by filePath.
    img.writeFile($Tcl.GetString(objv[2]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_image_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy current image or all images if special word `all` is specified.
  #
  # value - [img::new] object or string
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<img>|string('all')")
    return Tcl.ERROR
  
  let ptable = cast[PixTable](clientData)
  let key = $Tcl.GetString(objv[1])

  # Image
  if key == "all":
    ptable.clearImage()
  else:
    ptable.delKeyImage(key)

  return Tcl.OK