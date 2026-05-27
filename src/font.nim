# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_font_readFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Attempts to read a font from the specified file path.
  #
  # filePath - path to the font file.
  #
  # Pixie handles font loading and verification. If the file does not exist 
  # or is invalid, an error message is returned.
  #
  # Returns: A *new* handle [font] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Font
  let font = try:
    readFont($objv[1])
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let fontKey = toHexPtr(font)
  ptable.addFont(fontKey, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(fontKey.cstring, -1))

  return Tcl.OK

proc pix_font_size(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets the font size (Equivalent to `pix::font::configure`).
  #
  # font - [font] object handle
  # size - Double value (in pixels)
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
  font.size = objv[2].getFloat()

  return Tcl.OK

proc pix_font_color(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets the font color (Equivalent to `pix::font::configure`).
  #
  # font  - [font::readFont] object handle
  # color - color string (e.g., "red" or "#HEX")
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
    font.paint.color = objv[2].getColor()
  except InvalidColor as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_font_newFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Creates a new [font] object from a given TypeFace.
  #
  # typeface - [readTypeface] object handle (created via `pix::font::readTypeface`)
  #
  # Returns: A *new* handle [font] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Create a new pixie.Font from the given TypeFace object.
  let font = newFont(tface)

  let fontKey = toHexPtr(font)
  ptable.addFont(fontKey, font)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(fontKey.cstring, -1))

  return Tcl.OK

proc pix_font_newSpan(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets new Span.
  #
  # font - [font::readFont]
  # text - string
  #
  # Returns: A *new* handle <span> object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> text")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  # Create a new span object.
  let span = newSpan($objv[2], font)

  let spanKey = toHexPtr(span)
  ptable.addSpan(spanKey, span)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(spanKey.cstring, -1))

  return Tcl.OK

proc pix_font_paint(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets font Paint if paint optional argument is set, otherwise gets the font paint.
  #
  # font  - [font::readFont]
  # paint - [paint] (optional)
  #
  # Returns: 
  # A *new* handle [paint] object if no paint optional argument is set, otherwise set the font paint.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> ?<paint>?")
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

proc pix_font_readTypeface(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Loads a typeface from a file.
  #
  # filePath - file font (otf, ttc, ttf, svg)
  #
  # Returns: A *new* handle <TypeFace> object.
  #
  # See also : [font::parseTtf] [font::parseOtf] [font::parseSvgFont]
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Typeface
  let typeface = try:
    readTypeface($objv[1])
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let tFKey = toHexPtr(typeface)
  ptable.addTface(tFKey, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(tFKey.cstring, -1))

  return Tcl.OK

proc pix_font_readTypefaces(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Loads a OpenType Collection (.ttc).
  #
  # filePath - file font (ttc)
  #
  # Returns: A Tcl list with `Typeface` objects.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "filePath")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let newListobj = Tcl.NewListObj(0, nil)

  try:
    # Typeface
    for _, typeface in readTypefaces($objv[1]):
      let tFKey = toHexPtr(typeface)
      ptable.addTface(tFKey, typeface)
      discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewStringObj(tFKey.cstring, -1))
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_ascent(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets the font ascender value in font units.<br>
  #
  # typeface - [font::readTypeface]
  #
  # The ascender is the distance from the baseline to the highest point of any glyph.
  #
  # Returns: A double value in pixels (always positive).
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

proc pix_font_computeBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Computes the bounding box of a text arrangement.
  #
  # arrangement - [font::typeset] object (from `pix::font::typeset`)
  # transform   - optional 3x3 transformation matrix (optional:identityMatrix)
  #
  # The bounds represent the axis-aligned bounding box of all filled glyph 
  # regions in the arrangement's coordinate system.
  #
  # Returns: A Tcl dict value where:<br>
  # #Begintable
  #    **x** : The x offset of the top-left corner of the bounds.
  #    **y** : The y offset of the top-left corner of the bounds.
  #    **w** : The width of the bounds.
  #    **h** : The height of the bounds.
  # #EndTable
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement> ?transform?")
    return Tcl.ERROR

  # Arrangement
  let ptable = cast[PixTable](clientData)
  let arr = ptable.loadArr(interp, objv[1])
  if arr.isNil: return Tcl.ERROR

  let rect = 
    if objc == 3:
      try:
        arr.computeBounds(objv[2].getMtx())
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      try:
        arr.computeBounds()
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  Tcl.SetObjResult(interp, rect.toDictObj())

  return Tcl.OK

proc pix_font_copy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Copy font.
  #
  # font - [font::readFont]
  #
  # Returns: A *new* handle [font] object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  let newfont = font.copy()
  let fontKey = toHexPtr(newfont)
  ptable.addFont(fontKey, newfont)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(fontKey.cstring, -1))

  return Tcl.OK

proc pix_font_defaultLineHeight(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(font.defaultLineHeight))

  return Tcl.OK

proc pix_font_descent(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets the font descender value in font units.
  #
  # typeface - [font::readTypeface]
  #
  # The descent is the distance from the baseline to the lowest point of any glyph.
  #
  # Returns: A double value in pixels (usually negative).
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(tface.descent))

  return Tcl.OK

proc pix_font_capHeight(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # The font cap height value in font units (pixie >= 5.1.0).
  #
  # typeface - [font::readTypeface]
  #
  # The cap height is the distance from the baseline to the highest point of any glyph in the font.
  # This value is used to position text in the y-direction.
  #
  # Returns: A value is in pixels but can be a floating point value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace>")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(tface.capHeight))

  return Tcl.OK

proc pix_font_fallbackTypeface(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Searches through fallback typefaces to find one containing the specified character.
  #
  # typeface - [font::readTypeface] object handle.
  # char     - the character to look for.
  #
  # Returns: A handle to the fallback typeface, or the original typeface if it 
  # already contains the glyph.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $objv[2]

  if str.len == 0:
    return pixUtils.errorMSG(interp, 
      "pix(error): The len of 'char' is 0."
    )

  let c = str.runeAt(0)

  if tface.hasGlyph(c):
    Tcl.SetObjResult(interp, Tcl.NewStringObj(Tcl.GetString(objv[1]), -1))
  else:
    # New Typeface
    let newtface = tface.fallbackTypeface(c)

    if newtface == nil:
      return pixUtils.errorMSG(interp,
        "pix(error): The '<TypeFace>' return object is 'null'."
      )

    let p = toHexPtr(newtface)
    ptable.addTface(p, newtface)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_getAdvance(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
  let str = $objv[2]

  if str.len == 0:
    Tcl.SetObjResult(interp, Tcl.NewDoubleObj(0))
    return Tcl.OK

  let 
    c = str.runeAt(0)
    advance = tface.getAdvance(c)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(advance))

  return Tcl.OK

proc pix_font_getGlyphPath(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # The glyph path for the rune.
  #
  # typeface - [font::readTypeface]
  # char     - char
  #
  # Returns: A *new* handle [path] object.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let str = $objv[2]

  if str.len == 0:
    return pixUtils.errorMSG(
      interp, "pix(error): The len of 'char' is 0."
    )

  let c = str.runeAt(0)

  let path = try:
    tface.getGlyphPath(c)
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  if path == nil:
    return pixUtils.errorMSG(interp,
      "pix(error): The '<path>' return object is 'null'."
    )

  let pathKey = toHexPtr(path)
  ptable.addPath(pathKey, path)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(pathKey.cstring, -1))

  return Tcl.OK

proc pix_font_getKerningAdjustment(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
    Tcl.WrongNumArgs(interp, 1, objv, "<TypeFace> char1 char2")
    return Tcl.ERROR

  # TypeFace
  let ptable = cast[PixTable](clientData)
  let tface = ptable.loadTFace(interp, objv[1])
  if tface.isNil: return Tcl.ERROR

  # Rune
  let 
    str1 = $objv[2]
    str2 = $objv[3]

  let c1 = try:
    str1.runeAt(0)
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let c2 = try:
    str2.runeAt(0)
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let adjustment = tface.getKerningAdjustment(c1, c2)

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(adjustment))

  return Tcl.OK

proc pix_font_hasGlyph(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
  let str = $objv[2]

  if str.len == 0:
    Tcl.SetObjResult(interp, Tcl.NewIntObj(0))
    return Tcl.OK

  Tcl.SetObjResult(interp, Tcl.NewIntObj(
    cint(tface.hasGlyph(str.runeAt(0))))
  )

  return Tcl.OK

proc pix_font_layoutBounds(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Computes the logical width and height (in pixels) of the given object.
  #
  # object - [typeset], [readFont] or [newSpan] object.
  # text   - required only if a [font] object is provided.
  #
  # Returns: A Tcl list {width height}.
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
  let arg1 = $objv[1]

  if ptable.hasArr(arg1):
    # Arrangement
    let arr = ptable.getArr(arg1)
    bounds = arr.layoutBounds()

  elif ptable.hasFont(arg1):
    # Font + text
    let font = ptable.getFont(arg1)
    if objc != 3:
      return pixUtils.errorMSG(interp,
        "pix(error): 'text' argument missing; required when the first argument is a <font> object."
      )

    bounds = font.layoutBounds($objv[2])
  else:
    # Span
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, 
        "pix(error): The list <span> object is empty."
      )

    var spans = newSeq[Span]()
    for i in 0..count-1:
      spans.add(ptable.getSpan($elements[i]))

    bounds = spans.layoutBounds()

  let newListobj = Tcl.NewListObj(2, nil)

  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.x))
  discard Tcl.ListObjAppendElement(interp, newListobj, Tcl.NewDoubleObj(bounds.y))

  Tcl.SetObjResult(interp, newListobj)

  return Tcl.OK

proc pix_font_lineGap(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(tface.lineGap()))

  return Tcl.OK

proc pix_font_lineHeight(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

  Tcl.SetObjResult(interp, Tcl.NewDoubleObj(tface.lineHeight()))

  return Tcl.OK

proc pix_font_name(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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

proc pix_font_parseOtf(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse Otf string.
  #
  # buffer - string
  #
  # The goal is to take a string buffer containing an Otf *(Open Type Font)*
  # and parse it into a TypeFace object.
  #
  # Returns: A *new* handle <TypeFace> object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseOtf($objv[1])
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let tFKey = toHexPtr(typeface)
  ptable.addTface(tFKey, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(tFKey.cstring, -1))

  return Tcl.OK

proc pix_font_parseSvgFont(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse Svg Font string.
  #
  # buffer - string
  #
  # The `pix::font::parseSvgFont` function is used to interpret the string as an SVG font
  # and convert it into a `TypeFace` object.
  #
  # Returns: A *new* handle <TypeFace> object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseSvgFont($objv[1])
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let tFKey = toHexPtr(typeface)
  ptable.addTface(tFKey, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(tFKey.cstring, -1))

  return Tcl.OK

proc pix_font_parseTtf(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse Ttf string.
  #
  # buffer - string
  #
  # The `pix::font::parseTtf` function is used to interpret the string as a Ttf
  # (TrueType Font) and convert it into a `TypeFace` object.
  #
  # Returns: A *new* handle <TypeFace> object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "buffer")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Buffer
  let typeface = try:
    parseTtf($objv[1])
  except PixieError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let tFKey = toHexPtr(typeface)
  ptable.addTface(tFKey, typeface)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(tFKey.cstring, -1))

  return Tcl.OK

proc pix_font_scale(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # The scale factor to transform font units into pixels.
  #
  # object - [font::readFont] or [font::readTypeface] object.
  #
  # Returns: A Tcl double value.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|<TypeFace>")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let arg1 = $objv[1]

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

proc pix_font_typeset(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
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
  # Returns: A *new* handle <arrangement> object.
  if objc notin (2..4):
    let errMsg = "<font> 'text' {?bounds value ?hAlign value ?vAlign value ?wrap value} or " &
    "<span> {?bounds value ?hAlign value ?vAlign value ?wrap value}"
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
  let arg1 = $objv[1]

  if ptable.hasFont(arg1):
    # Font
    font = ptable.getFont(arg1)
    if objc < 3:
      return pixUtils.errorMSG(interp,
        "pix(error): 'text' argument missing; required when the first argument is a <font> object."
      )
    text = $objv[2]
  else:
    # Spans
    if Tcl.ListObjGetElements(interp, objv[1], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count == 0:
      return pixUtils.errorMSG(interp, "wrong # args: list <span> is empty.")

    hasFont = false
    for j in 0..count-1:
      spans.add(ptable.getSpan($elements[j]))

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
    except CatchableError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  else:
    arr = if hasFont: typeset(font, text) else: typeset(spans)

  let p = toHexPtr(arr)
  ptable.addArr(p, arr)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_font_configure(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Configure [font::readFont] parameters.
  #
  # font    - [font::readFont]
  # options - A Tcl dict, see description below.
  #
  # #Begintable
  # **noKerningAdjustments** : Boolean.
  # **underline**            : Boolean.
  # **strikethrough**        : Boolean.
  # **size**                 : Double (pixels).
  # **lineHeight**           : Double (pixels).
  # **color**                : Color string.
  # **paint**                : [paint] object.
  # #EndTable
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<font> {?size value ...?}")
    return Tcl.ERROR

  # Font
  let ptable = cast[PixTable](clientData)
  let font = ptable.loadFont(interp, objv[1])
  if font.isNil: return Tcl.ERROR

  var
    count, countP: Tcl.Size
    elements, elementsP: Tcl.PPObj

  if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
    return Tcl.ERROR

  if count mod 2 != 0:
    return pixUtils.errorMSG(interp,
      "wrong # args: 'options' should be a list of {?key value ...?}"
    )

  for i in countup(0, count - 1, 2):
    let 
      mkey = $elements[i]
      value = elements[i+1]
    case mkey:
      of "noKerningAdjustments":
        font.noKerningAdjustments = value.getBool()
      of "underline":
        font.underline = value.getBool()
      of "strikethrough":
        font.strikethrough = value.getBool()
      of "size":
        font.size = value.getFloat()
      of "lineHeight":
        font.lineHeight = value.getFloat()
      of "paint":
        font.paint = try:
          SomePaint(value.getColor())
        except InvalidColor as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
      of "color":
        font.paint.color = try:
          value.getColor()
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

proc pix_font_selectionRects(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Gets the selection rectangles for a text arrangement.
  #
  # arrangement - [font::typeset] object handle.
  #
  # Returns: A Tcl dictionary where each value represents 
  # a selection rectangle {x y w h}.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<Arrangement>")
    return Tcl.ERROR

  # Arrangement
  let ptable = cast[PixTable](clientData)
  let arr = ptable.loadArr(interp, objv[1])
  if arr.isNil: return Tcl.ERROR

  let dictGlobobj = Tcl.NewDictObj()

  for index, rect in arr.selectionRects:
    if Tcl.DictObjPut(
      interp, 
      dictGlobobj, 
      Tcl.NewIntObj(index.cint), 
      rect.toDictObj()
    ): != Tcl.OK:
      return Tcl.ERROR

  Tcl.SetObjResult(interp, dictGlobobj)

  return Tcl.OK

proc pix_font_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy the [font] or all fonts if special word `all` is specified.
  #
  # value - [font::readFont] or string
  #
  # Returns: Nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<font>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $objv[1]

  # Font
  if key == "all":
    ptable.clearFont()
  else:
    ptable.delKeyFont(key)

  return Tcl.OK
