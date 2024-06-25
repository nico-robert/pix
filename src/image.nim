# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_image(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets a new image.
  # 
  # size  - list width + height
  #
  # Returns a 'new' img object.
  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "{width height}")
      return Tcl.ERROR
    
    # Size
    if Tcl.ListObjGetElements(interp, objv[1], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'size' should be 'width' 'height'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
    
    let img = newImage(width, height)
 
    let myPtr = cast[pointer](img)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # New image copy.
  # 
  # image - object
  #
  # Returns a 'new' img object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR
    
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    
    let copyimg = img.copy()

    let myPtr = cast[pointer](copyimg)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = copyimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_draw(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Draws one image onto another using a matrix transform and color blending.
  # 
  # image     - object
  # image2    - object
  # matrix3   - list (optional:mat3)
  # blendMode - Enum value (optional:NormalBlend)
  #
  # Returns nothing.
  try:
    let count: cint = 0
    let elements: Tcl.PPObj = nil
    var matrix3: vmath.Mat3

    if objc != 3 and objc != 4 and objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<img1> <img2> matrix3:optional blendMode:optional")
      return Tcl.ERROR
    
    # Image1
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img1 = imgTable[$arg1]

    # Image2
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let img2 = imgTable[$arg2]

    if objc == 3:
      img1.draw(img2)
    elif objc == 4:
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
        return Tcl.ERROR
      if count == 1:
        let myEnum = parseEnum[BlendMode]($arg3)
        img1.draw(img2, blendMode = myEnum)
      else:
        if matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
          return Tcl.ERROR
        img1.draw(img2, transform = matrix3)
    else:
      if matrix3x3(interp, objv[4], matrix3) != Tcl.OK:
        return Tcl.ERROR

      let arg5 = Tcl.GetStringFromObj(objv[5], nil)
      let myEnum = parseEnum[BlendMode]($arg5)

      img1.draw(img2, transform = matrix3, blendMode = myEnum)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the image with the color.
  # 
  # image   - object
  # value   - string color or <paint> object
  #
  # Returns nothing.
  try:
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> color|<paint>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Color or Paint
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    if paintTable.hasKey($arg2):
      let paint = paintTable[$arg2]
      img.fill(paint)
    else:
      let str = $arg2
      var crgbx: ColorRGBX
      if isColorRgbx(str, crgbx):
        img.fill(crgbx)
      else:
        img.fill(parseHtmlColor(str))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_readImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills the image with the color.
  # 
  # filePath - path file
  #
  # Returns a 'new' img object.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "filePath")
      return Tcl.ERROR

    let file = Tcl.GetStringFromObj(objv[1], nil)
    let img = readimage($file)
    
    let myPtr = cast[pointer](img)
    let p = ("0x" & cast[uint64](myPtr).toHex & "^img").toLowerAscii
    imgTable[p] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_fillpath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills a path.
  # 
  # image      - object
  # pathValue  - string path  or path object
  # paintValue - string color or paint object
  # matrix     - list (optional:mat3)
  #
  # Returns nothing.
  try:
    var img: Image
    var matrix3: vmath.Mat3

    let cmd = Tcl.GetStringFromObj(objv[0], nil)

    if objc notin (4..5):
      Tcl.WrongNumArgs(interp, 1, objv, "<img> <path>|string color|<paint> matrix:optional")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    if cmd == "pix::ctx::fillPath":
      let ctx = ctxTable[$arg1]
      img = ctx.image
    else:
      img = imgTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let arg3 = Tcl.GetStringFromObj(objv[3], nil)
    
    var myTable = false
    var hasMatrix = false

    if pathTable.hasKey($arg2):
      myTable = true

    if objc == 5:
      if matrix3x3(interp, objv[4], matrix3) != Tcl.OK:
        return Tcl.ERROR
      hasMatrix = true
    
    if paintTable.hasKey($arg3):
      let paint = paintTable[$arg3]
      if myTable:
        let mypath = pathTable[$arg2]
        if hasMatrix:
          img.fillPath(mypath, paint, matrix3)
        else:
          img.fillPath(mypath, paint)
      else:
        let mypath = $arg2
        if hasMatrix:
          img.fillPath(mypath, paint, matrix3)
        else:
          img.fillPath(mypath, paint)
    else:
      # Color
      let color = parseHtmlColor($arg3).rgba
      if myTable:
        let mypath = pathTable[$arg2]
        if hasMatrix:
          img.fillPath(mypath, color, matrix3)
        else:
          img.fillPath(mypath, color)
      else:
        let mypath = $arg2
        if hasMatrix:
          img.fillPath(mypath, color, matrix3)
        else:
          img.fillPath(mypath, color)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Strokes a path.
  # 
  # image   - object
  # value   - string path
  # color   - string
  # options - dict (strokeWidth, transform, lineCap, miterLimit, lineJoin, dashes)
  #
  # Returns nothing.
  try:
    var sWidth, v: cdouble = 1.0
    let mymiterLimit: cdouble = defaultMiterLimit
    let count, dashescount: cint = 0
    let elements, dasheselements: Tcl.PPObj = nil
    var matrix3: vmath.Mat3 = mat3()
    var img: Image
    var mydashes: seq[float32] = @[]
    var myEnumlineCap, myEnumlineJoin: string = "null"

    let cmd = Tcl.GetStringFromObj(objv[0], nil)

    if objc != 5:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> 'pathstring' color {key value key value ...}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)

    if cmd == "pix::ctx::strokePath":
      let ctx = ctxTable[$arg1]
      img = ctx.image
    else:
      img = imgTable[$arg1]

    let arg3 = Tcl.GetStringFromObj(objv[3], nil)
    let color = parseHtmlColor($arg3).rgba

    # Dict
    if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      Tcl.SetResult(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...", nil)
      return Tcl.ERROR

    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "strokeWidth":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], sWidth.addr) != Tcl.OK:
            return Tcl.ERROR
        of "transform":
          if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
            return Tcl.ERROR
        of "lineCap":
          let arg = Tcl.GetStringFromObj(elements[i+1], nil)
          myEnumlineCap = $arg
        of "miterLimit":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], mymiterLimit.addr) != Tcl.OK:
            return Tcl.ERROR
        of "lineJoin":
          let arg = Tcl.GetStringFromObj(elements[i+1], nil)
          myEnumlineJoin = $arg
        of "dashes":
          if Tcl.ListObjGetElements(interp, elements[i+1], dashescount.addr, dasheselements.addr) != Tcl.OK:
            return Tcl.ERROR
          for j in 0..dashescount-1:
            if Tcl.GetDoubleFromObj(interp, dasheselements[j], v.addr) != Tcl.OK:
              return Tcl.ERROR
            mydashes.add(v)
        else:
          Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
          return Tcl.ERROR
      inc(i, 2)

    let myEnumLC = parseEnum[LineCap]($myEnumlineCap, ButtCap)
    let myEnumLJ = parseEnum[LineJoin]($myEnumlineJoin, MiterJoin)

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    if pathTable.hasKey($arg2):
      img.strokePath(
        pathTable[$arg2], color,
        transform = matrix3,
        strokeWidth = sWidth,
        lineCap = myEnumLC,
        lineJoin = myEnumLJ,
        miterLimit = mymiterLimit,
        dashes = mydashes
      )
    else:
      img.strokePath(
        $arg2, color,
        transform = matrix3,
        strokeWidth = sWidth,
        lineCap = myEnumLC,
        lineJoin = myEnumLJ,
        miterLimit = mymiterLimit,
        dashes = mydashes
      )

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_blur(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Applies Gaussian blur to the image given a radius.
  # 
  # image   - object
  # radius  - double value
  # color   - string (optional:transparent)
  #
  # Returns nothing.
  try:
    let radius: cdouble = 0

    if objc notin (3..4):
      Tcl.WrongNumArgs(interp, 1, objv, "<img> radius color:optional")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[2], radius.addr) != Tcl.OK: return Tcl.ERROR

    if objc == 4:
      # Color RGBA check
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let color = parseHtmlColor($arg3).rgba
      img.blur(radius, color)
    else:
      img.blur(radius)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
    
proc pix_image_shadow(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a shadow of the image with the offset, spread and blur.
  # 
  # image   - object
  # options - dict (offset, spread, blur, color)
  #
  # Returns nothing.
  try:
    let x, y, spread, blur: cdouble = 0
    let count, dictcount: cint = 0
    let elements, dict : Tcl.PPObj = nil
    var colorShadow: ColorRGBA

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {offset? ?value spread? ?value blur? ?value color? ?value}")
      return Tcl.ERROR
      
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Dict
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      Tcl.SetResult(interp, "wrong # args: 'dict options' should be :key value key1 value1 ...", nil)
      return Tcl.ERROR

    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "offset":
          if Tcl.ListObjGetElements(interp, elements[i+1], dictcount.addr, dict.addr) != Tcl.OK:
            return Tcl.ERROR
          if dictcount != 2:
            Tcl.SetResult(interp, "wrong # args: 'offset' should be 'x' 'y'", nil)
            return Tcl.ERROR
            
          if Tcl.GetDoubleFromObj(interp, dict[0], x.addr) != Tcl.OK: return Tcl.ERROR
          if Tcl.GetDoubleFromObj(interp, dict[1], y.addr) != Tcl.OK: return Tcl.ERROR

        of "spread":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], spread.addr) != Tcl.OK:
            return Tcl.ERROR
        of "blur":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], blur.addr) != Tcl.OK:
            return Tcl.ERROR
        of "color":
          # Color RGBA check
          let el = Tcl.GetStringFromObj(elements[i+1], nil)
          colorShadow = parseHtmlColor($el).rgba
        else:
          Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
          return Tcl.ERROR
      inc(i, 2)
      
    let shadow = img.shadow(
      offset = vec2(x, y),
      spread = spread,
      blur = blur,
      color = colorShadow
    )
    
    let myPtr = cast[pointer](shadow)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let js = (hex & "^img").toLowerAscii

    imgTable[js] = shadow

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(js), -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

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
  try:
    var x, y: cdouble = 1.0
    let count, veccount: cint = 0
    let elements, vecelements: Tcl.PPObj = nil
    var matrix3: vmath.Mat3 = mat3()
    var vecBounds = vec2(0, 0)
    var myEnumhAlign, myEnumvAlign: string = "null"
  
    if objc != 3 and objc != 4 and objc != 5:
      let msg = """<img> <arrangement> matrix3:optional or
      <img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    if arrTable.hasKey($arg2):
      # Arrangement
      let arrangement = arrTable[$arg2]
      if objc == 4:
        if matrix3x3(interp, objv[3], matrix3) != Tcl.OK:
          return Tcl.ERROR
        img.fillText(arrangement, matrix3)
      else:
        img.fillText(arrangement)
    else:
      let font = fontTable[$arg2]
      if objc < 4:
        Tcl.SetResult(interp, cstring("pix(error): If <font> is present, a 'text' must be associated."), nil)
        return Tcl.ERROR

      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let text = $arg3

      if objc == 5:
        # Dict
        if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
          return Tcl.ERROR

        if count mod 2 == 1:
          Tcl.SetResult(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...", nil)
          return Tcl.ERROR

        var i = 0
        while i < count:
          let mkey = Tcl.GetStringFromObj(elements[i], nil)
          case $mkey:
            of "transform":
              if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
                return Tcl.ERROR
            of "hAlign":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumhAlign = $arg
            of "vAlign":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumvAlign = $arg
            of "bounds":
              if Tcl.ListObjGetElements(interp, elements[i+1], veccount.addr, vecelements.addr) != Tcl.OK:
                return Tcl.ERROR
              if veccount != 2:
                Tcl.SetResult(interp, "wrong # args: 'bounds' should be 'x' 'y'", nil)
                return Tcl.ERROR

              if Tcl.GetDoubleFromObj(interp, vecelements[0], x.addr) != Tcl.OK: return Tcl.ERROR
              if Tcl.GetDoubleFromObj(interp, vecelements[1], y.addr) != Tcl.OK: return Tcl.ERROR

              vecBounds = vec2(x, y)
            else:
              Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
              return Tcl.ERROR
          inc(i, 2)
        
        let myEnumLH = parseEnum[HorizontalAlignment]($myEnumhAlign, LeftAlign)
        let myEnumLV = parseEnum[VerticalAlignment]($myEnumvAlign, TopAlign)

        img.fillText(font, text, transform = matrix3, bounds = vecBounds, hAlign = myEnumLH, vAlign = myEnumLV)

      else:
        img.fillText(font, text)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_resize(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Resize an image to a given height and width
  # 
  # image  - object
  # size   - list width + height
  #
  # Returns nothing.
  try:
    let width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {width height}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'size' should be 'width' 'height'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR

    let newimg = img.resize(width, height)

    let myPtr = cast[pointer](newimg)
    let p = ("0x" & cast[uint64](myPtr).toHex & "^img").toLowerAscii
    imgTable[p] = newimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_get(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets image size.
  # 
  # image - object
  #
  # Returns Tcl dict (width, height).
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    let dictObj = Tcl.NewDictObj()

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("width", -1), Tcl.NewIntObj(img.width))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("height", -1), Tcl.NewIntObj(img.height))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_getPixel(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a pixel at (x, y) or returns transparent black if outside of bounds.
  # 
  # image        - object
  # coordinates  - list x,y
  #
  # Returns Tcl dict (r, g, b, a).
  try:
    let x, y: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    let dictObj = Tcl.NewDictObj()

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    let data = img[x, y]

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", -1), Tcl.NewIntObj(data.r.int))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", -1), Tcl.NewIntObj(data.g.int))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", -1), Tcl.NewIntObj(data.b.int))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", -1), Tcl.NewIntObj(data.a.int))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_setPixel(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a pixel at (x, y) or returns transparent black if outside of bounds.
  # 
  # image       - object
  # coordinates - list x,y 
  # color       - string color
  #
  # Returns nothing.
  try:
    let x, y: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} color")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    let arg3 = Tcl.GetStringFromObj(objv[3], nil)
    let color = parseHtmlColor($arg3).color

    img[x, y] = color

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_applyOpacity(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Multiplies alpha of the image by opacity.
  # 
  # image    - object
  # opacity  - double value
  #
  # Returns nothing.
  try:
    let opacity: cdouble = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> opacity")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # opacity
    if Tcl.GetDoubleFromObj(interp, objv[2], opacity.addr) != Tcl.OK:
      return Tcl.ERROR

    img.applyOpacity(opacity)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_ceil(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # A value of 0 stays 0. Anything else turns into 255.
  # 
  # image - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    img.ceil()

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_diff(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Compares the parameters and returns a score and image of the difference. 
  # 
  # masterimage - object
  # image       - object
  #
  # Returns Tcl dict (score, imgdiff).
  try:
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<masterimg> <img>")
      return Tcl.ERROR

    # Image master
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let masterimg = imgTable[$arg1]

    # Image
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let img = imgTable[$arg2]

    let (score, newimg) = masterimg.diff(img)

    let myPtr = cast[pointer](newimg)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = newimg

    let dictObj = Tcl.NewDictObj()

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("score", -1), Tcl.NewDoubleObj(score))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("img", -1), Tcl.NewStringObj(p.cstring, -1))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_flipHorizontal(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Flips the image around the Y axis.
  # 
  # image - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    img.flipHorizontal()

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_flipVertical(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Flips the image around the X axis.
  # 
  # image - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    img.flipVertical()

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_getColor(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a color at (x, y) or returns transparent black if outside of bounds.
  # 
  # image        - object
  # coordinates  - list x,y
  #
  # Returns Tcl dict (r, g, b, a).
  try:
    let x, y: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    let dictObj = Tcl.NewDictObj()

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK:
      return Tcl.ERROR

    let c = img.getColor(x, y)

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("r", -1), Tcl.NewDoubleObj(c.r))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("g", -1), Tcl.NewDoubleObj(c.g))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("b", -1), Tcl.NewDoubleObj(c.b))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("a", -1), Tcl.NewDoubleObj(c.a))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_inside(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns true if (x, y) is inside the image, false otherwise.
  # 
  # image        - object
  # coordinates  - list x,y
  #
  try:
    let x, y: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil
    var val: int = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y}")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'x' 'y'", nil)
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR

    if img.inside(x, y): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_invert(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Inverts all of the colors and alpha.
  # 
  # image - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    img.invert()

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_isOneColor(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if the entire image is the same color.
  # 
  # image - object
  #
  # Returns true, false otherwise.
  try:
    var val: int = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if img.isOneColor(): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_isOpaque(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if the entire image is opaque (alpha values are all 255). 
  # 
  # image - object
  #
  # Returns true, false otherwise.
  try:
    var val: int = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if img.isOpaque(): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_isTransparent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks if this image is fully transparent or not.
  # 
  # image - object
  #
  # Returns true, false otherwise.
  try:
    var val: int = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if img.isTransparent(): val = 1

    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_magnifyBy2(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Scales image up by 2 ^ power.
  # 
  # image  - object
  # power  - integer value (optional:1)
  #
  # Returns a 'new' img object.
  try:
    let power: cint = 1 
    var newimg: Image

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<img> power:optional")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if objc == 3:
      if Tcl.GetIntFromObj(interp, objv[2], power.addr) != Tcl.OK:
        return Tcl.ERROR
      newimg = img.magnifyBy2(power.int)
    else:
      newimg = img.magnifyBy2()

    let myPtr = cast[pointer](newimg)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = newimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_minifyBy2(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Scales the image down by an integer scale.
  # 
  # image  - object
  # power  - integer value (optional:1)
  #
  # Returns a 'new' img object.
  try:
    let power: cint = 1 
    var newimg: Image

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<img> power:optional")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    if objc == 3:
      if Tcl.GetIntFromObj(interp, objv[2], power.addr) != Tcl.OK:
        return Tcl.ERROR
      newimg = img.minifyBy2(power.int)
    else:
      newimg = img.minifyBy2()

    let myPtr = cast[pointer](newimg)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = newimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_opaqueBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Checks the bounds of opaque pixels. Some images have transparency around them,
  # use this to find just the visible part of the image and then use subImage to cut
  # it out. Returns zero rect if whole image is transparent,
  # or just the size of the image if no edge is transparent.
  # 
  # image - object
  #
  # Returns Tcl dict (x, y, w, h).
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    let dictObj = Tcl.NewDictObj()

    let rect = img.opaqueBounds()

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", -1), Tcl.NewDoubleObj(rect.x))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", -1), Tcl.NewDoubleObj(rect.y))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", -1), Tcl.NewDoubleObj(rect.w))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", -1), Tcl.NewDoubleObj(rect.h))

    Tcl.SetObjResult(interp, dictObj)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_rotate90(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Rotates the image 90 degrees clockwise.
  # 
  # image - object
  #
  # Returns nothing.
  try:
    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    img.rotate90()

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_subImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets a sub image from this image.
  # 
  # image        - object
  # coordinates  - list x,y
  # size         - list width + height
  #
  # Returns a 'new' img object.
  try:
    let x, y, width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'width' 'height'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
    
    # Size
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'size' should be 'width' 'height'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
    
    let subimage = img.subImage(x, y, width, height)
 
    let myPtr = cast[pointer](subimage)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = subimage

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_superImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Either cuts a sub image or returns a super image with padded transparency.
  # 
  # image        - object
  # coordinates  - list x,y
  # size         - list width + height
  #
  # Returns a 'new' img object.
  try:
    let x, y, width, height: cint = 0
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> {x y} {width height}")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Coordinates
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'coordinates' should be 'x' 'y'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], x.addr) != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], y.addr) != Tcl.OK: return Tcl.ERROR
    
    # Size
    if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: 'size' should be 'width' 'height'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], width.addr)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK: return Tcl.ERROR
    
    let subimage = img.superImage(x, y, width, height)
 
    let myPtr = cast[pointer](subimage)
    let hex = "0x" & cast[uint64](myPtr).toHex
    let p = (hex & "^img").toLowerAscii

    imgTable[p] = subimage

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_fillGradient(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Fills with the Paint gradient.
  # 
  # image  - object
  # paint  - object
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> <paint>")
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Paint
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let paint = paintTable[$arg2]

    img.fillGradient(paint)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

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
  try:
    var x, y, sWidth, v: cdouble = 1.0
    let mymiterLimit: cdouble = defaultMiterLimit
    let count, veccount, dashescount: cint = 0
    let elements, vecelements, dasheselements: Tcl.PPObj = nil
    var matrix3: vmath.Mat3 = mat3()
    var vecBounds = vec2(0, 0)
    var mydashes: seq[float32] = @[]
    var myEnumlineCap, myEnumlineJoin: string = "null"
    var myEnumhAlign, myEnumvAlign: string = "null"
  
    if objc != 3 and objc != 4 and objc != 5:
      let msg = """
      <img> <arrangement> {?transform ?value ?strokeWidth ?value ?lineCap ?value ?lineJoin ?value ?miterLimit ?value ?dashes ?value} or
      <img> <font> 'text' {?transform ?value ?bounds ?value ?hAlign ?value ?vAlign ?value}"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    let arg2 = Tcl.GetStringFromObj(objv[2], nil)

    if arrTable.hasKey($arg2):
      # Arrangement
      let arr = arrTable[$arg2]
      if objc == 4:
        # Dict
        if Tcl.ListObjGetElements(interp, objv[3], count.addr, elements.addr) != Tcl.OK:
          return Tcl.ERROR

        if count mod 2 == 1:
          Tcl.SetResult(interp, "wrong # args: 'arr options' should be :key value ?key1 ?value1 ...", nil)
          return Tcl.ERROR

        var i = 0
        while i < count:
          let mkey = Tcl.GetStringFromObj(elements[i], nil)
          case $mkey:
            of "strokeWidth":
              if Tcl.GetDoubleFromObj(interp, elements[i+1], sWidth.addr) != Tcl.OK:
                return Tcl.ERROR
            of "transform":
              if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
                return Tcl.ERROR
            of "lineCap":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumlineCap = $arg
            of "miterLimit":
              if Tcl.GetDoubleFromObj(interp, elements[i+1], mymiterLimit.addr) != Tcl.OK:
                return Tcl.ERROR
            of "lineJoin":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumlineJoin = $arg
            of "dashes":
              if Tcl.ListObjGetElements(interp, elements[i+1], dashescount.addr, dasheselements.addr) != Tcl.OK:
                return Tcl.ERROR
              for j in 0..dashescount-1:
                if Tcl.GetDoubleFromObj(interp, dasheselements[j], v.addr) != Tcl.OK:
                  return Tcl.ERROR
                mydashes.add(v)
            else:
              Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
              return Tcl.ERROR
          inc(i, 2)

        let myEnumLC = parseEnum[LineCap]($myEnumlineCap, ButtCap)
        let myEnumLJ = parseEnum[LineJoin]($myEnumlineJoin, MiterJoin)

        img.strokeText(
          arr, transform = matrix3, strokeWidth = sWidth,
          lineCap = myEnumLC, lineJoin = myEnumLJ,
          dashes = mydashes, 
          miterLimit = mymiterLimit
        )

      else:
        img.strokeText(arr)
    else:
      let font = fontTable[$arg2]
      if objc < 4:
        Tcl.SetResult(interp, cstring("pix(error): If <font> is present, a 'text' must be associated."), nil)
        return Tcl.ERROR

      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let text = $arg3

      if objc == 5:
        # Dict
        if Tcl.ListObjGetElements(interp, objv[4], count.addr, elements.addr) != Tcl.OK:
          return Tcl.ERROR

        if count mod 2 == 1:
          Tcl.SetResult(interp, "wrong # args: 'font options' should be :key value ?key1 ?value1 ...", nil)
          return Tcl.ERROR

        var i = 0
        while i < count:
          let mkey = Tcl.GetStringFromObj(elements[i], nil)
          case $mkey:
            of "strokeWidth":
              if Tcl.GetDoubleFromObj(interp, elements[i+1], sWidth.addr) != Tcl.OK:
                return Tcl.ERROR
            of "transform":
              if matrix3x3(interp, elements[i+1], matrix3) != Tcl.OK:
                return Tcl.ERROR
            of "miterLimit":
              if Tcl.GetDoubleFromObj(interp, elements[i+1], mymiterLimit.addr) != Tcl.OK:
                return Tcl.ERROR
            of "hAlign":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumhAlign = $arg
            of "vAlign":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumvAlign = $arg
            of "lineCap":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumlineCap = $arg
            of "lineJoin":
              let arg = Tcl.GetStringFromObj(elements[i+1], nil)
              myEnumlineJoin = $arg
            of "dashes":
              if Tcl.ListObjGetElements(interp, elements[i+1], dashescount.addr, dasheselements.addr) != Tcl.OK:
                return Tcl.ERROR
              for j in 0..dashescount-1:
                if Tcl.GetDoubleFromObj(interp, dasheselements[j], v.addr) != Tcl.OK:
                  return Tcl.ERROR
                mydashes.add(v)
            of "bounds":
              if Tcl.ListObjGetElements(interp, elements[i+1], veccount.addr, vecelements.addr) != Tcl.OK:
                return Tcl.ERROR
              if veccount != 2:
                Tcl.SetResult(interp, "wrong # args: 'bounds' should be 'x' 'y'", nil)
                return Tcl.ERROR

              if Tcl.GetDoubleFromObj(interp, vecelements[0], x.addr) != Tcl.OK: return Tcl.ERROR
              if Tcl.GetDoubleFromObj(interp, vecelements[1], y.addr) != Tcl.OK: return Tcl.ERROR

              vecBounds = vec2(x, y)
            else:
              Tcl.SetResult(interp, cstring("wrong # args: Key '" & $mkey & "' not supported"), nil)
              return Tcl.ERROR
          inc(i, 2)

        let myEnumLC = parseEnum[LineCap]($myEnumlineCap, ButtCap)
        let myEnumLJ = parseEnum[LineJoin]($myEnumlineJoin, MiterJoin)
        let myEnumLH = parseEnum[HorizontalAlignment]($myEnumhAlign, LeftAlign)
        let myEnumLV = parseEnum[VerticalAlignment]($myEnumvAlign, TopAlign)

        img.strokeText(
          font, text, transform = matrix3, strokeWidth = sWidth,
          lineCap = myEnumLC, lineJoin = myEnumLJ, dashes = mydashes, 
          bounds = vecBounds, hAlign = myEnumLH, vAlign = myEnumLV,
          miterLimit = mymiterLimit
        )

      else:
        img.strokeText(font, text)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_writeFile(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Save image file.
  # 
  # image    - object
  # filePath - string (\*.png|\*.bmp|\*.jpeg|\*.qoi|\*.ppm)
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<img> filePath")
      return Tcl.ERROR

    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    let file = Tcl.GetStringFromObj(objv[2], nil)

    img.writeFile($file)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR

proc pix_image_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current image or all images if special word `all` is specified.
  # 
  # value - image object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<img>")
      return Tcl.ERROR
    
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    if arg1 == "all":
      imgTable.clear()
    else:
      imgTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    Tcl.SetResult(interp, cstring("pix(error): " & e.msg), nil)
    return Tcl.ERROR
