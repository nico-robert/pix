# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Parse SVG XML. Defaults to the SVG's view box size.
  #
  # svg  - string data
  # size - list width,height (optional:SVGviewbox)
  #
  # Returns: A *new* [svg] object.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv,
    "'svg string' ?{width height}:optional"
    )
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)

  # Svg string
  let arg1 = $Tcl.GetString(objv[1])
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
    Tcl.WrongNumArgs(interp, 1, objv, "<svg>")
    return Tcl.ERROR

  # Svg
  let ptable = cast[PixTable](clientData)
  let svg = ptable.loadSVG(interp, objv[1])
  if svg.isNil: return Tcl.ERROR

  let img = try:
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
    Tcl.WrongNumArgs(interp, 1, objv, "<svg>|string('all')")
    return Tcl.ERROR

  let ptable = cast[PixTable](clientData)
  let key = $Tcl.GetString(objv[1])

  # Svg
  if key == "all":
    ptable.clearSVG()
  else:
    ptable.delKeySVG(key)

  return Tcl.OK