# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_font_readFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Try to read the font from the file located at the given path.
  #
  # filePath - file font
  #
  # Pixie will take care of the rest (loading the font, verifying it, etc.).<br>
  # If there is an error (like the file not existing), an exception will be
  # raised which we will catch and return the error message.
  #
  # Returns: A *new* [font] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Font
  let font = try:
    readFont($Tcl.GetString(objv[1]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(font)
  ptable.addFont(p, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_size(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Size (Same as pix::font::configure procedure).
  #
  # font  - [font::newFont]
  # size  - double value
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> size")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  # Font size.
  var fsize: cdouble

  if Tcl.GetDoubleFromObj(interp, objv[2], fsize) != Tcl.OK:
    return Tcl.ERROR

  font.size = fsize

  return Tcl.OK

proc pix_font_color(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font color (Same as pix::font::configure procedure).
  #
  # font  - [font::newFont]
  # color - string [color]
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> color")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  try:
    # Color gets.
    font.paint.color = pixUtils.getColor(objv[2])
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_font_newFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Create a new pixie.Font from the given *TypeFace* object.
  #
  # typeface - [font::readTypeface]
  #
  # The size of the font is set to 0 (which is the default value).
  # The [paint] object is initialized with a default *Color (black)*.
  # The text buffer is initialized with a default string ("").
  # The flags are initialized with a default value of 0.
  #
  # Returns: A *new* [font].
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Create a new pixie.Font from the given TypeFace object.
  let font = newFont(tface)

  let p = toHexPtr(font)
  ptable.addFont(p, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_newSpan(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets new Span.
  #
  # font - [font::newFont]
  # text - string
  #
  # Returns: A *new* span object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> text")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  # Create a new span object.
  let span = newSpan($Tcl.GetString(objv[2]), font)

  let p = toHexPtr(span)
  ptable.addSpan(p, span)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_paint(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Sets font Paint if paint optional argument is set, otherwise gets the font paint.
  #
  # font  - [font::newFont]
  # paint - [paint::new] (optional)
  #
  # Returns: 
  # A *new* [paint] if no paint optional argument is set, otherwise set the font paint.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> ?<paint>:optional")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  if objc == 3:
    # Paint
    let paint = ptable.loadPaint(interp, objv[2])
    if paint.isNil: return Tcl.ERROR

    font.paint = paint
  else:
    # No Paint object gets the font paint.
    let paint = font.paint
    let p = toHexPtr(paint)
    ptable.addPaint(p, paint)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_readTypeface(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a typeface from a file.
  #
  # filePath - file font
  #
  # Returns: A *new* Typeface object.
  #
  # See also : [font::parseTtf] [font::parseOtf] [font::parseSvgFont]
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Typeface
  let typeface = try:
    readTypeface($Tcl.GetString(objv[1]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  ptable.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_readTypefaces(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Loads a OpenType Collection (.ttc).
  #
  # filePath - file font
  #
  # Returns: A Tcl list with `Typeface` objects.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let newListobj = Tcl.NewListObj(0, nil)

  try:
    # Typeface
    for _, typeface in readTypefaces($Tcl.GetString(objv[1])):
      let p = toHexPtr(typeface)
      ptable.addTface(p, typeface)
      discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewStringObj(p.cstring, -1))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_ascent(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font ascender value in font units.
  #
  # typeface - [font::readTypeface]
  #
  # The ascender is the distance from the baseline to the highest point of any glyph in the font.
  # This value is used to position text in the y-direction.
  # The value is in the font's coordinate system.
  # The value is in pixels but can be a floating point value.
  # The value is positive.
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Gets the font ascender value in font units.
  let ascentValue = tface.ascent()

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(ascentValue))

  return Tcl.OK

proc pix_font_computeBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Computes the bounds of an `arrangement` object.
  #
  # arrangement - [font::typeset]
  # transform   - matrix list (optional:mat3)
  #
  # The bounds is the axis-aligned bounding box of all the glyphs in the
  # arrangement. The bounds is computed in the arrangement's coordinate system.
  # The bounds does not include the outline of the glyphs, only the filled
  # region.
  #
  # If the transform argument is provided, the bounds is computed after applying
  # the transformation matrix to the arrangement. The transformation matrix is
  # a 3x3 matrix as a list of 9 elements.
  #
  # Returns: A Tcl dict value where:<br>
  #    **x** : is the x offset of the top-left corner of the bounds.<br>
  #    **y** : is the y offset of the top-left corner of the bounds.<br>
  #    **w** : is the width of the bounds.<br>
  #    **h** : is the height of the bounds.<br>
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> ?transform:optional")
    return Tcl.ERROR

  var
    matrix3: vmath.Mat3
    rect: Rect

  # Arrangement
  let ptable = cast[PixTable](clientData)
  let arr = ptable.loadArr(interp, objv[1])
  if arr.isNil: return Tcl.ERROR

  if objc == 3:
    # Matrix 3x3 check
    if pixUtils.matrix3x3(interp, objv[2], matrix3) != Tcl.OK:
      return Tcl.ERROR
    try:
      rect = arr.computeBounds(matrix3)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
      rect = arr.computeBounds()
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let dictObj = Tcl.NewDictObj()

  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
  discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))

  Tcl.SetObjResult(interp, dictObj)

  return Tcl.OK

proc pix_font_copy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Copy font.
  #
  # font - [font::readFont]
  #
  # Returns: A *new* [font] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  let newfont = font.copy()
  let p = toHexPtr(newfont)
  ptable.addFont(p, newfont)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_defaultLineHeight(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in pixels for the current font size.
  #
  # font - [font::readFont]
  #
  # This proc calculates and returns the default line height
  # of the font in pixels, based on its current size and other
  # internal properties.
  # The line height is used to determine the vertical distance
  # between the baselines of two lines of text.
  #
  # For example, if the line height is 15.0, then the baseline
  # of the second line of text will be 15.0 pixels below the
  # baseline of the first line of text.
  #
  # Returns: The line height is in pixels.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  let defaultLineHeight = font.defaultLineHeight()

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(defaultLineHeight))

  return Tcl.OK

proc pix_font_descent(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The font descender value in font units.
  #
  # typeface - [font::readTypeface]
  #
  # The descent is the distance from the baseline to the lowest point of any glyph in the font.
  # This value is used to position text in the y-direction.
  # The value is negative.
  #
  # Returns: A value is in pixels but can be a floating point value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Gets the font descender value in font units.
  let descentValue = tface.descent

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(descentValue))

  return Tcl.OK

proc pix_font_fallbackTypeface(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Looks through fallback typefaces to find one that has the glyph.
  #
  # typeface - [font::readTypeface]
  # char     - char
  #
  # Returns: A *new* Tcl `TypeFace` or the arg `TypeFace` if typeface has glyph.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $Tcl.GetString(objv[2])

  if str.len == 0:
    return pixUtils.errorMSG(interp, 
    "pix(error): the len of 'char' is 0."
    )

  let c = str.runeAt(0)

  if tface.hasGlyph(c):
    Tcl.SetObjResult(interp, Tcl.NewStringObj(Tcl.GetString(objv[1]), -1))
  else:
    # New Typeface
    let newtface = tface.fallbackTypeface(c)

    if newtface == nil:
      return pixUtils.errorMSG(interp,
      "pix(error): the '<TypeFace>' return object is 'null'."
      )

    let p = toHexPtr(newtface)
    ptable.addTface(p, newtface)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_getAdvance(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Try to get the advance width for the given rune in pixels.
  # If the rune is not supported by the typeface, this will raise an
  # exception.
  #
  # typeface - [font::readTypeface]
  # char     - char
  #
  # Returns: A value is in pixels
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $Tcl.GetString(objv[2])

  if str.len == 0:
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(0))
    return Tcl.OK

  let 
    c = str.runeAt(0)
    advance = tface.getAdvance(c)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(advance))

  return Tcl.OK

proc pix_font_getGlyphPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The glyph path for the rune.
  #
  # typeface - [font::readTypeface]
  # char     - char
  #
  # Returns: A *new* [path].
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $Tcl.GetString(objv[2])

  if str.len == 0:
    return pixUtils.errorMSG(
      interp, "pix(error): the len of 'char' is 0."
    )

  let c = str.runeAt(0)

  let path = try:
    tface.getGlyphPath(c)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  if path == nil:
    return pixUtils.errorMSG(interp,
    "pix(error): the '<path>' return object is 'null'."
    )

  let p = toHexPtr(path)
  ptable.addPath(p, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_getKerningAdjustment(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Retrieve the kerning adjustment for the pair of characters (c1, c2) from the typeface.
  #
  # typeface - [font::readTypeface]
  # char1    - char
  # char2    - char
  #
  # Kerning is the process of adjusting the space between characters in a proportional font.
  # The kerning adjustment is measured in pixels and is specific to the pair of characters.
  # This allows for more visually pleasing and readable text by reducing or increasing space
  # between specific pairs of characters, depending on the typeface design.
  #
  # Returns: A Tcl double value.
  if objc != 4:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let 
    str1 = $Tcl.GetString(objv[2])
    str2 = $Tcl.GetString(objv[3])

  let c1 = try:
    str1.runeAt(0)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let c2 = try:
    str2.runeAt(0)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let adjustment = tface.getKerningAdjustment(c1, c2)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(adjustment))

  return Tcl.OK

proc pix_font_hasGlyph(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Guess if the glyph exists for this rune.
  #
  # typeface - [font::readTypeface]
  # char     - char
  #
  # Returns: A Tcl boolean value.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $Tcl.GetString(objv[2])

  if str.len == 0:
    Tcl.SetObjResult(interp, Tcl.NewIntObj(0))
    return Tcl.OK

  let c = str.runeAt(0)
  let hasglyph = if tface.hasGlyph(c): 1 else: 0

  Tcl.SetObjResult(interp, Tcl.NewIntObj(hasglyph.cint))

  return Tcl.OK

proc pix_font_layoutBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Computes the width and height in pixels.
  #
  # object - [font::typeset], [font::readFont] or [font::newSpan]
  # text   - string (if [font] object is present)
  #
  # The bounds does not include the outline of the glyphs, only the filled region.
  #
  # Returns: A Tcl dict value {x y} where the x is the width of the bounds in pixels,
  # and the y is the height of the bounds in pixels.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<Arrangement> or <font> + 'text' or <span>"
    )
    return Tcl.ERROR

  var
    count: Tcl.Size
    elements: Tcl.PPObj
    bounds: vmath.Vec2

  let ptable = cast[PixTable](clientData)
  let arg1 = $Tcl.GetString(objv[1])

  if ptable.hasArr(arg1):
    # Arrangement
    let arr = ptable.getArr(arg1)
    bounds = arr.layoutBounds()

  elif ptable.hasFont(arg1):
    # Font + text
    let font = ptable.getFont(arg1)
    if objc != 3:
      return pixUtils.errorMSG(interp,
      "pix(error): If <font> is present, a 'text' must be associated."
      )

    bounds = font.layoutBounds($Tcl.GetString(objv[2]))
  else:
    # Span
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, 
      "pix(error): list <span> object is empty."
      )

    var spans = newSeq[Span]()
    for i in 0..count-1:
      spans.add(ptable.getSpan($Tcl.GetString(elements[i])))

    bounds = spans.layoutBounds()

  let newListobj = Tcl.NewListObj(0, nil)

  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.x))
  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.y))

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_lineGap(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets the font line gap value in font units.
  #
  # typeface - [font::readTypeface]
  #
  # The line gap is the distance in font units between the
  # baseline of one line of text and the baseline of the next.
  # The line gap is used to determine the spacing between
  # lines of text.
  #
  # Returns: The line gap value in font units.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  let lineGap = tface.lineGap()

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(lineGap))

  return Tcl.OK

proc pix_font_lineHeight(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The default line height in font units.
  #
  # typeface - [font::readTypeface]
  #
  # The line height is the height of a line of text in the font,
  # which is typically slightly larger than the ascent of the
  # font (the height above the baseline) plus the descent of the
  # font (the height below the baseline).
  #
  # The line height is typically used to determine the vertical
  # distance between the baselines of two lines of text.
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  let lineHeight = tface.lineHeight()

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(lineHeight))

  return Tcl.OK

proc pix_font_name(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # This procedure retrieves the name of a given typeface object.
  #
  # typeface - [font::readTypeface]
  #
  # Returns: The name of the font.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  let name = tface.name()

  Tcl.SetObjResult(interp, Tcl.NewStringObj(name.cstring, -1))

  return Tcl.OK

proc pix_font_parseOtf(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Otf string.
  #
  # buffer - string
  #
  # The goal is to take a string buffer containing an Otf *(Open Type Font)*
  # and parse it into a TypeFace object.
  #
  # Returns: A *new* TypeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseOtf($Tcl.GetString(objv[1]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  ptable.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_parseSvgFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Svg Font string.
  #
  # buffer - string
  #
  # The *pix::font::parseSvgFont* function is used to interpret the string as an SVG font
  # and convert it into a `TypeFace` object.
  #
  # Returns: A *new* TypeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseSvgFont($Tcl.GetString(objv[1]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  ptable.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_parseTtf(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse Ttf string.
  #
  # buffer - string
  #
  # The *pix::font::parseTtf* function is used to interpret the string as a Ttf
  # (TrueType Font) and convert it into a `TypeFace` object.
  #
  # Returns: A *new* TypeFace object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseTtf($Tcl.GetString(objv[1]))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(typeface)
  ptable.addTface(p, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_scale(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # The scale factor to transform font units into pixels.
  #
  # object - [font::readFont] or [font::readTypeface] object.
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|<TypeFace>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1 = $Tcl.GetString(objv[1])

  let scale =
    if ptable.hasFont(arg1):
      # Font
      let font = ptable.getFont(arg1)
      font.scale()
    elif ptable.hasTFace(arg1):
      # TypeFace
      let typeface = ptable.getTFace(arg1)
      typeface.scale()
    else:
      return pixUtils.errorMSG(interp,
      "pix(error): unknown <font> or <TypeFace> key object found '" & arg1 & "'"
      ) 

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(scale))

  return Tcl.OK

proc pix_font_typeset(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Lays out the character glyphs and returns the arrangement.
  #
  # object  - [font::readFont] or [font::newSpan]
  # options - A Tcl dict, see description below. (optional)
  #
  # #Begintable
  # **bounds** : A list coordinates.
  # **hAlign** : A Enum value.
  # **vAlign** : A Enum value.
  # **wrap**   : A boolean value.
  # #EndTable
  #
  # Returns: A *new* arrangement object.
  if objc notin (2..4):
    let errMsg = "<font> 'text' {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value} or " &
    "<span> {?bounds ?value ?hAlign ?value ?vAlign ?value ?wrap ?value}"
    Tcl.WrongNumArgs(interp, 1, objv, errMsg.cstring)
    return Tcl.ERROR

  var
    count: Tcl.Size
    elements: Tcl.PPObj
    arr: pixie.Arrangement
    font: pixie.Font
    spans = newSeq[Span]()
    text: string
    hasFont: bool = true
    jj = 3

  let ptable = cast[PixTable](clientData)
  let arg1 = $Tcl.GetString(objv[1])

  if ptable.hasFont(arg1):
    # Font
    font = ptable.getFont(arg1)
    if objc < 3:
      return pixUtils.errorMSG(interp,
      "pix(error): If <font> is present, a 'text' must be associated."
      )
    text = $Tcl.GetString(objv[2])
  else:
    # Spans
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, "wrong # args: list <span> is empty.")

    hasFont = false
    for j in 0..count-1:
      spans.add(ptable.getSpan($Tcl.GetString(elements[j])))

  if (objc == 4 and hasFont) or (objc == 3 and not hasFont):
    if hasFont == false: jj = 2
    var opts = pixParses.RenderOptions()
    try:
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
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    arr = if hasFont: typeset(font, text) else: typeset(spans)

  let p = toHexPtr(arr)
  ptable.addArr(p, arr)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_configure(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Configure [font::readFont] parameters.
  #
  # font    - [font::readFont]
  # options - A Tcl dict, see description below.
  #
  # #Begintable
  #  **noKerningAdjustments** : A boolean value.
  #  **underline**            : A boolean value.
  #  **strikethrough**        : A boolean value.
  #  **size**                 : A double value.
  #  **lineHeight**           : A double value.
  #  **paint**                : A list of [paint] objects.
  #  **color**                : A string [color].
  # #EndTable
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv,
    "<font> {?size ?value ?noKerningAdjustments ?value ?lineHeight ?value}"
    )
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  var
    fsize, flineHeight: cdouble
    count, countP: Tcl.Size
    myBool: cint = 0
    elements, elementsP: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp,
    "wrong # args: 'dict options' should be :key value ?key1 ?value1 ..."
    )

  for i in countup(0, count - 1, 2):
    let 
      mkey = $Tcl.GetString(elements[i])
      value = elements[i+1]
    case mkey:
      of "noKerningAdjustments":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK: 
          return Tcl.ERROR
        font.noKerningAdjustments = myBool.bool
      of "underline":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK:
          return Tcl.ERROR
        font.underline = myBool.bool
      of "strikethrough":
        if Tcl.GetBooleanFromObj(interp, value, myBool) != Tcl.OK:
          return Tcl.ERROR
        font.strikethrough = myBool.bool
      of "size":
        if Tcl.GetDoubleFromObj(interp, value, fsize) != Tcl.OK: 
          return Tcl.ERROR
        font.size = fsize
      of "lineHeight":
        if Tcl.GetDoubleFromObj(interp, value, flineHeight) != Tcl.OK:
          return Tcl.ERROR
        font.lineHeight = flineHeight
      of "paint":
        try:
          font.paint = SomePaint(pixUtils.getColor(value))
        except InvalidColor as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "color":
        try:
          font.paint.color = pixUtils.getColor(value)
        except InvalidColor as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "paints":
        if Tcl.ListObjGetElements(interp, value, countP, elementsP) != Tcl.OK:
          return Tcl.ERROR
        if countP != 0:
          var paints = newSeq[pixie.Paint]()
          for ps in 0..countP-1:
            let paint = ptable.loadPaint(interp, elementsP[ps])
            if paint.isNil: return Tcl.ERROR
            paints.add(paint)

          font.paints = paints
      else:
        return pixUtils.errorMSG(interp, 
        "wrong # args: Key '" & mkey & "' not supported."
        )

  return Tcl.OK

proc pix_font_selectionRects(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Gets coordinates rectangle for [font::typeset].
  #
  # arrangement - [font::typeset]
  #
  # The selectionRects method returns a seq of vec4 that represents the
  # coordinates of the rectangles that are used to render the text for
  # the given arrangement object.
  #
  # The coordinates are in the format *(x, y, w, h)* where:
  #  x and y are the top-left corner of the rectangle
  #  w and h are the width and height of the rectangle
  #
  # Returns: A Tcl dictionary with keys that contains the coordinates of the rectangle
  # in the format *(x, y, w, h)*.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement>")
    return Tcl.ERROR

  # Arrangement
  let ptable = cast[PixTable](clientData)
  let arr = ptable.loadArr(interp, objv[1])
  if arr.isNil: return Tcl.ERROR

  let dictGlobobj = Tcl.NewDictObj()

  for index, rect in arr.selectionRects:
    let dictObj = Tcl.NewDictObj()
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("x", 1), Tcl.NewDoubleObj(rect.x))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("y", 1), Tcl.NewDoubleObj(rect.y))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("w", 1), Tcl.NewDoubleObj(rect.w))
    discard Tcl.DictObjPut(nil, dictObj, Tcl.NewStringObj("h", 1), Tcl.NewDoubleObj(rect.h))
    discard Tcl.DictObjPut(nil, dictGlobobj, Tcl.NewIntObj(index.cint), dictObj)

  Tcl.SetObjResult(interp, dictGlobobj)

  return Tcl.OK

proc pix_font_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current font or all fonts if special word `all` is specified.
  #
  # value - [font::readFont] or string
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $Tcl.GetString(objv[1])

  # Font
  if key == "all":
    ptable.clearFont()
  else:
    ptable.delKeyFont(key)

  return Tcl.OK
