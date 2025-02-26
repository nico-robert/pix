# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_font_readFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Try to read the font from the file located at the given path.
  #
  # filePath - file font
  #
  # Pixie will take care of the rest (loading the font, verifying it, etc.).
  #
  # If there is an error (like the file not existing), an exception will be
  # raised which we will catch and return the error message.
  #
  # Returns a 'new' font object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  # Font
  let font = try:
    readFont(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(font)
  pixTables.addFont(p, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_size(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Size (Same as pix::font::configure procedure).
  #
  # font  - object
  # size  - double value
  #
  # Returns nothing.
  var fsize: cdouble

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> size")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  if Tcl.GetDoubleFromObj(interp, objv[2], fsize) != Tcl.OK:
    return Tcl.ERROR

  try:
    font.size = fsize
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_font_color(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font color (Same as pix::font::configure procedure).
  #
  # font  - object
  # color - string color
  #
  # Returns nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> color")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  try:
    # Color gets.
    font.paint.color = pixUtils.getColor(objv[2])
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_font_newFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a new pixie.Font from the given TypeFace object.
  # The `pixie.Font` object is initialized with the given TypeFace object.
  #
  # typeface - object
  #
  # The size of the font is set to 0 (which is the default value).
  # The paint object is initialized with a default Color (black).
  # The text buffer is initialized with a default string ("").
  # The flags are initialized with a default value of 0.
  #
  # Returns a 'new' font object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Create a new pixie.Font from the given TypeFace object.
  let font = try:
    newFont(tface)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(font)
  pixTables.addFont(p, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_newSpan(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets new Span.
  #
  # font - object
  # text - string
  #
  # Returns a 'new' span object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> text")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)
  # Text
  let text = $Tcl.GetString(objv[2])

  # Create a new Span object.
  let span = try:
    newSpan(text, font)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(span)
  pixTables.addSpan(p, span)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_paint(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Paint if paint optional argument is set, otherwise gets the font paint.
  #
  # font  - object
  # paint - object (optional)
  #
  # Returns a 'new' paint object if no paint optional argument is set, otherwise set the font paint.
  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<font> ?<paint>:optional")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  if objc == 3:
    # Paint
    let arg2 = $Tcl.GetString(objv[2])

    if not pixTables.hasPaint(arg2):
      return pixUtils.errorMSG(interp, "pix(error): no key <ctx> object found '" & arg2 & "'")

    try:
      font.paint = pixTables.getPaint(arg2)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    # No Paint object gets the font paint.
    let paint = try:
      font.paint
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    
    let p = toHexPtr(paint)
    pixTables.addPaint(p, paint)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_readTypeface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a typeface from a file.
  #
  # filePath - file font
  #
  # Returns a 'new' typeface object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  # Typeface
  let typeface = try:
    readTypeface($Tcl.GetString(objv[1]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  pixTables.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_readTypefaces(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a OpenType Collection (.ttc).
  #
  # filePath - file font
  #
  # Returns Tcl list <typeface> object.
  let newListobj = Tcl.NewListObj(0, nil)

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  try:
    # Typeface
    for _, typeface in readTypefaces($Tcl.GetString(objv[1])):
      let p = toHexPtr(typeface)
      pixTables.addTface(p, typeface)
      discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewStringObj(p.cstring, -1))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_ascent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font ascender value in font units.
  #
  # typeface - object
  #
  # The ascender is the distance from the baseline to the highest point of any glyph in the font.
  # This value is used to position text in the y-direction.
  # The value is in the font's coordinate system.
  # The value is in pixels but can be a floating point value.
  # The value is positive.
  #
  # Returns Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Gets the font ascender value in font units.
  let ascentValue = try:
    tface.ascent()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(ascentValue))

  return Tcl.OK

proc pix_font_computeBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Bounds Arrangement object.
  #
  # arrangement - object
  # transform   - matrix list (optional:mat3)
  #
  # Returns Tcl dict value {x y w h}.
  var
    matrix3: vmath.Mat3
    rect: Rect

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> ?transform:optional")
    return Tcl.ERROR

  # Arrangement
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasArr(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <Arrangement> object found '" & arg1 & "'")

  let arr = pixTables.getArr(arg1)

  if objc == 3:
    # Matrix 3x3 check
    if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR
    try:
      rect = arr.computeBounds(matrix3)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      rect = arr.computeBounds()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_font_copy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy font.
  #
  # font - object
  #
  # Returns a 'new' font object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  let newfont = try:
    font.copy()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(newfont)
  pixTables.addFont(p, newfont)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_defaultLineHeight(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in pixels for the current font size.
  #
  # font - object
  #
  # This proc calculates and returns the default line height
  # of the font in pixels, based on its current size and other
  # internal properties.
  #
  # Returns Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  let defaultLineHeight = try:
    font.defaultLineHeight()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(defaultLineHeight))

  return Tcl.OK

proc pix_font_descent(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font descender value in font units.
  #
  # typeface - object
  #
  # The descent is the distance from the baseline to the lowest point of any glyph in the font.
  # This value is used to position text in the y-direction.
  # The value is in the font's coordinate system.
  # The value is in pixels but can be a floating point value.
  # The value is negative.
  #
  # Returns Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)
  
  # Gets the font descender value in font units.
  let descentValue = try:
    tface.descent
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(descentValue))

  return Tcl.OK

proc pix_font_fallbackTypeface(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Looks through fallback typefaces to find one that has the glyph.
  #
  # typeface - object
  # char     - string 'char'
  #
  # Returns a 'new' Tcl typeFace or the
  # arg typeFace if typeface has glyph.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Rune
  let 
    char1 = $Tcl.GetString(objv[2])
    c = char1.runeAt(0)

  if tface.hasGlyph(c):
    Tcl.SetObjResult(interp, Tcl.NewStringObj(arg1.cstring, -1))
  else:
    # New Typeface
    let newtface = try:
      tface.fallbackTypeface(c)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg) 

    if newtface == nil:
      return pixUtils.errorMSG(interp, "pix(error): the '<TypeFace>' return object is 'null'.")

    let p = toHexPtr(newtface)
    pixTables.addTface(p, newtface)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_getAdvance(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Try to get the advance width for the given rune in pixels.
  # If the rune is not supported by the typeface, this will raise an
  # exception.
  #
  # typeface - object
  # char     - 'char'
  #
  # Returns Tcl double value.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)
  # Rune
  let 
    char1 = $Tcl.GetString(objv[2])
    c = char1.runeAt(0)

  let advance = try:
    tface.getAdvance(c)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(advance))

  return Tcl.OK

proc pix_font_getGlyphPath(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The glyph path for the rune.
  #
  # typeface - object
  # char     - 'char'
  #
  # Returns a 'new' path object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Rune
  let
    char1 = $Tcl.GetString(objv[2])
    c = char1.runeAt(0)

  let path = try:
    tface.getGlyphPath(c)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  if path == nil:
    return pixUtils.errorMSG(interp, "pix(error): the '<path>' return object is 'null'.")

  let p = toHexPtr(path)
  pixTables.addPath(p, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_getKerningAdjustment(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Retrieve the kerning adjustment for the pair of characters (c1, c2) from the typeface.
  #
  # typeface - object
  # char1    - 'char'
  # char2    - 'char'
  #
  # Kerning is the process of adjusting the space between characters in a proportional font.
  # The kerning adjustment is measured in pixels and is specific to the pair of characters.
  # This allows for more visually pleasing and readable text by reducing or increasing space
  # between specific pairs of characters, depending on the typeface design.
  #
  # Returns Tcl double value.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char char")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Rune
  let 
    char1 = $Tcl.GetString(objv[2])
    c1 = char1.runeAt(0)
    char2 = $Tcl.GetString(objv[3])
    c2 = char2.runeAt(0)

  let adjustment = try:
    tface.getKerningAdjustment(c1, c2)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(adjustment))

  return Tcl.OK

proc pix_font_hasGlyph(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns if there is a glyph for this rune.
  #
  # typeface - object
  # char1    - 'char'
  #
  # Returns true, otherwise false.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  # Rune
  let
    char1 = $Tcl.GetString(objv[2])
    c = char1.runeAt(0)

  let hasglyph = try:
    if tface.hasGlyph(c): 1 else: 0
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewIntObj(hasglyph))

  return Tcl.OK

proc pix_font_layoutBounds(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Computes the width and height of the arrangement in pixels.
  # Computes the width and height of the text in pixels.
  # Computes the width and height of the spans in pixels.
  #
  # object - arrangement, font or span object
  # text   - string (if font object)
  #
  # Returns Tcl dict value {x y}.
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    bounds: vmath.Vec2

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> or <font> + 'text' or <span>")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  if pixTables.hasArr(arg1):
    # Arrangement
    let arr = pixTables.getArr(arg1)
    try:
      bounds = arr.layoutBounds()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    
  elif pixTables.hasFont(arg1):
    # Font + text
    let font = pixTables.getFont(arg1)
    if objc != 3:
      return pixUtils.errorMSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")

    try:
      bounds = font.layoutBounds($Tcl.GetString(objv[2]))
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    # Span
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, "pix(error): list <span> object is empty.")

    var spans = newSeq[Span]()
    for i in 0..count-1:
      spans.add(pixTables.getSpan($Tcl.GetString(elements[i])))

    try:
      bounds = spans.layoutBounds()
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let newListobj = Tcl.NewListObj(0, nil)

  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.x))
  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.y))

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_lineGap(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets the font line gap value in font units.
  #
  # typeface - object
  #
  # The line gap is the distance in font units between the
  # baseline of one line of text and the baseline of the next.
  # The line gap is used to determine the spacing between
  # lines of text.
  #
  # Returns the line gap value in font units.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  let lineGap = try:
    tface.lineGap()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(lineGap))

  return Tcl.OK

proc pix_font_lineHeight(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in font units.
  #
  # typeface - object
  #
  # The line height is the height of a line of text in the font,
  # which is typically slightly larger than the ascent of the
  # font (the height above the baseline) plus the descent of the
  # font (the height below the baseline).
  #
  # The line height is typically used to determine the vertical
  # distance between the baselines of two lines of text.
  #
  # Returns Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  let lineHeight = try:
    tface.lineHeight()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(lineHeight))

  return Tcl.OK

proc pix_font_name(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Returns the name of the font.
  #
  # typeface - object
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasTFace(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <TypeFace> object found '" & arg1 & "'")

  let tface = pixTables.getTFace(arg1)

  let name = try:
    tface.name()
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(name.cstring, -1))

  return Tcl.OK

proc pix_font_parseOtf(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Otf string.
  #
  # buffer - string
  #
  # The goal is to take a string buffer containing an Otf (Open
  # Type Font) and parse it into a TypeFace object.
  #
  # Returns a 'new' typeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  # Buffer
  let typeface = try:
    parseOtf($Tcl.GetString(objv[1]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  pixTables.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_parseSvgFont(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Svg Font string.
  #
  # buffer - string
  #
  # The `parseSvgFont` function is used to interpret the string as an SVG font
  # and convert it into a `TypeFace` object.
  #
  # Returns a 'new' typeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR
  
  # Buffer
  let typeface = try:
    parseSvgFont($Tcl.GetString(objv[1]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  pixTables.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_parseTtf(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Ttf string.
  #
  # buffer - string
  #
  # The `parseTtf` function is used to interpret the string as a Ttf
  # (TrueType Font) and convert it into a `TypeFace` object.
  #
  # Returns a 'new' typeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  # Buffer
  let typeface = try:
    parseTtf($Tcl.GetString(objv[1]))
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  
  let p = toHexPtr(typeface)
  pixTables.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_scale(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The scale factor to transform font units into pixels.
  #
  # object - font or typeFace object
  #
  # Returns Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|<TypeFace>")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  let scale = try:
    if pixTables.hasFont(arg1):
      # Font
      let font = pixTables.getFont(arg1)
      font.scale()
    elif pixTables.hasTFace(arg1):
      # TypeFace
      let typeface = pixTables.getTFace(arg1)
      typeface.scale()
    else:
      return pixUtils.errorMSG(interp, "pix(error): no <font> or <TypeFace> object found.")
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(scale))

  return Tcl.OK

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
  var
    count: Tcl.Size
    elements: Tcl.PPObj
    arr: pixie.Arrangement
    font: pixie.Font
    spans = newSeq[Span]()
    text: string
    hasFont: bool = true
    jj = 3

  if objc notin (2..4):
    let errMsg = "<font> 'text' {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value} or " &
    "<span> {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  if pixTables.hasFont(arg1):
    # Font
    font = pixTables.getFont(arg1)
    if objc < 3:
      return pixUtils.errorMSG(interp, "pix(error): If <font> is present, a 'text' must be associated.")
    text = $Tcl.GetString(objv[2])
  else:
    # Spans
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, "wrong # args: list <span> is empty.")

    hasFont = false
    for j in 0..count-1:
      spans.add(pixTables.getSpan($Tcl.GetString(elements[j])))

  if (objc == 4 and hasFont) or (objc == 3 and hasFont == false):
    if hasFont == false: jj = 2
    try:
      var opts = pixParses.RenderOptions()
      pixParses.typeSetOptions(interp, objv[jj], opts)

      arr = if hasFont: 
        typeset(font, text,
          bounds = opts.bounds,
          hAlign = opts.hAlign,
          vAlign = opts.vAlign,
          wrap = opts.wrap
        ) 
      else: 
        typeset(spans, 
          bounds = opts.bounds,
          hAlign = opts.hAlign,
          vAlign = opts.vAlign,
          wrap = opts.wrap
        )
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    try:
      arr = if hasFont: typeset(font, text) else: typeset(spans)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(arr)
  pixTables.addArr(p, arr)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

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
  var
    fsize, flineHeight: cdouble
    count, countP: Tcl.Size
    myBool: int = 0
    elements, elementsP: Tcl.PPObj

  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> {?size ?value ?noKerningAdjustments ?value ?lineHeight ?value}")
    return Tcl.ERROR

  # Font
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasFont(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <font> object found '" & arg1 & "'")

  let font = pixTables.getFont(arg1)

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp, "wrong # args: 'dict options' should be :key value ?key1 ?value1 ...")

  for i in countup(0, count - 1, 2):
    let 
      mkey = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case mkey:
      of "noKerningAdjustments":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK: return Tcl.ERROR
        try:
          font.noKerningAdjustments = myBool.bool
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "underline":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK: return Tcl.ERROR
        try:
          font.underline = myBool.bool
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "strikethrough":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK: return Tcl.ERROR
        try:
          font.strikethrough = myBool.bool
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "size":
        if Tcl.GetDoubleFromObj(interp, value, fsize) != Tcl.OK: return Tcl.ERROR
        try:
          font.size = fsize
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "lineHeight":
        if Tcl.GetDoubleFromObj(interp, value, flineHeight) != Tcl.OK: return Tcl.ERROR
        try:
          font.lineHeight = flineHeight
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "paint":
        try:
          font.paint = SomePaint(pixUtils.getColor(value))
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "color":
        try:
          font.paint.color = pixUtils.getColor(value)
        except Exception as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "paints":
        if Tcl.ListObjGetElements(interp, value, countP, elementsP) != Tcl.OK: return Tcl.ERROR
        if countP != 0:
          var paints = newSeq[pixie.Paint]()
          for ps in 0..countP-1:
            try:
              let paint = pixTables.getPaint($Tcl.GetString(elementsP[ps]))
              paints.add(paint)
            except Exception as e:
              return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

          font.paints = paints
      else:
        return pixUtils.errorMSG(interp, "wrong # args: Key '" & mkey & "' not supported.")

  return Tcl.OK

proc pix_font_selectionRects(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets coordinates rectangle for 'arrangement' object.
  #
  # arrangement - object
  #
  # Returns Tcl dict value (x, y, w, h).
  let dictGlobobj = Tcl.NewDictObj()

  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement>")
    return Tcl.ERROR

  # Arrangement
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasArr(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <Arrangement> object found '" & arg1 & "'")

  let arr = pixTables.getArr(arg1)

  try:
    for index, rect in arr.selectionRects:
      let dictObj = Tcl.NewDictObj()
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
      discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))
      discard Tcl.DictObjPut(nil, dictGlobobj, Tcl.NewIntObj(index), dictObj)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, dictGlobobj)

  return Tcl.OK

proc pix_font_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current font or all fonts if special word `all` is specified.
  #
  # value - font object or string
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:
    # Font
    if arg1 == "all":
      fontTable.clear()
    else:
      fontTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK
