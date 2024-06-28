# Copyright (c) 2024 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
# pix - Tcl wrapper around Pixie, a full-featured 2D graphics library written in Nim.
# (https://github.com/treeform/pixie)

# 03-Jun-2024 : v0.1 Initial release
# 25-Jun-2024 : v0.2
               # Add `font` namespace + test file.
               # Add `image` namespace + test file.
               # Add `paint` namespace + test file.
               # Add `path` namespace + test file.
               # Rename `pix::ctx::getSize` by `pix::ctx::get` 
               # Rename `pix::img::read` by `pix::img::readImage`
               # Rename `pix::font::read` by `pix::font::readFont`
               # Add documentation based on Pixie API reference.
               # Add binary for Linux.
               # Code refactoring.

import pixie, pixie/fileformats/svg
import std/strutils
import tables
import unicode
import std/base64
from tclpix as Tcl import nil
from tkpix  as Tk import nil
#
var imgTable   = initTable[string, Image]()
var ctxTable   = initTable[string, Context]()
var pathTable  = initTable[string, Path]()
var paintTable = initTable[string, Paint]()
var fontTable  = initTable[string, Font]()
var tFaceTable = initTable[string, Typeface]()
var arrTable   = initTable[string, Arrangement]()
var svgTable   = initTable[string, Svg]()
var spanTable  = initTable[string, Span]()

const version: cstring = "0.2"

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

  # Nim version supported.
  if NimVersion < "2.0.2":
    raise newException(OSError, 
      "pix(error): Nim version: '" & NimVersion & "' not supported."
    )
  
  # Commands context :
  if Tcl.CreateObjCommand(interp, "pix::ctx::new", pix_context, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::arc", pix_ctx_arc, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::arcTo", pix_ctx_arcTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::beginPath", pix_ctx_beginPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::bezierCurveTo", pix_ctx_bezierCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::circle", pix_ctx_circle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::clearRect", pix_ctx_clearRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::clip", pix_ctx_clip, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::closePath", pix_ctx_closePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::drawImage", pix_ctx_drawImage, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::ellipse", pix_ctx_ellipse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fill", pix_ctx_fill, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillCircle", pix_ctx_fillCircle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillEllipse", pix_ctx_fillEllipse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillPolygon", pix_ctx_fillPolygon, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillRect", pix_ctx_fillRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillRoundedRect", pix_ctx_fillRoundedRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillText", pix_ctx_fillText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::getLineDash", pix_ctx_getLineDash, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::getTransform", pix_ctx_getTransform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::isPointInPath", pix_ctx_isPointInPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::isPointInStroke", pix_ctx_isPointInStroke, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineTo", pix_ctx_lineTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::measureText", pix_ctx_measureText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::moveTo", pix_ctx_moveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::polygon", pix_ctx_polygon, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::quadraticCurveTo", pix_ctx_quadraticCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::rect", pix_ctx_rect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::resetTransform", pix_ctx_resetTransform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::restore", pix_ctx_restore, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::rotate", pix_ctx_rotate, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::roundedRect", pix_ctx_roundedRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::save", pix_ctx_save, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::saveLayer", pix_ctx_saveLayer, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::scale", pix_ctx_scale, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::setLineDash", pix_ctx_setLineDash, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::setTransform", pix_ctx_setTransform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::stroke", pix_ctx_stroke, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeCircle", pix_ctx_strokeCircle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeEllipse", pix_ctx_strokeEllipse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokePolygon", pix_ctx_strokePolygon, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeRect", pix_ctx_strokeRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeRoundedRect", pix_ctx_strokeRoundedRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeSegment", pix_ctx_strokeSegment, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeText", pix_ctx_strokeText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::transform", pix_ctx_transform, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::translate", pix_ctx_translate, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented context.
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokeStyle", pix_ctx_strokeStyle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineJoin", pix_ctx_lineJoin, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillStyle", pix_ctx_fillStyle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::lineWidth", pix_ctx_lineWidth, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::writeFile", pix_ctx_writeFile, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::font", pix_ctx_font, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fontSize", pix_ctx_fontSize, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::textAlign", pix_ctx_textAlign, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::get", pix_ctx_get, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::globalAlpha", pix_ctx_globalAlpha, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::textBaseline", pix_ctx_textBaseline, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::fillPath", pix_ctx_fillPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::strokePath", pix_ctx_strokePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::ctx::destroy", pix_ctx_destroy, nil, nil) == nil:
    return Tcl.ERROR

  # Commands paths :
  if Tcl.CreateObjCommand(interp, "pix::path::new", pix_path, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::addPath", pix_path_addPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::angleToMiterLimit", pix_path_angleToMiterLimit, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::arc", pix_path_arc, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::arcTo", pix_path_arcTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::bezierCurveTo", pix_path_bezierCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::circle", pix_path_circle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::closePath", pix_path_closePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::computeBounds", pix_path_computeBounds, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::copy", pix_path_copy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::ellipse", pix_path_ellipse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::ellipticalArcTo", pix_path_ellipticalArcTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::fillOverlaps", pix_path_fillOverlaps, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::lineTo", pix_path_lineTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::miterLimitToAngle", pix_path_miterLimitToAngle, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::moveTo", pix_path_moveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::polygon", pix_path_polygon, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::quadraticCurveTo", pix_path_quadraticCurveTo, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::rect", pix_path_rect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::roundedRect", pix_path_roundedRect, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::strokeOverlaps", pix_path_strokeOverlaps, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::path::transform", pix_path_transform, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented path.
  if Tcl.CreateObjCommand(interp, "pix::path::destroy", pix_path_destroy, nil, nil) == nil:
    return Tcl.ERROR

  # Commands image :
  if Tcl.CreateObjCommand(interp, "pix::img::new", pix_image, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::applyOpacity", pix_image_applyOpacity, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::blur", pix_image_blur, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::ceil", pix_image_ceil, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::diff", pix_image_diff, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::draw", pix_image_draw, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fill", pix_image_fill, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::flipHorizontal", pix_image_flipHorizontal, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::flipVertical", pix_image_flipVertical, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::getColor", pix_image_getColor, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::getPixel", pix_image_getPixel, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::inside", pix_image_inside, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::invert", pix_image_invert, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::isOneColor", pix_image_isOneColor, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::isOpaque", pix_image_isOpaque, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::isTransparent", pix_image_isTransparent, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::magnifyBy2", pix_image_magnifyBy2, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::minifyBy2", pix_image_minifyBy2, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::opaqueBounds", pix_image_opaqueBounds, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::resize", pix_image_resize, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::rotate90", pix_image_rotate90, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::shadow", pix_image_shadow, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::setPixel", pix_image_setPixel, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::strokeText", pix_image_strokeText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::subImage", pix_image_subImage, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::superImage", pix_image_superImage, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented image.
  if Tcl.CreateObjCommand(interp, "pix::img::copy", pix_image_copy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::readImage", pix_image_readImage, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fillPath", pix_image_fillpath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fillText", pix_image_fillText, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::strokePath", pix_image_strokePath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::get", pix_image_get, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::fillGradient", pix_image_fillGradient, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::destroy", pix_image_destroy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::img::writeFile", pix_image_writeFile, nil, nil) == nil:
    return Tcl.ERROR

  # Commands paint :
  if Tcl.CreateObjCommand(interp, "pix::paint::new", pix_paint, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::copy", pix_paint_copy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::fillGradient", pix_paint_fillGradient, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented paint.
  if Tcl.CreateObjCommand(interp, "pix::paint::configure", pix_paint_configure, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::paint::destroy", pix_paint_destroy, nil, nil) == nil:
    return Tcl.ERROR

  # Commands font :
  if Tcl.CreateObjCommand(interp, "pix::font::ascent", pix_font_ascent, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::computeBounds", pix_font_computeBounds, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::copy", pix_font_copy, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::defaultLineHeight", pix_font_defaultLineHeight, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::descent", pix_font_descent, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::fallbackTypeface", pix_font_fallbackTypeface, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::getAdvance", pix_font_getAdvance, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::getGlyphPath", pix_font_getGlyphPath, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::getKerningAdjustment", pix_font_getKerningAdjustment, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::hasGlyph", pix_font_hasGlyph, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::layoutBounds", pix_font_layoutBounds, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::lineGap", pix_font_lineGap, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::lineHeight", pix_font_lineHeight, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::name", pix_font_name, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::newFont", pix_font_newFont, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::newSpan", pix_font_newSpan, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::paint", pix_font_paint, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::parseOtf", pix_font_parseOtf, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::parseSvgFont", pix_font_parseSvgFont, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::parseTtf", pix_font_parseTtf, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::readFont", pix_font_readFont, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::readTypeface", pix_font_readTypeface, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::readTypefaces", pix_font_readTypefaces, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::scale", pix_font_scale, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::typeset", pix_font_typeset, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented font.
  if Tcl.CreateObjCommand(interp, "pix::font::configure", pix_font_configure, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::selectionRects", pix_font_selectionRects, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::size", pix_font_size, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::color", pix_font_color, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::font::destroy", pix_font_destroy, nil, nil) == nil:
    return Tcl.ERROR

  # Commands svg :
  if Tcl.CreateObjCommand(interp, "pix::svg::parse", pix_svg_parse, nil, nil) == nil:
    return Tcl.ERROR
  if Tcl.CreateObjCommand(interp, "pix::svg::newImage", pix_svg_newImage, nil, nil) == nil:
    return Tcl.ERROR
  # Undocumented svg.
  if Tcl.CreateObjCommand(interp, "pix::svg::destroy", pix_svg_destroy, nil, nil) == nil:
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