# Copyright (c) 2026 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.

# The only module that reads or writes private fields of pixie, through
# std/importutils, with the pix commands built on them.
import pixie
import std/[importutils, tables, strutils]
import ./[pixtables, pixutils]
import ../bindings/tcl/binding as Tcl

proc isClipped*(ctx: pixie.Context): bool =
  # Tells whether a clipping mask is active on the context.
  #
  # ctx - The context.
  #
  # Returns: true when a clip has been set since the last restore.
  privateAccess(pixie.Context)

  return ctx.mask != nil

proc clipMask*(ctx: pixie.Context): pixie.Image =
  # Gets the clipping mask of the context.
  #
  # ctx - The context.
  #
  # Returns: The mask image (canvas size), or nil without a clip.
  privateAccess(pixie.Context)

  return ctx.mask

proc hasLayer*(ctx: pixie.Context): bool =
  # Tells whether the context draws into a layer (saveLayer).
  #
  # ctx - The context.
  #
  # Returns: true inside a saveLayer.
  privateAccess(pixie.Context)

  return ctx.layer != nil

proc currentPath*(ctx: pixie.Context): pixie.Path =
  # Gets the current path of the context (beginPath, moveTo, rect...).
  #
  # ctx - The context.
  #
  # Returns: The path object of the context itself (not a copy).
  privateAccess(pixie.Context)

  return ctx.path

proc lineDash*(ctx: pixie.Context): seq[float32] =
  # Gets the dash pattern of the context.
  #
  # ctx - The context.
  #
  # Returns: The dash lengths, empty for a solid line.
  privateAccess(pixie.Context)

  return ctx.lineDash

proc pix_ctx_fontCached*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Sets font for current context, like [ctx::font], reading each font
  # file once for all contexts.
  #
  # context  - [ctx]
  # filePath - string
  #
  # pixie keeps its typefaces per context: with [ctx::font], every new
  # context reads and parses the font file again at its first text.
  #
  # Returns: Nothing.
  if objc != 3:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> filePath")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.load(interp, objv[1], pixie.Context)
  if ctx.isNil: return Tcl.ERROR

  let filePath = $objv[2]
  ctx.font = filePath

  if not ptable.ctxFontTable.hasKey(filePath):
    try:
      ptable.ctxFontTable[filePath] = readTypeface(filePath)
    except PixieError:
      # Unreadable font: pixie reports the error when the font is used.
      return Tcl.OK

  # 'typefaces' is private: the typeface read once is shared under the
  # path pixie looks up.
  privateAccess(pixie.Context)
  ctx.typefaces[filePath] = ptable.ctxFontTable[filePath]

  return Tcl.OK

proc pix_ctx_isClipped*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Tells whether a clipping region is active on the context.
  #
  # context - [ctx]
  #
  # A clip set with [ctx::clip] stays active until the [ctx::restore]
  # matching the [ctx::save] that preceded it.
  #
  # Returns: 1 when a clipping region is active, 0 otherwise.
  if objc != 2:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx>")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.load(interp, objv[1], pixie.Context)
  if ctx.isNil: return Tcl.ERROR

  Tcl.SetObjResult(interp, Tcl.NewIntObj(ctx.isClipped().cint))

  return Tcl.OK

proc drawInBounds(
  ctx: pixie.Context,
  bounds: Rect,
  paint: pixie.Paint,
  drawShape: proc (target: pixie.Image, paint: pixie.Paint, transform: Mat3) {.closure, gcsafe.}
) =
  # Draws a shape working on its bounds only.
  #
  # ctx       - The context, without layer or global alpha.
  # bounds    - The shape bounds in image pixels.
  # paint     - The paint of the shape.
  # drawShape - Fills or strokes the shape onto target, with the given paint
  #             and transform.
  #
  # pixie draws a clipped shape into a canvas-size layer, masks the whole
  # layer and draws it back; a gradient or image paint is also painted over
  # the whole canvas, then masked by the shape. The same steps run here on
  # an image of the shape bounds: the pixels outside are unchanged.
  #
  # Returns: Nothing.
  let
    x0 = max(0, floor(bounds.x).int - 1)
    y0 = max(0, floor(bounds.y).int - 1)
    x1 = min(ctx.image.width, ceil(bounds.x + bounds.w).int + 1)
    y1 = min(ctx.image.height, ceil(bounds.y + bounds.h).int + 1)

  if x1 <= x0 or y1 <= y0:
    return

  # Under the bounds, a mask fully open draws the shape as without clip,
  # a mask fully closed hides it: only a shape across the clip edge needs
  # the bounds image. A solid paint without clip is drawn directly.
  let mask = ctx.clipMask()
  if mask != nil:
    var
      fullyOpen = true
      fullyClosed = true
    block scan:
      for y in y0 ..< y1:
        for x in x0 ..< x1:
          let a = mask.data[mask.dataIndex(x, y)].a
          if a != 255: fullyOpen = false
          if a != 0: fullyClosed = false
          if not fullyOpen and not fullyClosed:
            break scan

    if fullyClosed:
      return
    # (A blend mode other than normal applies to the layer, not the image.)
    if fullyOpen and paint.blendMode == NormalBlend and paint.kind == SolidPaint:
      drawShape(ctx.image, paint, ctx.getTransform())
      return

  let
    offset = vec2(x0.float32, y0.float32)
    shift = translate(-offset)

  # Gradient handles and image matrices are in image space: they follow the
  # bounds image.
  var moved = paint
  if paint.kind != SolidPaint:
    moved = paint.copy()
    moved.imageMat = shift * paint.imageMat
    for p in moved.gradientHandlePositions.mitems:
      p = p - offset

  let sub = newImage(x1 - x0, y1 - y0)
  drawShape(sub, moved, shift * ctx.getTransform())
  if mask != nil:
    sub.draw(mask, shift, MaskBlend)
  ctx.image.draw(sub, translate(offset))

proc boundedDraw(ctx: pixie.Context, paint: pixie.Paint): bool =
  # Tells whether a draw on the context gains by working on the shape bounds.
  #
  # ctx   - The context.
  # paint - The paint of the shape.
  #
  # Inside a layer, or with a global alpha, pixie stacks layers whose masks
  # cannot be reproduced on the bounds alone: the context draws itself. A
  # solid paint without clip is drawn by pixie on its bounds already. A blend
  # mode other than normal applies to the canvas, not to the bounds image.
  #
  # Returns: true under a clip, or for a gradient or image paint in normal
  #          blend; never inside a layer or with a global alpha.
  if ctx.hasLayer() or ctx.globalAlpha != 1:
    return false
  if ctx.isClipped():
    return true

  return paint.kind != SolidPaint and paint.blendMode == NormalBlend

proc pix_ctx_fillBounded*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Fills the path with the current fillStyle, like [ctx::fill], faster
  # under a clipping region or with a gradient or image paint.
  #
  # context     - [ctx]
  # path        - [path] (optional)
  # windingRule - Enum value (optional:NonZero)
  #
  # Under a clip, [ctx::fill] masks and redraws a layer of the whole image
  # for every shape, and paints a gradient or image paint over the whole
  # image; this command does it on the shape bounds only, with the same
  # pixels. Otherwise (solid color without clip, inside a layer or with a
  # global alpha), it is [ctx::fill].
  #
  # Returns: Nothing.
  if objc notin (2..4):
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>? ?enum=WindingRule?")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.load(interp, objv[1], pixie.Context)
  if ctx.isNil: return Tcl.ERROR

  try:
    var
      path = ctx.currentPath()
      windingRule = NonZero

    if objc == 3:
      # Path or enum
      let arg2 = $objv[2]
      if ptable.has(arg2, pixie.Path):
        path = ptable.get(arg2, pixie.Path)
      else:
        windingRule = parseEnum[WindingRule](arg2)
    elif objc == 4:
      # Path + Enum
      path = ptable.load(interp, objv[2], pixie.Path)
      if path.isNil: return Tcl.ERROR
      windingRule = parseEnum[WindingRule]($objv[3])

    if not ctx.boundedDraw(ctx.fillStyle):
      ctx.fill(path, windingRule)
    else:
      let rule = windingRule
      ctx.drawInBounds(path.computeBounds(ctx.getTransform()), ctx.fillStyle,
        proc (target: pixie.Image, paint: pixie.Paint, transform: Mat3) {.closure, gcsafe.} =
          target.fillPath(path, paint, transform, rule)
      )
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK

proc pix_ctx_strokeBounded*(clientData: Tcl.TClientData, interp: Tcl.PInterp, objc: cint, objv: Tcl.PPObj): cint {.cdecl.} =
  # Strokes the path with the current strokeStyle, like [ctx::stroke],
  # faster under a clipping region or with a gradient or image paint.
  #
  # context - [ctx]
  # path    - [path] (optional)
  #
  # Under a clip, [ctx::stroke] masks and redraws a layer of the whole image
  # for every shape, and paints a gradient or image paint over the whole
  # image; this command does it on the shape bounds only, with the same
  # pixels. Otherwise (solid color without clip, inside a layer or with a
  # global alpha), it is [ctx::stroke].
  #
  # Returns: Nothing.
  if objc notin [2, 3]:
    Tcl.WrongNumArgs(interp, 1, objv, "<ctx> ?<path>?")
    return Tcl.ERROR

  # Context
  let ptable = cast[PixTable](clientData)
  let ctx = ptable.load(interp, objv[1], pixie.Context)
  if ctx.isNil: return Tcl.ERROR

  try:
    var path = ctx.currentPath()
    if objc == 3:
      path = ptable.load(interp, objv[2], pixie.Path)
      if path.isNil: return Tcl.ERROR

    if not ctx.boundedDraw(ctx.strokeStyle):
      ctx.stroke(path)
    else:
      let
        mat = ctx.getTransform()
        scale = max(vec2(mat[0, 0], mat[0, 1]).length, vec2(mat[1, 0], mat[1, 1]).length)
        dashes = ctx.lineDash()
        lineWidth = ctx.lineWidth
        lineCap = ctx.lineCap
        lineJoin = ctx.lineJoin
        miterLimit = ctx.miterLimit
      # The stroke reaches past the path by half its width, more at miter
      # joins and square caps.
      var reach = 1.0.float32
      if lineJoin == MiterJoin: reach = max(reach, miterLimit)
      if lineCap == SquareCap: reach = max(reach, sqrt(2.0).float32)
      let
        pad = lineWidth / 2 * scale * reach
        b = path.computeBounds(mat)
      ctx.drawInBounds(rect(b.x - pad, b.y - pad, b.w + 2 * pad, b.h + 2 * pad),
        ctx.strokeStyle,
        proc (target: pixie.Image, paint: pixie.Paint, transform: Mat3) {.closure, gcsafe.} =
          target.strokePath(path, paint, transform, lineWidth,
            lineCap, lineJoin, miterLimit, dashes)
      )
  except CatchableError as e:
    return pixUtils.errorMSG(interp, "pix(error): " & e.msg)

  return Tcl.OK
