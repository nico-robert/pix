# Copyright (c) 2024-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse SVG XML. Defaults to the SVG's view box size.
  #
  # svg  - string data
  # size - A list {width height} (optional:SVGviewbox)
  # opts - dict options (if compiled with **resvg** lib) (optional)
  #
  #  **resvg** dictionary options. The options are:<br>
  #  #Begintable
  #  **dpi**                : Sets the target DPI.
  #  **mtx**                : The transformation matrix (*matrix3x3*) to apply to the SVG.
  #  **styleSheet**         : The style sheet to use.
  #  **serifFontFamily**    : Sets the `serif` font family.
  #  **sansSerifFontFamily**: Sets the `sans-serif` font family.
  #  **cursiveFontFamily**  : Sets the `cursive` font family.
  #  **fantasyFontFamily**  : Sets the `fantasy` font family.
  #  **monospaceFontFamily**: Sets the `monospace` font family.
  #  **languages**          : Sets the list of languages.
  #  **shapeRenderingMode** : Sets the default shape rendering method.
  #  **textRenderingMode**  : Sets the default text rendering method.
  #  **imageRenderingMode** : Sets the default image rendering method.
  #  **fontFamily**         : Sets the default font family.
  #  **loadFontFile**       : Loads a font file into the internal fonts database.
  #  **fontSize**           : Sets the default font size. 
  #  **loadSystemFonts**    : Loads system fonts into the internal fonts database.
  #  #EndTable
  #
  # Returns: A *new* handle [svg] object.
  let ptable = cast[PixTable](clientData)
  let svgStr = $objv[1]

  when defined(resvg):
    if objc notin (2..4):
      Tcl.WrongNumArgs(interp, 1, objv, "'svg string' ?size? ?opts?")
      return Tcl.ERROR

    var width, height: int
    var opts = none(RenderResvgOpts)
    var hasSize = false

    if objc >= 3:
      if getListInt(interp, objv[2], width, height, "") == Tcl.OK:
        hasSize = true
        if objc == 4:
          var o = RenderResvgOpts()
          try: resvg.options(interp, objv[3], o)
          except ValueError as e:
            return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
          opts = some(o)
      else:
        var o = RenderResvgOpts()
        try: resvg.options(interp, objv[2], o)
        except ValueError as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
        opts = some(o)

    let svg = try:
      if hasSize: resvg.parse(svgStr, width, height, opts)
      else: resvg.parse(svgStr, option = opts)
    except ValueError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    let svgKey = toHexPtr(svg)
    ptable.addRESVG(svgKey, svg)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(svgKey.cstring, -1))

  else:
    if objc notin [2, 3]:
      Tcl.WrongNumArgs(interp, 1, objv, "'svg string' ?size?")
      return Tcl.ERROR

    var width, height: int
    if objc == 3 and getListInt(interp, objv[2], width, height,
        "wrong # args: 'size' should be '{width height}") != Tcl.OK:
      return Tcl.ERROR

    let svg = try:
      if objc == 3: parseSvg(svgStr, width, height)
      else: parseSvg(svgStr)
    except PixieError as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    let svgKey = toHexPtr(svg)
    ptable.addSVG(svgKey, svg)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(svgKey.cstring, -1))

  return Tcl.OK

proc pix_svg_newImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Render SVG and return the image.
  #
  # svg - [svg::parse]
  #
  # Returns: A *new* handle [img] object.
  if objc != 2:
    let text = if defined(resvg): "<resvg>" else: "<svg>"
    Tcl.WrongNumArgs(interp, 1, objv, text.cstring)
    return Tcl.ERROR

  # Svg
  let ptable = cast[PixTable](clientData)

  # Image
  let img =
    when defined(resvg):
      let svg = ptable.loadRESVG(interp, objv[1])
      if svg.isNil: return Tcl.ERROR
      try:
        resvg.toImage(svg)
      except CatchableError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      let svg = ptable.loadSVG(interp, objv[1])
      if svg.isNil: return Tcl.ERROR
      try:
        newImage(svg)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let imgKey = toHexPtr(img)
  ptable.addImage(imgKey, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(imgKey.cstring, -1))

  return Tcl.OK

proc pix_svg_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy the [svg] or all svgs if special word `all` is specified.
  #
  # value - [svg::parse] or string.
  #
  # Returns: Nothing.
  if objc != 2:
    let text = if defined(resvg): "<resvg>|string('all')" else: "<svg>|string('all')"
    Tcl.WrongNumArgs(interp, 1, objv, text.cstring)
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $objv[1]

  # Svg
  if key == "all":
    when defined(resvg):
      ptable.clearRESVG() 
    else:
      ptable.clearSVG()
  else:
    when defined(resvg):
      ptable.delKeyRESVG(key)
    else:
      ptable.delKeySVG(key)

  return Tcl.OK