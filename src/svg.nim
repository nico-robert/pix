# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse SVG XML. Defaults to the SVG's view box size.
  #
  # svg  - string data
  # size - list width,height (optional:SVGviewbox)
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
  # Returns: A *new* [svg] object.
  when defined(resvg):
    if objc notin (2..4):
      Tcl.WrongNumArgs(interp, 1, objv,
        "'svg string' ?{width height} ?opts"
      )
      return Tcl.ERROR

    let ptable = cast[PixTable](clientData)

    # Svg string
    let arg1 = $objv[1]
    var svg: Resvg

    if objc == 4:
      var width, height: cint

      # Size
      if pixParses.getListInt(interp, objv[2], width, height, 
        "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
        return Tcl.ERROR

      var opts = RenderResvgOpts()
      try:
        resvg.options(interp, objv[3], opts)
        svg = resvg.parse(arg1, width, height, some(opts))
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    elif objc == 3:
      var width, height: cint

      # Size
      if pixParses.getListInt(interp, objv[2], width, height, 
        "wrong # args: 'size' should be 'width' 'height'") == Tcl.OK:
        svg = resvg.parse(arg1, width, height)
      else:
        var opts = RenderResvgOpts()
        try:
          resvg.options(interp, objv[3], opts)
          svg = resvg.parse(arg1, option = some(opts))
        except ValueError as e:
          return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      # pixie SVG
      try:
        svg = resvg.parse(arg1)
      except ValueError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    let p = toHexPtr(svg)
    ptable.addRESVG(p, svg)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))
  else:
    if objc notin [2, 3]:
      Tcl.WrongNumArgs(interp, 1, objv,
        "'svg string' ?{width height}:optional"
      )
      return Tcl.ERROR

    let ptable = cast[PixTable](clientData)

    # Svg string
    let arg1 = $objv[1]
    var svg: Svg

    if objc == 3:
      var width, height: cint

      # Size
      if pixParses.getListInt(interp, objv[2], width, height, 
        "wrong # args: 'size' should be 'width' 'height'") != Tcl.OK:
        return Tcl.ERROR

      try:
        svg = parseSvg(arg1, width, height)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      try:
        svg = parseSvg(arg1)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

    let p = toHexPtr(svg)
    ptable.addSVG(p, svg)

    Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_svg_newImage(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Render SVG and return the image.
  #
  # svg - [svg::parse]
  #
  # Returns: A *new* [img] object.
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
      except Exception as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
    else:
      let svg = ptable.loadSVG(interp, objv[1])
      if svg.isNil: return Tcl.ERROR
      try:
        newImage(svg)
      except PixieError as e:
        return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(img)
  ptable.addImage(p, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_svg_destroy(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Destroy current svg or all svgs if special word `all` is specified.
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