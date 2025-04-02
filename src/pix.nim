# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

import pixie, pixie/fileformats/svg
import std/[strutils, parsecfg, streams, tables, unicode]
import core/[pixtables, pixparses, pixutils]

when defined(x11):
  import bindings/x11/binding as X

import bindings/tcl/binding as Tcl
import bindings/tk/binding  as Tk

# Source : https://stackoverflow.com/questions/57121829/get-version-from-nimble-package
const pixVersion = staticRead("../pix.nimble").newStringStream.loadConfig.getSectionValue("", "version")

include "image.nim"
include "context.nim"
include "paint.nim"
include "paths.nim"
include "surface.nim"
include "font.nim"
include "svg.nim"

proc Pix_Init(interp: Tcl.PInterp): cint {.exportc, dynlib.} =
  # Package initialization entry point.
  #
  # Returns 0 on success, 1 on failure.
  if Tcl.InitStubs(interp, Tcl.VERSION,  0) == nil:
    return Tcl.ERROR

  if Tk.InitTkStubs(interp, Tcl.VERSION, 0) == nil:
    return Tcl.ERROR

  when defined(x11):
    if Tk.InitImageType(interp) == Tcl.OK:
      Tk.CreateImageType(X.createImgType(interp))

  # Namespace
  var ns = Tcl.CreateNamespace(interp, "pix", nil, nil)
  if ns == nil:
    ns = Tcl.FindNamespace(interp, "pix", nil, 0)
    if ns == nil:
      return pixUtils.errorMSG(interp, "Can't create or find namespace 'pix'")

  # Package
  if Tcl.PkgProvideEx(interp, "pix", pixVersion.cstring, nil) != Tcl.OK:
    return Tcl.ERROR

  var commands = {
    # Context commands :
    "pix::ctx::new"               : pix_context,
    "pix::ctx::arc"               : pix_ctx_arc,
    "pix::ctx::arcTo"             : pix_ctx_arcTo,
    "pix::ctx::beginPath"         : pix_ctx_beginPath,
    "pix::ctx::bezierCurveTo"     : pix_ctx_bezierCurveTo,
    "pix::ctx::circle"            : pix_ctx_circle,
    "pix::ctx::clearRect"         : pix_ctx_clearRect,
    "pix::ctx::clip"              : pix_ctx_clip,
    "pix::ctx::closePath"         : pix_ctx_closePath,
    "pix::ctx::drawImage"         : pix_ctx_drawImage,
    "pix::ctx::ellipse"           : pix_ctx_ellipse,
    "pix::ctx::fill"              : pix_ctx_fill,
    "pix::ctx::fillCircle"        : pix_ctx_fillCircle,
    "pix::ctx::fillEllipse"       : pix_ctx_fillEllipse,
    "pix::ctx::fillPolygon"       : pix_ctx_fillPolygon,
    "pix::ctx::fillRect"          : pix_ctx_fillRect,
    "pix::ctx::fillRoundedRect"   : pix_ctx_fillRoundedRect,
    "pix::ctx::fillText"          : pix_ctx_fillText,
    "pix::ctx::getLineDash"       : pix_ctx_getLineDash,
    "pix::ctx::getTransform"      : pix_ctx_getTransform,
    "pix::ctx::isPointInPath"     : pix_ctx_isPointInPath,
    "pix::ctx::isPointInStroke"   : pix_ctx_isPointInStroke,
    "pix::ctx::lineTo"            : pix_ctx_lineTo,
    "pix::ctx::measureText"       : pix_ctx_measureText,
    "pix::ctx::moveTo"            : pix_ctx_moveTo,
    "pix::ctx::polygon"           : pix_ctx_polygon,
    "pix::ctx::quadraticCurveTo"  : pix_ctx_quadraticCurveTo,
    "pix::ctx::rect"              : pix_ctx_rect,
    "pix::ctx::resetTransform"    : pix_ctx_resetTransform,
    "pix::ctx::restore"           : pix_ctx_restore,
    "pix::ctx::rotate"            : pix_ctx_rotate,
    "pix::ctx::roundedRect"       : pix_ctx_roundedRect,
    "pix::ctx::save"              : pix_ctx_save,
    "pix::ctx::saveLayer"         : pix_ctx_saveLayer,
    "pix::ctx::scale"             : pix_ctx_scale,
    "pix::ctx::setLineDash"       : pix_ctx_setLineDash,
    "pix::ctx::setTransform"      : pix_ctx_setTransform,
    "pix::ctx::stroke"            : pix_ctx_stroke,
    "pix::ctx::strokeCircle"      : pix_ctx_strokeCircle,
    "pix::ctx::strokeEllipse"     : pix_ctx_strokeEllipse,
    "pix::ctx::strokePolygon"     : pix_ctx_strokePolygon,
    "pix::ctx::strokeRect"        : pix_ctx_strokeRect,
    "pix::ctx::strokeRoundedRect" : pix_ctx_strokeRoundedRect,
    "pix::ctx::strokeSegment"     : pix_ctx_strokeSegment,
    "pix::ctx::strokeText"        : pix_ctx_strokeText,
    "pix::ctx::transform"         : pix_ctx_transform,
    "pix::ctx::translate"         : pix_ctx_translate,
    # Undocumented context commands.
    "pix::ctx::strokeStyle"       : pix_ctx_strokeStyle,
    "pix::ctx::lineJoin"          : pix_ctx_lineJoin,
    "pix::ctx::fillStyle"         : pix_ctx_fillStyle,
    "pix::ctx::lineWidth"         : pix_ctx_lineWidth,
    "pix::ctx::writeFile"         : pix_ctx_writeFile,
    "pix::ctx::font"              : pix_ctx_font,
    "pix::ctx::fontSize"          : pix_ctx_fontSize,
    "pix::ctx::textAlign"         : pix_ctx_textAlign,
    "pix::ctx::get"               : pix_ctx_get,
    "pix::ctx::globalAlpha"       : pix_ctx_globalAlpha,
    "pix::ctx::textBaseline"      : pix_ctx_textBaseline,
    "pix::ctx::fillPath"          : pix_ctx_fillPath,
    "pix::ctx::strokePath"        : pix_ctx_strokePath,
    "pix::ctx::destroy"           : pix_ctx_destroy,

    # Path commands
    "pix::path::new"               : pix_path,
    "pix::path::addPath"           : pix_path_addPath,
    "pix::path::angleToMiterLimit" : pix_path_angleToMiterLimit,
    "pix::path::arc"               : pix_path_arc,
    "pix::path::arcTo"             : pix_path_arcTo,
    "pix::path::bezierCurveTo"     : pix_path_bezierCurveTo,
    "pix::path::circle"            : pix_path_circle,
    "pix::path::closePath"         : pix_path_closePath,
    "pix::path::computeBounds"     : pix_path_computeBounds,
    "pix::path::copy"              : pix_path_copy,
    "pix::path::ellipse"           : pix_path_ellipse,
    "pix::path::ellipticalArcTo"   : pix_path_ellipticalArcTo,
    "pix::path::fillOverlaps"      : pix_path_fillOverlaps,
    "pix::path::lineTo"            : pix_path_lineTo,
    "pix::path::miterLimitToAngle" : pix_path_miterLimitToAngle,
    "pix::path::moveTo"            : pix_path_moveTo,
    "pix::path::polygon"           : pix_path_polygon,
    "pix::path::quadraticCurveTo"  : pix_path_quadraticCurveTo,
    "pix::path::rect"              : pix_path_rect,
    "pix::path::roundedRect"       : pix_path_roundedRect,
    "pix::path::strokeOverlaps"    : pix_path_strokeOverlaps,
    "pix::path::transform"         : pix_path_transform,
    # Undocumented path commands.
    "pix::path::destroy"           : pix_path_destroy,

    # Image commands
    "pix::img::new"            : pix_image,
    "pix::img::applyOpacity"   : pix_image_applyOpacity,
    "pix::img::blur"           : pix_image_blur,
    "pix::img::ceil"           : pix_image_ceil,
    "pix::img::diff"           : pix_image_diff,
    "pix::img::draw"           : pix_image_draw,
    "pix::img::fill"           : pix_image_fill,
    "pix::img::flipHorizontal" : pix_image_flipHorizontal,
    "pix::img::flipVertical"   : pix_image_flipVertical,
    "pix::img::getColor"       : pix_image_getColor,
    "pix::img::getPixel"       : pix_image_getPixel,
    "pix::img::inside"         : pix_image_inside,
    "pix::img::invert"         : pix_image_invert,
    "pix::img::isOneColor"     : pix_image_isOneColor,
    "pix::img::isOpaque"       : pix_image_isOpaque,
    "pix::img::isTransparent"  : pix_image_isTransparent,
    "pix::img::magnifyBy2"     : pix_image_magnifyBy2,
    "pix::img::minifyBy2"      : pix_image_minifyBy2,
    "pix::img::opaqueBounds"   : pix_image_opaqueBounds,
    "pix::img::resize"         : pix_image_resize,
    "pix::img::rotate90"       : pix_image_rotate90,
    "pix::img::shadow"         : pix_image_shadow,
    "pix::img::setPixel"       : pix_image_setPixel,
    "pix::img::strokeText"     : pix_image_strokeText,
    "pix::img::subImage"       : pix_image_subImage,
    "pix::img::superImage"     : pix_image_superImage,
    # Undocumented image commands.
    "pix::img::copy"           : pix_image_copy,
    "pix::img::readImage"      : pix_image_readImage,
    "pix::img::fillPath"       : pix_image_fillpath,
    "pix::img::fillText"       : pix_image_fillText,
    "pix::img::strokePath"     : pix_image_strokePath,
    "pix::img::get"            : pix_image_get,
    "pix::img::fillGradient"   : pix_image_fillGradient,
    "pix::img::destroy"        : pix_image_destroy,
    "pix::img::writeFile"      : pix_image_writeFile,

    # Paint commands
    "pix::paint::new"          : pix_paint,
    "pix::paint::copy"         : pix_paint_copy,
    "pix::paint::fillGradient" : pix_paint_fillGradient,
    # Undocumented paint commands
    "pix::paint::configure"    : pix_paint_configure,
    "pix::paint::destroy"      : pix_paint_destroy,

    # Font commands
    "pix::font::ascent"               : pix_font_ascent,
    "pix::font::computeBounds"        : pix_font_computeBounds,
    "pix::font::copy"                 : pix_font_copy,
    "pix::font::defaultLineHeight"    : pix_font_defaultLineHeight,
    "pix::font::descent"              : pix_font_descent,
    "pix::font::fallbackTypeface"     : pix_font_fallbackTypeface,
    "pix::font::getAdvance"           : pix_font_getAdvance,
    "pix::font::getGlyphPath"         : pix_font_getGlyphPath,
    "pix::font::getKerningAdjustment" : pix_font_getKerningAdjustment,
    "pix::font::hasGlyph"             : pix_font_hasGlyph,
    "pix::font::layoutBounds"         : pix_font_layoutBounds,
    "pix::font::lineGap"              : pix_font_lineGap,
    "pix::font::lineHeight"           : pix_font_lineHeight,
    "pix::font::name"                 : pix_font_name,
    "pix::font::newFont"              : pix_font_newFont,
    "pix::font::newSpan"              : pix_font_newSpan,
    "pix::font::paint"                : pix_font_paint,
    "pix::font::parseOtf"             : pix_font_parseOtf,
    "pix::font::parseSvgFont"         : pix_font_parseSvgFont,
    "pix::font::parseTtf"             : pix_font_parseTtf,
    "pix::font::readFont"             : pix_font_readFont,
    "pix::font::readTypeface"         : pix_font_readTypeface,
    "pix::font::readTypefaces"        : pix_font_readTypefaces,
    "pix::font::scale"                : pix_font_scale,
    "pix::font::typeset"              : pix_font_typeset,
    # Undocumented font commands
    "pix::font::configure"            : pix_font_configure,
    "pix::font::selectionRects"       : pix_font_selectionRects,
    "pix::font::size"                 : pix_font_size,
    "pix::font::color"                : pix_font_color,
    "pix::font::destroy"              : pix_font_destroy,

    # SVG commands
    "pix::svg::parse"    : pix_svg_parse,
    "pix::svg::newImage" : pix_svg_newImage,
    # Undocumented svg commands
    "pix::svg::destroy"  : pix_svg_destroy,

    # General pix commands
    "pix::drawSurface"       : pix_draw_surface,
    "pix::colorHTMLtoRGBA"   : pixUtils.colorHTMLtoRGBA,
    "pix::pathObjToString"   : pixUtils.pathObjToString,
    "pix::svgStyleToPathObj" : pixUtils.svgStyleToPathObj,
    "pix::toB64"             : pixUtils.toB64,
    "pix::toBinary"          : pixUtils.toBinary,
    "pix::rotMatrix"         : pixUtils.rotMatrix,
    "pix::scaleMatrix"       : pixUtils.scaleMatrix,
    "pix::transMatrix"       : pixUtils.transMatrix,
    "pix::mulMatrix"         : pixUtils.mulMatrix,
    # ...
  }.toTable

  when defined(x11):
    commands["pix::surfXUpdate"] = X.surfXUpdate

  # Register all commands
  for cmdName, cmdProc in commands.pairs:
    if Tcl.CreateObjCommand(interp, cmdName.cstring, cmdProc, nil, nil) == nil:
      return Tcl.ERROR

  return Tcl.OK