# Copyright (c) 2024-2025 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details

const GXcopy* = 0x3.cint  # src

const 
  GCFunction*          = 1'u32 shl 0
  GCPlaneMask*         = 1'u32 shl 1
  GCForeground*        = 1'u32 shl 2
  GCBackground*        = 1'u32 shl 3
  GCGraphicsExposures* = 1'u32 shl 16

# Constants from X.h that might be needed
const
  LSBFirst* = 0
  MSBFirst* = 1
  XYBitmap* = 0  # depth 1, XYFormat
  XYPixmap* = 1  # depth == drawable depth
  ZPixmap*  = 2  # depth == drawable depth

when defined(windows):
  when defined(cpu64):
    type
      XID = culonglong
      Drawable* = XID
      Pixmap* = XID
  else:
    type
      XID = culong
      Drawable* = XID
      Pixmap* = XID
else:
  type
    XID = culong
    Drawable* = XID
    Pixmap* = XID

# X11 types declarations first
type
  XPointer* = ptr char
  Color*{.importc: "XColor", header: "X11/Xlib.h".} = object
    pixel*  : culong
    red*    : cushort
    green*  : cushort
    blue*   : cushort
    flags*  : cchar
    pad*    : cchar

  XGCValues*{.importc: "XGCValues", header: "X11/Xlib.h".} = object
    function*           : cint
    plane_mask*         : culong
    foreground*         : culong
    background*         : culong
    line_width*         : cint
    line_style*         : cint
    cap_style*          : cint
    join_style*         : cint
    fill_style*         : cint
    fill_rule*          : cint
    arc_mode*           : cint
    tile*               : Pixmap
    stipple*            : Pixmap
    ts_x_origin*        : cint
    ts_y_origin*        : cint
    font*               : culong
    subwindow_mode*     : cint
    graphics_exposures* : bool
    clip_x_origin*      : cint
    clip_y_origin*      : cint
    clip_mask*          : Pixmap
    dash_offset*        : cint
    dashes*             : cchar

  GC* = ptr XGCValues
  Display*{.final.} = object

# Remaining X11 types
type
  Visual*{.final.} = object
    visualid*     : culong
    class*        : cint
    red_mask*     : culong
    green_mask*   : culong
    blue_mask*    : culong
    bits_per_rgb* : cint
    map_entries*  : cint

  Uid* = cstring

type
  XVisual = object  # Forward declaration 
  
  Screen* = object
    white_pixel*: culong    # Value white pixel
    black_pixel*: culong    # Value black pixel

  XWindowAttributes*{.importc: "XWindowAttributes", header: "X11/Xlib.h".} = object
    x*, y*                 : cint
    width*, height*        : cint
    border_width*          : cint
    depth*                 : cint
    visual*                : ptr XVisual
    root*                  : culong
    class*                 : cint
    bit_gravity*           : cint
    win_gravity*           : cint
    backing_store*         : cint
    backing_planes*        : culong
    backing_pixel*         : culong
    save_under*            : cint
    colormap*              : culong
    map_installed*         : cint
    map_state*             : cint
    all_event_masks*       : clong
    your_event_mask*       : clong
    do_not_propagate_mask* : clong
    override_redirect*     : cint
    screen*                : ptr Screen

  XImageFuncs* = object
    create_image*   : proc(display: ptr Display, visual: ptr Visual, depth: cuint,
                          format: cint, offset: cint, data: cstring, width: cuint,
                          height: cuint, bitmap_pad: cint, bytes_per_line: cint): ImagePtr {.cdecl.}
    destroy_image*  : proc(ximage: ImagePtr): cint {.cdecl.}
    get_pixel*      : proc(ximage: ImagePtr, x, y: cint): culong {.cdecl.}
    put_pixel*      : proc(ximage: ImagePtr, x, y: cint, pixel: culong): cint {.cdecl.}
    sub_image*      : proc(ximage: ImagePtr, x, y: cint, width, height: cuint): ImagePtr {.cdecl.}
    add_pixel*      : proc(ximage: ImagePtr, value: clong): cint {.cdecl.}

  ImagePtr* = ptr XImage
  XImage*{.importc: "XImage", header: "X11/Xlib.h".} = object
    width*           : cint
    height*          : cint
    xoffset*         : cint
    format*          : cint
    data*            : cstring
    byte_order*      : cint
    bitmap_unit*     : cint
    bitmap_bit_order*: cint
    bitmap_pad*      : cint
    depth*           : cint
    bytes_per_line*  : cint
    bits_per_pixel*  : cint
    red_mask*        : culong
    green_mask*      : culong
    blue_mask*       : culong
    obdata*          : XPointer
    f*               : XImageFuncs

type
  TXCreateImage*         = proc(display: ptr Display, v: ptr Visual, ui1: cuint, i1: cint, i2: cint, cp: cstring, ui2: cuint, ui3: cuint, i3: cint, i4: cint): ImagePtr {.cdecl.}
  TXCreateGC*            = proc(display: ptr Display, d: Drawable, valueMask: culong, valuePtr: var XGCValues): GC {.cdecl.}
  TXPutImage*            = proc(display: ptr Display, dr: Drawable, gc: GC, im: ImagePtr, sx: cint, sy: cint, dx: cint, dy: cint, w: cuint, h: cuint): cint {.cdecl.}
  TPutImage*             = proc(colors: ptr culong, ncolors: cint, display: ptr Display, d: Drawable, gc: GC, image: ptr XImage, src_x: cint, src_y: cint, dest_x: cint, dest_y: cint, width: cuint, height: cuint): cint {.cdecl.}
  TXFlush*               = proc(display: ptr Display): cint {.cdecl.}
  TXSetBackground*       = proc(display: ptr Display, gc: GC, bg: culong): cint {.cdecl.}
  TXSetForeground*       = proc(display: ptr Display, gc: GC, fg: culong): cint {.cdecl.}
  TXSetClipMask*         = proc(display: ptr Display, gc: GC, pixmap: Pixmap): cint {.cdecl.}
  TXGetWindowAttributes* = proc(display: ptr Display, w: culong, x: var XWindowAttributes): cint {.cdecl.}
  TXFillRectangle*       = proc(display: ptr Display, dr: Drawable, gc: GC, x: cint, y: cint, width: cuint, height: cuint): cint {.cdecl.}
  TXCopyArea*            = proc(display: ptr Display, dr1: Drawable, dr2: Drawable, gc: GC, i1: cint, i2: cint, ui1: cuint, ui2: cuint, i3: cint, i4: cint): cint {.cdecl.}

var
  XCreateImage*          : TXCreateImage
  XCreateGC*             : TXCreateGC
  XPutImage*             : TXPutImage
  XFillRectangle*        : TXFillRectangle
  XFlush*                : TXFlush
  XSetBackground*        : TXSetBackground
  XSetForeground*        : TXSetForeground
  XSetClipMask*          : TXSetClipMask
  XCopyArea*             : TXCopyArea
  XGetWindowAttributes*  : TXGetWindowAttributes
  TkPutImage*            : TPutImage

type TkIntXlibStubs* = object
  xCreateImage*          : TXCreateImage
  xCreateGC*             : TXCreateGC
  xPutImage*             : TXPutImage
  xFlush*                : TXFlush
  xSetBackground*        : TXSetBackground
  xSetForeground*        : TXSetForeground
  xCopyArea*             : TXCopyArea
  xFillRectangle*        : TXFillRectangle
  xSetClipMask*          : TXSetClipMask
  tkPutImage*            : TPutImage

proc XDestroyImage*(ximage: ImagePtr): cint {.cdecl, importc: "XDestroyImage", header: "X11/Xutil.h".} =
  return ximage.f.destroy_image(ximage)