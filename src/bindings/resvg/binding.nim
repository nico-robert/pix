# Copyright (c) 2025-2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import ./types as resvg
import ../tcl/binding as Tcl
import ../../core/pixutils as pixUtils
import std/[strutils, options]
import pixie

type
  RenderResvgOpts* = object
    dpi*: Option[cfloat] = none(cfloat)
    mtx*: Option[resvg.transform] = none(resvg.transform)
    styleSheet*: Option[cstring] = none(cstring)
    serifFontFamily*: Option[cstring] = none(cstring)
    sansSerifFontFamily*: Option[cstring] = none(cstring)
    cursiveFontFamily*: Option[cstring] = none(cstring)
    fantasyFontFamily*: Option[cstring] = none(cstring)
    monospaceFontFamily*: Option[cstring] = none(cstring)
    languages*: Option[cstring] = none(cstring)
    shapeRenderingMode*: Option[resvg.shape_rendering] = none(resvg.shape_rendering)
    textRenderingMode*: Option[resvg.text_rendering] = none(resvg.text_rendering)
    imageRenderingMode*: Option[resvg.image_rendering] = none(resvg.image_rendering)
    fontFamily*: Option[cstring] = none(cstring)
    loadFontFile*: Option[cstring] = none(cstring)
    fontSize*: Option[cfloat] = none(cfloat)
    loadSystemFonts*: Option[bool] = none(bool)

{.pragma: resvg, cdecl, importc: "$1", header: "resvg.h".}

proc resvg_transform_identity*(): resvg.transform {.resvg.}
proc resvg_init_log*() {.resvg.}
proc resvg_options_create*(): resvg.optionsPtr {.resvg.}
proc resvg_options_destroy*(options: resvg.optionsPtr) {.resvg.}
proc resvg_tree_destroy*(tree: resvg.render_treePtr) {.resvg.}
proc resvg_get_image_size*(tree: resvg.render_treePtr): resvg.size {.resvg.}
proc resvg_parse_tree_from_file*(filename: cstring, options: resvg.optionsPtr, tree: var resvg.render_treePtr): resvg.error {.resvg.}
proc resvg_parse_tree_from_data*(data: cstring, len: csize_t, options: resvg.optionsPtr, tree: var resvg.render_treePtr): resvg.error {.resvg.}
proc resvg_render*(tree: resvg.render_treePtr, transform: resvg.transform, width: cint, height: cint, pixmap: ptr uint8) {.resvg.}
proc resvg_is_image_empty*(tree: resvg.render_treePtr): bool {.resvg.}

# Options :
proc resvg_options_set_dpi*(options: resvg.optionsPtr, dpi: cfloat) {.resvg.}
proc resvg_options_set_stylesheet*(options: resvg.optionsPtr, stylesheet: cstring) {.resvg.}
proc resvg_options_set_serif_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_set_sans_serif_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_set_cursive_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_set_fantasy_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_set_monospace_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_set_languages*(options: resvg.optionsPtr, languages: cstring) {.resvg.}
proc resvg_options_set_shape_rendering_mode*(options: resvg.optionsPtr, mode: resvg.shape_rendering) {.resvg.}
proc resvg_options_set_text_rendering_mode*(options: resvg.optionsPtr, mode: resvg.text_rendering) {.resvg.}
proc resvg_options_set_image_rendering_mode*(options: resvg.optionsPtr, mode: resvg.image_rendering) {.resvg.}
proc resvg_options_set_font_family*(options: resvg.optionsPtr, family: cstring) {.resvg.}
proc resvg_options_load_font_file*(options: resvg.optionsPtr, filename: cstring) {.resvg.}
proc resvg_options_set_font_size*(options: resvg.optionsPtr, size: cfloat) {.resvg.}
proc resvg_options_load_system_fonts*(options: resvg.optionsPtr) {.resvg.}

# Initializes the RESVG library to log
# information to the stderr output.
when defined(debug):
  resvg_init_log()

proc toResvgMat*(mat: vmath.Mat3): resvg.transform =
  result.a = mat[0,0].cfloat  # a: scale x > m00
  result.b = mat[1,0].cfloat  # b: skew x  > m10
  result.c = mat[0,1].cfloat  # c: skew y  > m01
  result.d = mat[1,1].cfloat  # d: scale y > m11
  result.e = mat[2,0].cfloat  # e: translate x > m20
  result.f = mat[2,1].cfloat  # f: translate y > m21

proc parse*(data: string, targetWidth: cint = -1, targetHeight: cint = -1, option: Option[RenderResvgOpts] = none(RenderResvgOpts)): Resvg =
  # Parse an SVG string and render it to a pixmap.
  #
  # data         - The SVG string to parse.
  # targetWidth  - The target width of the rendered image. If -1, the SVG's view box size is used.
  # targetHeight - The target height of the rendered image. If -1, the SVG's view box size is used.
  #
  # Returns: A new Resvg object containing the rendered image.
  var options = resvg_options_create()
  var tree: resvg.render_treePtr
  var tr = resvg_transform_identity()

  if option.isSome:
    let opts = option.get()
    if opts.dpi.isSome                : resvg_options_set_dpi(options, opts.dpi.get())
    if opts.styleSheet.isSome         : resvg_options_set_stylesheet(options, opts.styleSheet.get())
    if opts.serifFontFamily.isSome    : resvg_options_set_serif_family(options, opts.serifFontFamily.get())
    if opts.sansSerifFontFamily.isSome: resvg_options_set_sans_serif_family(options, opts.sansSerifFontFamily.get())
    if opts.cursiveFontFamily.isSome  : resvg_options_set_cursive_family(options, opts.cursiveFontFamily.get())
    if opts.fantasyFontFamily.isSome  : resvg_options_set_fantasy_family(options, opts.fantasyFontFamily.get())
    if opts.monospaceFontFamily.isSome: resvg_options_set_monospace_family(options, opts.monospaceFontFamily.get())
    if opts.languages.isSome          : resvg_options_set_languages(options, opts.languages.get())
    if opts.shapeRenderingMode.isSome : resvg_options_set_shape_rendering_mode(options, opts.shapeRenderingMode.get())
    if opts.textRenderingMode.isSome  : resvg_options_set_text_rendering_mode(options, opts.textRenderingMode.get())
    if opts.imageRenderingMode.isSome : resvg_options_set_image_rendering_mode(options, opts.imageRenderingMode.get())
    if opts.fontFamily.isSome         : resvg_options_set_font_family(options, opts.fontFamily.get())
    if opts.loadFontFile.isSome       : resvg_options_load_font_file(options, opts.loadFontFile.get())
    if opts.fontSize.isSome           : resvg_options_set_font_size(options, opts.fontSize.get())
    if opts.loadSystemFonts.isSome    : resvg_options_load_system_fonts(options)
    if opts.mtx.isSome                : tr = opts.mtx.get()

  let err = resvg_parse_tree_from_data(data.cstring, data.len.csize_t, options, tree)

  if err != resvg.RESVG_OK:
    raise newException(
      ValueError, 
      "pix(error): Failed to parse SVG: '" & $err & "'"
    )

  if resvg_is_image_empty(tree):
    raise newException(ValueError,"pix(error): SVG is empty.")

  let imgSize = resvg_get_image_size(tree)

  var 
    width = imgSize.width.cint
    height = imgSize.height.cint

  if (width <= 0) or (height <= 0):
    raise newException(ValueError, "pix(error): Invalid resvg image size.")

  if targetWidth != -1 or targetHeight != -1:
    let
      twidth  = if targetWidth  == -1: imgSize.width  else: targetWidth.cfloat
      theight = if targetHeight == -1: imgSize.height else: targetHeight.cfloat

    if (twidth <= 0.0) or (theight <= 0.0):
      raise newException(ValueError, "pix(error): Invalid target size.")

    let
      scale_x = twidth / imgSize.width
      scale_y = theight / imgSize.height

    tr.a   = scale_x
    tr.d   = scale_y
    width  = twidth.cint
    height = theight.cint

  var pixmap: seq[uint8] = newSeq[uint8](width * height * 4)
  resvg_render(tree, tr, width, height, pixmap[0].addr)

  result = Resvg(width: width, height: height, pixmap: pixmap)

  defer:
    if options != nil:
      resvg_options_destroy(options)
    if tree != nil:
      resvg_tree_destroy(tree)

proc toImage*(svg: Resvg): Image =
  # Converts a Resvg object to an Image pixie object.
  #
  # svg - The Resvg object to convert.
  #
  # Returns: An Image object.
  result = newImage(svg.width, svg.height)
  copyMem(result.data[0].addr, svg.pixmap[0].addr, svg.pixmap.len)

proc options*(interp: Tcl.PInterp, objv: Tcl.PObj, opts: var RenderResvgOpts) =
  # Parse the options from the Tcl dict and set the fields of the 'RenderResvgOpts' object.
  #
  #  interp - interpreter.
  #  objv   - object options.
  #  opts   - RenderResvgOpts object to populate.
  #
  # Returns: Nothing or an exception if an error is found.
  var
    count: Tcl.Size
    elements: Tcl.PPObj

  # Dict
  if Tcl.ListObjGetElements(interp, objv, count, elements) != Tcl.OK:
    raise newException(ValueError, $interp)

  if count mod 2 != 0:
    raise newException(ValueError,
      "wrong # args: 'dict options' should be :key value ?key1 ?value1..."
    )

  for i in countup(0, count - 1, 2):
    let 
      key = $elements[i]
      value = elements[i+1]
    case key:
      of "dpi":
        var dpi: cdouble
        if Tcl.GetDoubleFromObj(interp, value, dpi) != Tcl.OK:
          raise newException(ValueError, $interp)
        if dpi <= 0.0:
          raise newException(ValueError, "dpi must be greater than 0.")
        opts.dpi = some(dpi.cfloat)
      of "styleSheet":
        opts.styleSheet = some(Tcl.GetString(value))
      of "serifFontFamily":
        opts.serifFontFamily = some(Tcl.GetString(value))
      of "sansSerifFontFamily":
        opts.sansSerifFontFamily = some(Tcl.GetString(value))
      of "cursiveFontFamily":
        opts.cursiveFontFamily = some(Tcl.GetString(value))
      of "fantasyFontFamily":
        opts.fantasyFontFamily = some(Tcl.GetString(value))
      of "monospaceFontFamily":
        opts.monospaceFontFamily = some(Tcl.GetString(value))
      of "languages":
        opts.languages = some(Tcl.GetString(value))
      of "shapeRenderingMode":
        try:
          opts.shapeRenderingMode = some(parseEnum[resvg.shape_rendering]($value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "textRenderingMode":
        try:
          opts.textRenderingMode = some(parseEnum[resvg.text_rendering]($value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "imageRenderingMode":
        try:
          opts.imageRenderingMode = some(parseEnum[resvg.image_rendering]($value))
        except ValueError as e:
          raise newException(ValueError, move(e.msg))
      of "fontFamily":
        opts.fontFamily = some(Tcl.GetString(value))
      of "loadFontFile":
        opts.loadFontFile = some(Tcl.GetString(value))
      of "fontSize":
        var fontSize: cdouble
        if Tcl.GetDoubleFromObj(interp, value, fontSize) != Tcl.OK:
          raise newException(ValueError, $interp)
        if fontSize <= 0.0:
          raise newException(ValueError, "fontSize must be greater than 0.")
        opts.fontSize = some(fontSize.cfloat)
      of "loadSystemFonts":
        var load: cint
        if Tcl.GetBooleanFromObj(interp, value, load) != Tcl.OK:
          raise newException(ValueError, $interp)
        if load.bool:
          opts.loadSystemFonts = some(true)
      of "mtx":
        var mtx: vmath.Mat3
        if pixUtils.matrix3x3(interp, value, mtx) != Tcl.OK:
          raise newException(ValueError, $interp)
        opts.mtx = some(toResvgMat(mtx))
      else:
        raise newException(ValueError, 
          "wrong # args: Key '" & key & "' not supported."
        )