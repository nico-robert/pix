# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

proc pix_svg_parse(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Parse SVG XML. Defaults to the SVG's view box size.
  #
  # svg  - string data
  # size - list width,height (optional:SVGviewbox)
  #
  # Returns a 'new' svg object.
  var
    width, height: int
    count: Tcl.Size
    elements: Tcl.PPObj
    svg: Svg

  if objc notin (2..3):
    Tcl.WrongNumArgs(interp, 1, objv, "'svg string' ?{width height}:optional")
    return Tcl.ERROR

  # Svg string
  let arg1 = $Tcl.GetString(objv[1])

  if objc == 3:
    # Size
    if Tcl.ListObjGetElements(interp, objv[2], count, elements) != Tcl.OK:
      return Tcl.ERROR

    if count != 2:
      return pixUtils.errorMSG(interp, "wrong # args: 'size' should be 'width' 'height'")

    if Tcl.GetIntFromObj(interp, elements[0], width)  != Tcl.OK: return Tcl.ERROR
    if Tcl.GetIntFromObj(interp, elements[1], height) != Tcl.OK: return Tcl.ERROR

    try:
       svg = parseSvg(arg1, width, height)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)
  else:
    try:
       svg = parseSvg(arg1)
    except Exception as e:
      return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(svg)
  pixTables.addSVG(p, svg)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_svg_newImage(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Render SVG and return the image.
  #
  # svg - object
  #
  # Returns a 'new' img object.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<svg>")
    return Tcl.ERROR

  # Svg
  let arg1 = $Tcl.GetString(objv[1])

  if not pixTables.hasSVG(arg1):
    return pixUtils.errorMSG(interp, "pix(error): no key <svg> object found '" & arg1 & "'")

  let svg = pixTables.getSVG(arg1)

  let img = try:
    newImage(svg)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  let p = toHexPtr(img)
  pixTables.addImage(p, img)

  Tcl.SetObjResult(interp, Tcl.NewStringObj(p.cstring, -1))

  return Tcl.OK

proc pix_svg_destroy(clientData: Tcl.PClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint =
  # Destroy current svg or all svgs if special word `all` is specified.
  #
  # value - svg object or string
  #
  # Returns nothing.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<svg>|string('all')")
    return Tcl.ERROR

  let arg1 = $Tcl.GetString(objv[1])

  try:
    # Svg
    if arg1 == "all":
      svgTable.clear()
    else:
      svgTable.del(arg1)
  except Exception as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK