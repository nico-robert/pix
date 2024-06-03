# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_image(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let width, height: cint = -1
    let count: cint = 0
    let elements : Tcl.PPObj = nil

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " {width height}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
    
    # Size
    if Tcl.ListObjGetElements(interp, objv[1], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      Tcl.SetResult(interp, "wrong # args: argument should be 'width' 'height'", nil)
      return Tcl.ERROR
      
    if Tcl.GetIntFromObj(interp, elements[0], width.addr) != Tcl.OK:
      return Tcl.ERROR

    if Tcl.GetIntFromObj(interp, elements[1], height.addr) != Tcl.OK:
      return Tcl.ERROR
    
    let img = newImage(width, height)
 
    let im = cast[pointer](img)
    let hex = "0x" & cast[uint64](im).toHex
    let i = (hex & "^img").toLowerAscii

    imgTable[i] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(i), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:

    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <img>"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
    
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]
    
    let copyimg = img.copy()

    let im = cast[pointer](copyimg)
    let hex = "0x" & cast[uint64](im).toHex
    let i = (hex & "^img").toLowerAscii

    imgTable[i] = copyimg

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(i), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_draw(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let count: cint = 0
    let elements: Tcl.PPObj = nil
    var matrix3: vmath.Mat3

    if objc notin (3..5):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <img1> <img2> matrix3:optional blendMode:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
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
        if matrix3(interp, objv[3], matrix3) != Tcl.OK:
          return Tcl.ERROR
        img1.draw(img2, transform = matrix3)
    else:
      if matrix3(interp, objv[4], matrix3) != Tcl.OK:
        return Tcl.ERROR

      let arg5 = Tcl.GetStringFromObj(objv[5], nil)
      let myEnum = parseEnum[BlendMode]($arg5)

      img1.draw(img2, transform = matrix3, blendMode = myEnum)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_fill(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <img> color"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Color
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let color = parseHtmlColor($arg2).rgba

    img.fill(color)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_read(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    if objc != 2:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " 'file image'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    let file = Tcl.GetStringFromObj(objv[1], nil)
    let img = readimage($file)
    
    let im = cast[pointer](img)
    let p = ("0x" & cast[uint64](im).toHex & "^img").toLowerAscii
    imgTable[p] = img

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(p), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_fillpath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var img: Image
    var matrix3: vmath.Mat3

    let cmd = Tcl.GetStringFromObj(objv[0], nil)

    if objc notin (4..5):
      let mess = "wrong # args: " & $cmd & " <img> <path|string> color|paint matrix:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
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
      if matrix3(interp, objv[4], matrix3) != Tcl.OK:
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_strokePath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

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
      let mess = "wrong # args: " & $cmd & " <img> 'pathstring' color {key value key value ...}"
      Tcl.SetResult(interp, mess.cstring , nil)
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
      Tcl.SetResult(interp, "wrong # args: argument should key value key1 value1 ...", nil)
      return Tcl.ERROR

    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "strokeWidth":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], sWidth.addr) != Tcl.OK:
            return Tcl.ERROR
        of "transform":
          if matrix3(interp, elements[i+1], matrix3) != Tcl.OK:
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
    echo "pix(error): ", e.msg
    return Tcl.ERROR

proc pix_image_blur(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let radius: cdouble = -1

    if objc notin (3..4):
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <img|ctx> radius {r g b a}:optional"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let str = $arg1
    
    var img: Image

    if str[^3..^1] == "ctx":
      let ctx = ctxTable[$str]
      img = ctx.image
    else:
      img = imgTable[$str]

    # Radius
    if Tcl.GetDoubleFromObj(interp, objv[2], radius.addr) != Tcl.OK:
      return Tcl.ERROR

    if objc == 4:
      # Color RGBA check
      let arg3 = Tcl.GetStringFromObj(objv[3], nil)
      let color = parseHtmlColor($arg3).rgba

      img.blur(radius, color)
    else:
      img.blur(radius)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    
proc pix_image_shadow(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    let x, y, spread, blur: cdouble = 0
    let count, dictcount: cint = 0
    let elements, dict : Tcl.PPObj = nil
    var colorShadow: ColorRGBA

    if objc != 3:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " <img> {offset? ?value spread? ?value blur? ?value color? ?value}"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR
      
    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    # Dict
    if Tcl.ListObjGetElements(interp, objv[2], count.addr, elements.addr) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      Tcl.SetResult(interp, "wrong # args: argument should key value key1 value1 ...", nil)
      return Tcl.ERROR

    var i = 0
    while i < count:
      let mkey = Tcl.GetStringFromObj(elements[i], nil)
      case $mkey:
        of "offset":
          if Tcl.ListObjGetElements(interp, elements[i+1], dictcount.addr, dict.addr) != Tcl.OK:
            return Tcl.ERROR
          if dictcount != 2:
            Tcl.SetResult(interp, "wrong # args: argument should be 'x' 'y'", nil)
            return Tcl.ERROR
            
          if Tcl.GetDoubleFromObj(interp, dict[0], x.addr) != Tcl.OK:
            return Tcl.ERROR
    
          if Tcl.GetDoubleFromObj(interp, dict[1], y.addr) != Tcl.OK:
            return Tcl.ERROR

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
    
    let im = cast[pointer](shadow)
    let hex = "0x" & cast[uint64](im).toHex
    let js = (hex & "^img").toLowerAscii

    imgTable[js] = shadow

    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(js), -1))

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    

proc pix_img_fillText(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =

  try:
    var matrix3: vmath.Mat3
  
    if objc != 4:
      let cmd = Tcl.GetStringFromObj(objv[0], nil)
      let mess = "wrong # args: " & $cmd & " '<img> <arrangement> matrix3'"
      Tcl.SetResult(interp, mess.cstring , nil)
      return Tcl.ERROR

    # Image
    let arg1 = Tcl.GetStringFromObj(objv[1], nil)
    let img = imgTable[$arg1]

    #Arrangement
    let arg2 = Tcl.GetStringFromObj(objv[2], nil)
    let arrangement = arrTable[$arg2]
    
    if matrix3(interp, objv[3], matrix3) != Tcl.OK:
      return Tcl.ERROR
    
    img.fillText(arrangement, matrix3)

    return Tcl.OK
  except Exception as e:
    echo "pix(error): ", e.msg
    return Tcl.ERROR
    