# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_font_readFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a font from a file.
  # 
  # filePath - file font
  #
  # Returns a 'new' font object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "filePath")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    
    # Font
    let font = readFont($arg1)
    
    let myPtr = cast[pointer](font)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^font").toLowerAscii

    fontTable[p] = font

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_size(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Size (Same as pix::font::configure procedure).
  # 
  # font - object
  # size  - double value
  #
  # Returns nothing.
  try:
    var fsize: cdouble = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<font> size")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]
    
    if Tcl.GetDoubleFromObj(interp, objv[2], fsize) != Tcl.OK:
      return Tcl.ERROR

    font.size = fsize

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_color(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font color (Same as pix::font::configure procedure).
  # 
  # font - object
  # color - string or list color simple
  #
  # Returns nothing.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<font> color")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]
    
    # Color simple check
    var cseqColorP: Color
    if isColorSimple(objv[1], cseqColorP):
      font.paint.color = cseqColorP
    else:
      let arg2 = Tcl.GetString(objv[2])
      let color = parseHtmlColor($arg2)
      font.paint.color = color
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
  
proc pix_font_newFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets new Font.
  # 
  # typeface - object
  #
  # Returns a 'new' font object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1 = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let font = newFont(tface)
    
    let myPtr = cast[pointer](font)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^font").toLowerAscii

    fontTable[p] = font

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_newSpan(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets new Span.
  # 
  # font - object
  # text - string
  #
  # Returns a 'new' span object.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<font> text")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]

    # Text
    let arg2 = Tcl.GetString(objv[2])
    let text = $arg2

    let span = newSpan(text, font)
    
    let myPtr = cast[pointer](span)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^span").toLowerAscii

    spanTable[p] = span

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Paint.
  # 
  # font  - object
  # paint - object (optional) 
  #
  # Returns a 'new' paint object.
  try:

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<font> <paint>:optional")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]

    if objc == 3:
      # Paint
      let arg2 = Tcl.GetString(objv[2])
      let paint = paintTable[$arg2]
      font.paint = paint
    else:
      let paint = font.paint

      let myPtr = cast[pointer](paint)
      let hex = "0x" & cast[uint64](myPtr).toHex()
      let p = (hex & "^paint").toLowerAscii

      paintTable[p] = paint

      Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_readTypeface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a typeface from a file.
  # 
  # filePath - file font
  #
  # Returns a 'new' typeface object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "filePath")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    
    # Typeface
    let typeface = readTypeface($arg1)
    
    let myPtr = cast[pointer](typeface)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^TFace").toLowerAscii

    tFaceTable[p] = typeface

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_readTypefaces(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a OpenType Collection (.ttc).
  # 
  # filePath - file font
  #
  # Returns Tcl list <typeface> object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "filePath")
      return Tcl.ERROR
      
    let arg1 = Tcl.GetString(objv[1])
    let newListobj = Tcl.NewListObj(0, nil)
    
    # Typeface
    let typefaces = readTypefaces($arg1)

    for _, typeface in typefaces:
      let myPtr = cast[pointer](typeface)
      let hex = "0x" & cast[uint64](myPtr).toHex()
      let p = (hex & "^TFace").toLowerAscii

      tFaceTable[p] = typeface
      discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewStringObj(p.cstring, -1))

    Tcl.SetObjResult(interp, newListobj)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_ascent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font ascender value in font units.
  # 
  # typeface - object
  #
  # Returns Tcl double value.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let value = tface.ascent()
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_computeBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Bounds Arrangement object.
  # 
  # arrangement - object
  # transform   - matrix list (optional:mat3)
  #
  # Returns Tcl dict value {x y w h}.
  try:
    var matrix3: vmath.Mat3
    var rect: Rect

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> transform:optional")
      return Tcl.ERROR

    # Arrangement
    let arg1  = Tcl.GetString(objv[1])
    let arr = arrTable[$arg1]
    let dictObj = Tcl.NewDictObj()

    if objc == 3:
      # Matrix 3x3 check
      if matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
        return Tcl.ERROR
      rect = arr.computeBounds(matrix3)
    else:
      rect = arr.computeBounds()

    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))

    Tcl.SetObjResult(interp, dictObj)
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)


proc pix_font_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy font.
  # 
  # font - object
  #
  # Returns a 'new' font object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<font>")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]
    
    let newfont = font.copy()
    
    let myPtr = cast[pointer](newfont)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^font").toLowerAscii

    fontTable[p] = newfont

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_defaultLineHeight(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in pixels for the current font size. 
  # 
  # font - object
  #
  # Returns Tcl double value.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<font>")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]
    
    let value = font.defaultLineHeight()
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
    
proc pix_font_descent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font descender value in font units.
  # 
  # typeface - object
  #
  # Returns Tcl double value.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let value = tface.descent()
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_fallbackTypeface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Looks through fallback typefaces to find one that has the glyph.
  # 
  # typeface - object
  # char     - string 'char'
  #
  # Returns a 'new' Tcl typeFace or the 
  # arg typeFace if typeface has glyph.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    # Rune
    let arg2 = Tcl.GetString(objv[2])
    var char1: string = $arg2

    let c = char1.runeAt(0)

    if tface.hasGlyph(c):
      Tcl.SetObjResult(interp, Tcl.NewStringObj(arg1, -1))
    else:
      # New Typeface
      let newtface = tface.fallbackTypeface(c)

      if newtface == nil:
        return ERROR_MSG(interp, "pix(error): '<TypeFace>' the return object is 'null'.")
      
      let myPtr = cast[pointer](newtface)
      let hex = "0x" & cast[uint64](myPtr).toHex()
      let p = (hex & "^TFace").toLowerAscii

      tFaceTable[p] = newtface

      Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_getAdvance(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The advance for the rune in pixels.
  # 
  # typeface - object
  # char     - string 'char'
  #
  # Returns Tcl double value.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    # Rune
    let arg2 = Tcl.GetString(objv[2])
    var char1: string = $arg2

    let c = char1.runeAt(0)

    let value = tface.getAdvance(c)
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_getGlyphPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The glyph path for the rune.
  # 
  # typeface - object
  # char     - string 'char'
  #
  # Returns a 'new' path object.
  try:

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    # Rune
    let arg2 = Tcl.GetString(objv[2])
    var char1: string = $arg2

    let c = char1.runeAt(0)

    let path = tface.getGlyphPath(c)

    if path == nil:
      return ERROR_MSG(interp, "pix(error): '<path>' the return object is 'null'.")

    let myPtr = cast[pointer](path)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^path").toLowerAscii

    pathTable[p] = path

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_getKerningAdjustment(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The kerning adjustment for the rune pair, in pixels.
  # 
  # typeface - object
  # char1    - string 'char'
  # char2    - string 'char'
  #
  # Returns Tcl double value.
  try:

    if objc != 4:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char char")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    # Rune
    let arg2 = Tcl.GetString(objv[2])
    var char1: string = $arg2
    let c1 = char1.runeAt(0)

    let arg3 = Tcl.GetString(objv[3])
    var char2: string = $arg3
    let c2 = char2.runeAt(0)

    let value = tface.getKerningAdjustment(c1, c2)
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_hasGlyph(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns if there is a glyph for this rune.
  # 
  # typeface - object
  # char1    - string 'char'
  #
  # Returns true, otherwise false.
  try:
    var val: int = 0

    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    # Rune
    let arg2 = Tcl.GetString(objv[2])
    var char1: string = $arg2
    let c = char1.runeAt(0)

    if tface.hasGlyph(c): val = 1
    
    Tcl.SetObjResult(interp, Tcl.NewIntObj(val))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_layoutBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Computes the width and height of the arrangement in pixels.
  # Computes the width and height of the text in pixels.
  # Computes the width and height of the spans in pixels.
  # 
  # object - arrangement, font or span object 
  # text   - string (if font object)
  #
  # Returns Tcl dict value {x y}.
  try:
    var count: Tcl.Size
    var elements: Tcl.PPObj
    var bounds: vmath.Vec2

    if objc notin (2..3):
      Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> or <font> + 'text' or <span>")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    let newListobj = Tcl.NewListObj(0, nil)

    if arrTable.hasKey($arg1):
      # Arrangement
      let arr = arrTable[$arg1]
      bounds = arr.layoutBounds()
    elif fontTable.hasKey($arg1):
      # Font + text
      let font = fontTable[$arg1]
      if objc != 3:
        return ERROR_MSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")
      
      let arg2 = Tcl.GetString(objv[2])
      let text = $arg2

      bounds = font.layoutBounds(text)
    else:
      # Span
      if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
        return Tcl.ERROR
      if count == 0:
        return ERROR_MSG(interp, "pix(error): list <span> object is empty.")
      var spans = newSeq[Span]()
      var strSpan: cstring
      for i in 0..count-1:
        strSpan = Tcl.GetString(elements[i])
        spans.add(spanTable[$strSpan])

      bounds = spans.layoutBounds()

    discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.x))
    discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.y))

    Tcl.SetObjResult(interp, newListobj)
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_lineGap(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font line gap value in font units.
  # 
  # typeface - object 
  #
  # Returns Tcl double value.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let value = tface.lineGap()
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_lineHeight(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in font units.
  # 
  # typeface - object 
  #
  # Returns Tcl double value.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let value = tface.lineHeight()
    
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_name(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns the name of the font.
  # 
  # typeface - object 
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
      return Tcl.ERROR

    # TypeFace
    let arg1  = Tcl.GetString(objv[1])
    let tface = tFaceTable[$arg1]

    let name = tface.name() 
    
    Tcl.SetObjResult(interp, Tcl.NewStringObj(cstring(name), -1))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_parseOtf(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Otf string.
  # 
  # buffer - string
  #
  # Returns a 'new' typeFace object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "buffer")
      return Tcl.ERROR

    # Buffer
    let arg1 = Tcl.GetString(objv[1])
    let buf = $arg1
    
    let typeface = parseOtf(buf)

    let myPtr = cast[pointer](typeface)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^TFace").toLowerAscii

    tFaceTable[p] = typeface

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_parseSvgFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Svg Font string.
  # 
  # buffer - string
  #
  # Returns a 'new' typeFace object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "buffer")
      return Tcl.ERROR

    # Buffer
    let arg1 = Tcl.GetString(objv[1])
    let buf = $arg1
    
    let typeface = parseSvgFont(buf)

    let myPtr = cast[pointer](typeface)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^TFace").toLowerAscii

    tFaceTable[p] = typeface

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_parseTtf(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Ttf string.
  # 
  # buffer - string
  #
  # Returns a 'new' typeFace object.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "buffer")
      return Tcl.ERROR

    # Buffer
    let arg1 = Tcl.GetString(objv[1])
    let buf = $arg1
    
    let typeface = parseTtf(buf)

    let myPtr = cast[pointer](typeface)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^TFace").toLowerAscii

    tFaceTable[p] = typeface

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_scale(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The scale factor to transform font units into pixels.
  # 
  # object - font or typeFace object
  #
  # Returns Tcl double value.
  try:
    var value: float32 = 0

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<font>|<TypeFace>")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    if fontTable.hasKey($arg1):
      # Font
      let font = fontTable[$arg1]
      value = font.scale()
    else:
      # TypeFace
      let typeface = tFaceTable[$arg1]
      value = typeface.scale()

    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(value))
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_typeset(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Lays out the character glyphs and returns the arrangement.
  # 
  # object - font or span object
  # args   - dict options described below: (optional)<br>
  #   bounds  - list coordinates<br>
  #   hAlign  - Enum value<br>
  #   vAlign  - Enum value<br>
  #   wrap    - boolean value<br>
  # 
  #
  # Returns a 'new' arrangement object.
  try:
    var x, y: cdouble = 1.0
    var count, veccount: Tcl.Size
    var wrapB: int = 0
    var elements, vecelements: Tcl.PPObj
    var mywrap, hasFont: bool = true
    var vecBounds = vec2(0, 0)
    var myEnumhAlign, myEnumvAlign: string = "null"
    var arr: Arrangement
    var font: Font
    var spans = newSeq[Span]()
    var text: string
    var jj = 3
  
    if objc != 2 and objc != 3 and objc != 4:
      let msg = """<font> 'text' {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value} or
       <span> {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value}"""
      Tcl.WrongNumArgs(interp, 1, objv, msg.cstring)
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    
    if fontTable.hasKey($arg1):
      # Font
      font = fontTable[$arg1]
      if objc < 3:
        return ERROR_MSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")
      let arg2 = Tcl.GetString(objv[2])
      text = $arg2
    else:
      # Spans
      if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
        return Tcl.ERROR

      if count == 0:
        return ERROR_MSG(interp, "wrong # args: list <span> is empty.")

      hasFont = false
      for j in 0..count-1:
        let myspan = Tcl.GetString(elements[j])
        spans.add(spanTable[$myspan])

    if (objc == 4 and hasFont) or (objc == 3 and hasFont == false):
      if hasFont == false: jj = 2
      # Dict
      if Tcl.ListObjGetElements(interp, objv[jj], count, elements) != Tcl.OK:
        return Tcl.ERROR

      if count mod 2 == 1:
        return ERROR_MSG(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

      var i = 0
      while i < count:
        let mkey = Tcl.GetString(elements[i])
        case $mkey:
          of "wrap":
            if Tcl.GetBooleanFromObj(interp, elements[i+1], wrapB) != Tcl.OK:
              return Tcl.ERROR
            mywrap = wrapB.bool
          of "hAlign":
            let arg = Tcl.GetString(elements[i+1])
            myEnumhAlign = $arg
          of "vAlign":
            let arg = Tcl.GetString(elements[i+1])
            myEnumvAlign = $arg
          of "bounds":
            if Tcl.ListObjGetElements(interp, elements[i+1], veccount, vecelements) != Tcl.OK:
              return Tcl.ERROR
            if veccount != 2:
              return ERROR_MSG(interp, "wrong # args: bounds argument should be 'x' 'y'")

            if Tcl.GetDoubleFromObj(interp, vecelements[0], x) != Tcl.OK: return Tcl.ERROR
            if Tcl.GetDoubleFromObj(interp, vecelements[1], y) != Tcl.OK: return Tcl.ERROR

            vecBounds = vec2(x, y)
          else:
            return ERROR_MSG(interp, "wrong # args: Key '" & $mkey & "' not supported.")
        inc(i, 2)
        
        let myEnumLH = parseEnum[HorizontalAlignment]($myEnumhAlign, LeftAlign)
        let myEnumLV = parseEnum[VerticalAlignment]($myEnumvAlign, TopAlign)
        
        if hasFont:
          arr = typeset(font, text, bounds = vecBounds, hAlign = myEnumLH, vAlign = myEnumLV, wrap = mywrap)
        else:
          arr = typeset(spans, bounds = vecBounds, hAlign = myEnumLH, vAlign = myEnumLV, wrap = mywrap)
    else:
      if hasFont:
        arr = typeset(font, text)
      else:
        arr = typeset(spans)

    let myPtr = cast[pointer](arr)
    let hex = "0x" & cast[uint64](myPtr).toHex()
    let p = (hex & "^arr").toLowerAscii

    arrTable[p] = arr
    
    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_configure(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Configure <font> parameters.
  # 
  # font - object
  # args - dict options described below: <br>
  #   noKerningAdjustments  - boolean value <br>
  #   underline             - boolean value <br>
  #   strikethrough         - boolean value <br>
  #   size                  - double value <br>
  #   lineHeight            - double value <br>
  #   paint                 - Html color <br>
  #   color                 - Simple color <br>
  # 
  # Returns nothing.
  try:
    var fsize, flineHeight: cdouble = 0
    var count, countP: Tcl.Size
    var myBool: int = 0
    var elements, elementsP: Tcl.PPObj
  
    if objc != 3:
      Tcl.WrongNumArgs(interp, 1, objv, "<font> {?size ?value ?noKerningAdjustments ?value ?lineHeight ?value}")
      return Tcl.ERROR

    # Font
    let arg1 = Tcl.GetString(objv[1])
    let font = fontTable[$arg1]

    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count mod 2 == 1:
      return ERROR_MSG(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

    var i = 0
    while i < count:
      let mkey = Tcl.GetString(elements[i])
      case $mkey:
        of "noKerningAdjustments":
          if Tcl.GetBooleanFromObj(interp, elements[i+1], myBool) != Tcl.OK:
            return Tcl.ERROR
          font.noKerningAdjustments = myBool.bool
        of "underline":
          if Tcl.GetBooleanFromObj(interp, elements[i+1], myBool) != Tcl.OK:
            return Tcl.ERROR
          font.underline = myBool.bool
        of "strikethrough":
          if Tcl.GetBooleanFromObj(interp, elements[i+1], myBool) != Tcl.OK:
            return Tcl.ERROR
          font.strikethrough = myBool.bool
        of "size":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], fsize) != Tcl.OK:
            return Tcl.ERROR
          font.size = fsize
        of "lineHeight":
          if Tcl.GetDoubleFromObj(interp, elements[i+1], flineHeight) != Tcl.OK:
            return Tcl.ERROR
          font.lineHeight = flineHeight
        of "paint":
          let arg2 = Tcl.GetString(elements[i+1])
          let color = parseHtmlColor($arg2)
          font.paint = color
        of "color":
          var cseqColorP: Color
          if isColorSimple(elements[i+1], cseqColorP) == false:
            return ERROR_MSG(interp, "pix(error): color should be a 'simple color' for 'color' field.")
          font.paint.color = cseqColorP
        of "paints":
          if Tcl.ListObjGetElements(interp, elements[i+1], countP, elementsP) != Tcl.OK:
            return Tcl.ERROR
          if countP != 0:
            var paints = newSeq[Paint]()
            for ps in 0..countP-1:
              let arg2 = Tcl.GetString(elementsP[ps])
              let paint = paintTable[$arg2]
              paints.add(paint)

            font.paints = paints
        else:
          return ERROR_MSG(interp, "wrong # args: Key '" & $mkey & "' not supported.")
      inc(i, 2)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_selectionRects(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets coordinates rectangle for 'arrangement' object.
  # 
  # arrangement - object
  #
  # Returns Tcl dict value (x, y, w, h).
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement>")
      return Tcl.ERROR

    let arg1 = Tcl.GetString(objv[1])
    let arr = arrTable[$arg1]
    let dictGlobobj = Tcl.NewDictObj()

    for index, rect in arr.selectionRects:
      let dictObj = Tcl.NewDictObj()
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))
      discard Tcl.DictObjPut(nil, dictGlobobj, Tcl.NewIntObj(index), dictObj)

    Tcl.SetObjResult(interp, dictGlobobj)
    
    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)

proc pix_font_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current font or all fonts if special word `all` is specified.
  # 
  # value - font object or string 
  #
  # Returns nothing.
  try:

    if objc != 2:
      Tcl.WrongNumArgs(interp, 1, objv, "<font>|string")
      return Tcl.ERROR
    
    # Font
    let arg1 = Tcl.GetString(objv[1])
    if $arg1 == "all":
      fontTable.clear()
    else:
      fontTable.del($arg1)

    return Tcl.OK
  except Exception as e:
    return ERROR_MSG(interp, "pix(error): " & e.msg)
