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

  GCValues*{.importc: "XGCValues", header: "X11/Xlib.h".} = object
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

  GC* = ptr GCValues
  Display*{.final.} = object

  PXExtData* = ptr XExtData
  XExtData*{.final.} = object
    number*      : cint
    next*        : PXExtData
    free_private*: proc (extension: PXExtData): cint {.cdecl.}
    private_data*: XPointer

  PVisual* = ptr Visual
  Visual*{.final.} = object
    ext_data*     : PXExtData
    visualid*     : culong
    class*        : cint
    red_mask*     : culong
    green_mask*   : culong
    blue_mask*    : culong
    bits_per_rgb* : cint
    map_entries*  : cint

  Uid* = cstring

  Screen* = object
    white_pixel*: culong    # Value white pixel
    black_pixel*: culong    # Value black pixel

  XWindowAttributes*{.importc: "XWindowAttributes", header: "X11/Xlib.h".} = object
    x*, y*                 : cint
    width*, height*        : cint
    border_width*          : cint
    depth*                 : cint
    visual*                : PVisual
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
    create_image*   : proc(display: ptr Display, visual: PVisual, depth: cuint,
                          format: cint, offset: cint, data: cstring, width: cuint,
                          height: cuint, bitmap_pad: cint, bytes_per_line: cint): PXImage {.cdecl.}
    destroy_image*  : proc(ximage: PXImage): cint {.cdecl.}
    get_pixel*      : proc(ximage: PXImage, x, y: cint): culong {.cdecl.}
    put_pixel*      : proc(ximage: PXImage, x, y: cint, pixel: culong): cint {.cdecl.}
    sub_image*      : proc(ximage: PXImage, x, y: cint, width, height: cuint): PXImage {.cdecl.}
    add_pixel*      : proc(ximage: PXImage, value: clong): cint {.cdecl.}

  PXImage* = ptr XImage
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

proc DestroyImage*(ximage: PXImage): cint {.cdecl, importc: "XDestroyImage", header: "X11/Xutil.h".} =
  return ximage.f.destroy_image(ximage)