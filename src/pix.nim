# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
# pix - Tcl wrapper around Pixie, a full-featured 2D graphics library written in Nim.
# (https://github.com/treeform/pixie)

# 03-Jun-2024 : v0.1 Initial release

import pixie, pixie/fileformats/svg
import std/strutils
import tables
import std/base64
from tclpix as Tcl import nil
from tkpix  as Tk import nil
# 
var imgTable   = initTable[string, Image]()
var ctxTable   = initTable[string, Context]()
var pathTable  = initTable[string, Path]()
var paintTable = initTable[string, Paint]()
var fontTable  = initTable[string, Font]()
var arrTable   = initTable[string, Arrangement]()
var svgTable   = initTable[string, Svg]()

var version: cstring = "0.1"

include "utils.nim"
include "image.nim"
include "context.nim"
include "paint.nim"
include "paths.nim"
include "surface.nim"
include "font.nim"
include "svg.nim"

proc Pix_Init(interp: Tcl.PInterp): cint {.exportc,dynlib.} =

  discard Tcl.InitStubs(interp, "8.6", 0)
  discard Tk.InitStubs(interp, "8.6", 0)

  # Namespace
  var ns = Tcl.CreateNamespace(interp, "pix", nil, nil)
  if ns == nil:
    ns = Tcl.FindNamespace(interp, "pix", nil, 0)
    if ns == nil:
      Tcl.SetResult(interp, "Can't create or find namespace 'pix'", nil)
      return Tcl.ERROR

  # Package
  discard Tcl.PkgProvideEx(interp, "pix", version, nil)
  
  # Commands context :
  if Tcl.CreateObjCommand(interp, "pix::ctx::new", pix_context, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeStyle", pix_ctx_strokeStyle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeSegment", pix_ctx_strokeSegment, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeRect", pix_ctx_strokeRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::moveTo", pix_ctx_moveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineTo", pix_ctx_lineTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::rect", pix_ctx_rect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillRect", pix_ctx_fillRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineJoin", pix_ctx_lineJoin, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillRoundedRect", pix_ctx_fillRoundedRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillStyle", pix_ctx_fillStyle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::isPointInStroke", pix_ctx_isPointInStroke, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::isPointInPath", pix_ctx_isPointInPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::stroke", pix_ctx_stroke, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineWidth", pix_ctx_lineWidth, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::clearRect", pix_ctx_clearRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::save", pix_ctx_save, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::saveLayer", pix_ctx_saveLayer, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::restore", pix_ctx_restore, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::scale", pix_ctx_scale, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::writeFile", pix_ctx_writeFile, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::closePath", pix_ctx_closePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::beginPath", pix_ctx_beginPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::resize", pix_ctx_resize, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::arc", pix_ctx_arc, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::arcTo", pix_ctx_arcTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::bezierCurveTo", pix_ctx_bezierCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::quadraticCurveTo", pix_ctx_quadraticCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::circle", pix_ctx_circle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::clip", pix_ctx_clip, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fill", pix_ctx_fill, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::drawImage", pix_ctx_drawImage, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::ellipse", pix_ctx_ellipse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::font", pix_ctx_font, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fontSize", pix_ctx_fontSize, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillText", pix_ctx_fillText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeText", pix_ctx_strokeText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::textAlign", pix_ctx_textAlign, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::getSize", pix_ctx_getSize, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::getImage", pix_ctx_img_get, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::rotate", pix_ctx_rotate, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::setTransform", pix_ctx_setTransform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::transform", pix_ctx_transform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::translate", pix_ctx_translate, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::resetTransform", pix_ctx_resetTransform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::measureText", pix_ctx_measureText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::setLineDash", pix_ctx_setLineDash, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::globalAlpha", pix_ctx_globalAlpha, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::textBaseline", pix_ctx_textBaseline, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillPath", pix_ctx_fillPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokePath", pix_ctx_strokePath, nil, nil) == nil:
    return Tcl.ERROR

  # Commands paths :
  if Tcl.CreateObjCommand(interp, "pix::path::new", pix_path, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::addPath", pix_path_addPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::polygon", pix_path_polygon, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::moveTo", pix_path_moveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::lineTo", pix_path_lineTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::closePath", pix_path_closePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::rect", pix_path_rect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::circle", pix_path_circle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::fillOverlaps", pix_path_fillOverlaps, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::transform", pix_path_transform, nil, nil) == nil:
    return Tcl.ERROR

  # Commands image :
  if Tcl.CreateObjCommand(interp, "pix::img::new", pix_image, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::copy", pix_image_copy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fill", pix_image_fill, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::blur", pix_image_blur, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::read", pix_image_read, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fillPath", pix_image_fillpath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::draw", pix_image_draw, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fillText", pix_img_fillText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::shadow", pix_image_shadow, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::strokePath", pix_image_strokePath, nil, nil) == nil:
    return Tcl.ERROR

  # Commands paint :
  if Tcl.CreateObjCommand(interp, "pix::paint::new", pix_paint, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::gradientHandlePositions", pix_paint_gradientHandlePositions, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::gradientStops", pix_paint_gradientStops, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::dict", pix_paint_dict, nil, nil) == nil:
    return Tcl.ERROR

  # Commands font :
  if Tcl.CreateObjCommand(interp, "pix::font::read", pix_font_readFont, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::size", pix_font_size, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::color", pix_font_color, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::typeset", pix_font_typeset, nil, nil) == nil:
    return Tcl.ERROR

  # Commands svg :
  if Tcl.CreateObjCommand(interp, "pix::svg::parse", pix_svg_parse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::svg::toImage", pix_svg_toImage, nil, nil) == nil:
    return Tcl.ERROR

  # Commands pix :
  if Tcl.CreateObjCommand(interp, "pix::drawSurface", pix_draw_surface, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::colorHTMLtoRGBA", pix_colorHTMLtoRGBA, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::parsePath", pix_parsePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::toB64", pix_toB64, nil, nil) == nil:
    return Tcl.ERROR
  return Tcl.OK