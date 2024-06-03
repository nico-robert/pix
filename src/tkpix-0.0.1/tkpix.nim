from tclpix import PInterp, TClientData, QueuePosition, PObj, PPObj
include "private/tkpixtypes.inc"

# Generated proc vars
#####################
var FindPhoto*: proc(interp: PInterp, imageName: cstring):PhotoHandle {.cdecl.}
var PhotoGetImage*: proc(handle: PhotoHandle, blockPtr: ptr TBlock):int {.cdecl.}
var PhotoBlank*: proc(handle: PhotoHandle) {.cdecl.}
var PhotoGetSize*: proc(handle: PhotoHandle, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.}
var PhotoExpand*: proc(interp: PInterp, handle: PhotoHandle, width: int, height: int):int {.cdecl.}
var PhotoPutBlock*: proc(interp: PInterp, handle: PhotoHandle, blockPtr: ptr PhotoImageBlock, x: int, y: int, width: int, height: int, compRule: int):int {.cdecl.}
var PhotoPutZoomedBlock*: proc(interp: PInterp, handle: PhotoHandle, blockPtr: PhotoImageBlock, x: int, y: int, width: int, height: int, zoomX: int, zoomY: int, subsampleX: int, subsampleY: int, compRule: int):int {.cdecl.}
var PhotoSetSize*: proc(interp: PInterp, handle: PhotoHandle, width: int, height: int):int {.cdecl.}

# Generated stubs structure
###########################

type TkPix = object
  magic* : cint
  hooks: pointer 
  MainLoop: proc() {.cdecl.} # 0
  D3DBorderColor: proc(border: Tk_3DBorder):PXColor {.cdecl.} # 1
  D3DBorderGC: proc(tkwin: Tk_Window, border: Tk_3DBorder, which: int):GC {.cdecl.} # 2
  D3DHorizontalBevel: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, x: int, y: int, width: int, height: int, leftIn: int, rightIn: int, topBevel: int, relief: int) {.cdecl.} # 3
  D3DVerticalBevel: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, x: int, y: int, width: int, height: int, leftBevel: int, relief: int) {.cdecl.} # 4
  AddOption: proc(tkwin: Tk_Window, name: cstring, value: cstring, priority: int) {.cdecl.} # 5
  BindEvent: proc(bindingTable: Tk_BindingTable, eventPtr: PXEvent, tkwin: Tk_Window, numObjects: Size, objectPtr: Pvoid) {.cdecl.} # 6
  CanvasDrawableCoords: proc(canvas: Tk_Canvas, x: cdouble, y: cdouble, drawableXPtr: Pshort, drawableYPtr: Pshort) {.cdecl.} # 7
  CanvasEventuallyRedraw: proc(canvas: Tk_Canvas, x1: int, y1: int, x2: int, y2: int) {.cdecl.} # 8
  CanvasGetCoord: proc(interp: PInterp, canvas: Tk_Canvas, str: cstring, doublePtr: ptr cdouble):int {.cdecl.} # 9
  CanvasGetTextInfo: proc(canvas: Tk_Canvas):PTk_CanvasTextInfo {.cdecl.} # 10
  CanvasPsBitmap: proc(interp: PInterp, canvas: Tk_Canvas, bitmap: Pixmap, x: int, y: int, width: int, height: int):int {.cdecl.} # 11
  CanvasPsColor: proc(interp: PInterp, canvas: Tk_Canvas, colorPtr: PXColor):int {.cdecl.} # 12
  CanvasPsFont: proc(interp: PInterp, canvas: Tk_Canvas, font: Tk_Font):int {.cdecl.} # 13
  CanvasPsPath: proc(interp: PInterp, canvas: Tk_Canvas, coordPtr: ptr cdouble, numPoints: Size) {.cdecl.} # 14
  CanvasPsStipple: proc(interp: PInterp, canvas: Tk_Canvas, bitmap: Pixmap):int {.cdecl.} # 15
  CanvasPsY: proc(canvas: Tk_Canvas, y: cdouble):cdouble {.cdecl.} # 16
  CanvasSetStippleOrigin: proc(canvas: Tk_Canvas, gc: GC) {.cdecl.} # 17
  CanvasTagsParseProc: proc(clientData: TClientData, interp: PInterp, tkwin: Tk_Window, value: cstring, widgRec: cstring, offset: Size):int {.cdecl.} # 18
  CanvasTagsPrintProc: proc(clientData: TClientData, tkwin: Tk_Window, widgRec: cstring, offset: Size, freeProcPtr: PFreeProc):cstring {.cdecl.} # 19
  CanvasTkwin: proc(canvas: Tk_Canvas):Tk_Window {.cdecl.} # 20
  CanvasWindowCoords: proc(canvas: Tk_Canvas, x: cdouble, y: cdouble, screenXPtr: Pshort, screenYPtr: Pshort) {.cdecl.} # 21
  ChangeWindowAttributes: proc(tkwin: Tk_Window, valueMask: culong, attsPtr: PXSetWindowAttributes) {.cdecl.} # 22
  CharBbox: proc(layout: Tk_TextLayout, index: Size, xPtr: ptr cint, yPtr: ptr cint, widthPtr: ptr cint, heightPtr: ptr cint):int {.cdecl.} # 23
  ClearSelection: proc(tkwin: Tk_Window, selection: Atom) {.cdecl.} # 24
  ClipboardAppend: proc(interp: PInterp, tkwin: Tk_Window, target: Atom, format: Atom, buffer: cstring):int {.cdecl.} # 25
  ClipboardClear: proc(interp: PInterp, tkwin: Tk_Window):int {.cdecl.} # 26
  ConfigureInfo: proc(interp: PInterp, tkwin: Tk_Window, specs: PTk_ConfigSpec, widgRec: pointer, argvName: cstring, flags: int):int {.cdecl.} # 27
  ConfigureValue: proc(interp: PInterp, tkwin: Tk_Window, specs: PTk_ConfigSpec, widgRec: pointer, argvName: cstring, flags: int):int {.cdecl.} # 28
  ConfigureWidget: proc(interp: PInterp, tkwin: Tk_Window, specs: PTk_ConfigSpec, objc: Size, objv: PObj, widgRec: pointer, flags: int):int {.cdecl.} # 29
  ConfigureWindow: proc(tkwin: Tk_Window, valueMask: uint, valuePtr: PXWindowChanges) {.cdecl.} # 30
  ComputeTextLayout: proc(font: Tk_Font, str: cstring, numChars: Size, wrapLength: int, justify: Tk_Justify, flags: int, widthPtr: ptr cint, heightPtr: ptr cint):Tk_TextLayout {.cdecl.} # 31
  CoordsToWindow: proc(rootX: int, rootY: int, tkwin: Tk_Window):Tk_Window {.cdecl.} # 32
  CreateBinding: proc(interp: PInterp, bindingTable: Tk_BindingTable, obj: pointer, eventStr: cstring, script: cstring, append: int):culong {.cdecl.} # 33
  CreateBindingTable: proc(interp: PInterp):Tk_BindingTable {.cdecl.} # 34
  CreateErrorHandler: proc(display: PDisplay, errNum: int, request: int, minorCode: int, errorProc: PTk_ErrorProc, clientData: TClientData):Tk_ErrorHandler {.cdecl.} # 35
  CreateEventHandler: proc(token: Tk_Window, mask: culong, callback: PTk_EventProc, clientData: TClientData) {.cdecl.} # 36
  CreateGenericHandler: proc(callback: PTk_GenericProc, clientData: TClientData) {.cdecl.} # 37
  CreateImageType: proc(typePtr: PTk_ImageType) {.cdecl.} # 38
  CreateItemType: proc(typePtr: PTk_ItemType) {.cdecl.} # 39
  CreatePhotoImageFormat: proc(formatPtr: PTk_PhotoImageFormat) {.cdecl.} # 40
  CreateSelHandler: proc(tkwin: Tk_Window, selection: Atom, target: Atom, callback: PTk_SelectionProc, clientData: TClientData, format: Atom) {.cdecl.} # 41
  CreateWindow: proc(interp: PInterp, parent: Tk_Window, name: cstring, screenName: cstring):Tk_Window {.cdecl.} # 42
  CreateWindowFromPath: proc(interp: PInterp, tkwin: Tk_Window, pathName: cstring, screenName: cstring):Tk_Window {.cdecl.} # 43
  DefineBitmap: proc(interp: PInterp, name: cstring, source: pointer, width: int, height: int):int {.cdecl.} # 44
  DefineCursor: proc(window: Tk_Window, cursor: Tk_Cursor) {.cdecl.} # 45
  DeleteAllBindings: proc(bindingTable: Tk_BindingTable, obj: pointer) {.cdecl.} # 46
  DeleteBinding: proc(interp: PInterp, bindingTable: Tk_BindingTable, obj: pointer, eventStr: cstring):int {.cdecl.} # 47
  DeleteBindingTable: proc(bindingTable: Tk_BindingTable) {.cdecl.} # 48
  DeleteErrorHandler: proc(handler: Tk_ErrorHandler) {.cdecl.} # 49
  DeleteEventHandler: proc(token: Tk_Window, mask: culong, callback: PTk_EventProc, clientData: TClientData) {.cdecl.} # 50
  DeleteGenericHandler: proc(callback: PTk_GenericProc, clientData: TClientData) {.cdecl.} # 51
  DeleteImage: proc(interp: PInterp, name: cstring) {.cdecl.} # 52
  DeleteSelHandler: proc(tkwin: Tk_Window, selection: Atom, target: Atom) {.cdecl.} # 53
  DestroyWindow: proc(tkwin: Tk_Window) {.cdecl.} # 54
  DisplayName: proc(tkwin: Tk_Window):cstring {.cdecl.} # 55
  DistanceToTextLayout: proc(layout: Tk_TextLayout, x: int, y: int):int {.cdecl.} # 56
  Draw3DPolygon: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, pointPtr: PXPoint, numPoints: Size, borderWidth: int, leftRelief: int) {.cdecl.} # 57
  Draw3DRectangle: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, x: int, y: int, width: int, height: int, borderWidth: int, relief: int) {.cdecl.} # 58
  DrawChars: proc(display: PDisplay, drawable: Drawable, gc: GC, tkfont: Tk_Font, source: cstring, numBytes: Size, x: int, y: int) {.cdecl.} # 59
  DrawFocusHighlight: proc(tkwin: Tk_Window, gc: GC, width: int, drawable: Drawable) {.cdecl.} # 60
  DrawTextLayout: proc(display: PDisplay, drawable: Drawable, gc: GC, layout: Tk_TextLayout, x: int, y: int, firstChar: Size, lastChar: Size) {.cdecl.} # 61
  Fill3DPolygon: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, pointPtr: PXPoint, numPoints: Size, borderWidth: int, leftRelief: int) {.cdecl.} # 62
  Fill3DRectangle: proc(tkwin: Tk_Window, drawable: Drawable, border: Tk_3DBorder, x: int, y: int, width: int, height: int, borderWidth: int, relief: int) {.cdecl.} # 63
  FindPhoto: proc(interp: PInterp, imageName: cstring):PhotoHandle {.cdecl.} # 64
  FontId: proc(font: Tk_Font):Font {.cdecl.} # 65
  Free3DBorder: proc(border: Tk_3DBorder) {.cdecl.} # 66
  FreeBitmap: proc(display: PDisplay, bitmap: Pixmap) {.cdecl.} # 67
  FreeColor: proc(colorPtr: PXColor) {.cdecl.} # 68
  FreeColormap: proc(display: PDisplay, colormap: Colormap) {.cdecl.} # 69
  FreeCursor: proc(display: PDisplay, cursor: Tk_Cursor) {.cdecl.} # 70
  FreeFont: proc(f: Tk_Font) {.cdecl.} # 71
  FreeGC: proc(display: PDisplay, gc: GC) {.cdecl.} # 72
  FreeImage: proc(image: Tk_Image) {.cdecl.} # 73
  FreeOptions: proc(specs: PTk_ConfigSpec, widgRec: pointer, display: PDisplay, needFlags: int) {.cdecl.} # 74
  FreePixmap: proc(display: PDisplay, pixmap: Pixmap) {.cdecl.} # 75
  FreeTextLayout: proc(textLayout: Tk_TextLayout) {.cdecl.} # 76
  Reserved77 : pointer # 77
  GCForColor: proc(colorPtr: PXColor, drawable: Drawable):GC {.cdecl.} # 78
  GeometryRequest: proc(tkwin: Tk_Window, reqWidth: int, reqHeight: int) {.cdecl.} # 79
  Get3DBorder: proc(interp: PInterp, tkwin: Tk_Window, colorName: Tk_Uid):Tk_3DBorder {.cdecl.} # 80
  GetAllBindings: proc(interp: PInterp, bindingTable: Tk_BindingTable, obj: pointer) {.cdecl.} # 81
  GetAnchor: proc(interp: PInterp, str: cstring, anchorPtr: PTk_Anchor):int {.cdecl.} # 82
  GetAtomName: proc(tkwin: Tk_Window, atom: Atom):cstring {.cdecl.} # 83
  GetBinding: proc(interp: PInterp, bindingTable: Tk_BindingTable, obj: pointer, eventStr: cstring):cstring {.cdecl.} # 84
  GetBitmap: proc(interp: PInterp, tkwin: Tk_Window, str: cstring):Pixmap {.cdecl.} # 85
  GetBitmapFromData: proc(interp: PInterp, tkwin: Tk_Window, source: pointer, width: int, height: int):Pixmap {.cdecl.} # 86
  GetCapStyle: proc(interp: PInterp, str: cstring, capPtr: ptr cint):int {.cdecl.} # 87
  GetColor: proc(interp: PInterp, tkwin: Tk_Window, name: Tk_Uid):PXColor {.cdecl.} # 88
  GetColorByValue: proc(tkwin: Tk_Window, colorPtr: PXColor):PXColor {.cdecl.} # 89
  GetColormap: proc(interp: PInterp, tkwin: Tk_Window, str: cstring):Colormap {.cdecl.} # 90
  GetCursor: proc(interp: PInterp, tkwin: Tk_Window, str: Tk_Uid):Tk_Cursor {.cdecl.} # 91
  GetCursorFromData: proc(interp: PInterp, tkwin: Tk_Window, source: cstring, mask: cstring, width: int, height: int, xHot: int, yHot: int, fg: Tk_Uid, bg: Tk_Uid):Tk_Cursor {.cdecl.} # 92
  GetFont: proc(interp: PInterp, tkwin: Tk_Window, str: cstring):Tk_Font {.cdecl.} # 93
  GetFontFromObj: proc(tkwin: Tk_Window, objPtr: PObj):Tk_Font {.cdecl.} # 94
  GetFontMetrics: proc(font: Tk_Font, fmPtr: PTk_FontMetrics) {.cdecl.} # 95
  GetGC: proc(tkwin: Tk_Window, valueMask: culong, valuePtr: PXGCValues):GC {.cdecl.} # 96
  GetImage: proc(interp: PInterp, tkwin: Tk_Window, name: cstring, changeProc: PTk_ImageChangedProc, clientData: TClientData):Tk_Image {.cdecl.} # 97
  GetImageModelData: proc(interp: PInterp, name: cstring, typePtrPtr: PTk_ImageType):pointer {.cdecl.} # 98
  GetItemTypes: proc():PTk_ItemType {.cdecl.} # 99
  GetJoinStyle: proc(interp: PInterp, str: cstring, joinPtr: ptr cint):int {.cdecl.} # 100
  GetJustify: proc(interp: PInterp, str: cstring, justifyPtr: PTk_Justify):int {.cdecl.} # 101
  GetNumMainWindows: proc():int {.cdecl.} # 102
  GetOption: proc(tkwin: Tk_Window, name: cstring, className: cstring):Tk_Uid {.cdecl.} # 103
  GetPixels: proc(interp: PInterp, tkwin: Tk_Window, str: cstring, intPtr: ptr cint):int {.cdecl.} # 104
  GetPixmap: proc(display: PDisplay, d: Drawable, width: int, height: int, depth: int):Pixmap {.cdecl.} # 105
  GetRelief: proc(interp: PInterp, name: cstring, reliefPtr: ptr cint):int {.cdecl.} # 106
  GetRootCoords: proc(tkwin: Tk_Window, xPtr: ptr cint, yPtr: ptr cint) {.cdecl.} # 107
  GetScrollInfo: proc(interp: PInterp, argc: Size, argv: ptr cstring, dblPtr: ptr cdouble, intPtr: ptr cint):int {.cdecl.} # 108
  GetScreenMM: proc(interp: PInterp, tkwin: Tk_Window, str: cstring, doublePtr: ptr cdouble):int {.cdecl.} # 109
  GetSelection: proc(interp: PInterp, tkwin: Tk_Window, selection: Atom, target: Atom, callback: PTk_GetSelProc, clientData: TClientData):int {.cdecl.} # 110
  GetUid: proc(str: cstring):Tk_Uid {.cdecl.} # 111
  GetVisual: proc(interp: PInterp, tkwin: Tk_Window, str: cstring, depthPtr: ptr cint, colormapPtr: PColormap):PVisual {.cdecl.} # 112
  GetVRootGeometry: proc(tkwin: Tk_Window, xPtr: ptr cint, yPtr: ptr cint, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 113
  Grab: proc(interp: PInterp, tkwin: Tk_Window, grabGlobal: int):int {.cdecl.} # 114
  HandleEvent: proc(eventPtr: PXEvent) {.cdecl.} # 115
  IdToWindow: proc(display: PDisplay, window: Window):Tk_Window {.cdecl.} # 116
  ImageChanged: proc(model: Tk_ImageModel, x: int, y: int, width: int, height: int, imageWidth: int, imageHeight: int) {.cdecl.} # 117
  erved118 : pointer # 118
  InternAtom: proc(tkwin: Tk_Window, name: cstring):Atom {.cdecl.} # 119
  IntersectTextLayout: proc(layout: Tk_TextLayout, x: int, y: int, width: int, height: int):int {.cdecl.} # 120
  MaintainGeometry: proc(window: Tk_Window, container: Tk_Window, x: int, y: int, width: int, height: int) {.cdecl.} # 121
  MainWindow: proc(interp: PInterp):Tk_Window {.cdecl.} # 122
  MakeWindowExist: proc(tkwin: Tk_Window) {.cdecl.} # 123
  ManageGeometry: proc(tkwin: Tk_Window, mgrPtr: PTk_GeomMgr, clientData: TClientData) {.cdecl.} # 124
  MapWindow: proc(tkwin: Tk_Window) {.cdecl.} # 125
  MeasureChars: proc(tkfont: Tk_Font, source: cstring, numBytes: Size, maxPixels: int, flags: int, lengthPtr: ptr cint):int {.cdecl.} # 126
  MoveResizeWindow: proc(tkwin: Tk_Window, x: int, y: int, width: int, height: int) {.cdecl.} # 127
  MoveWindow: proc(tkwin: Tk_Window, x: int, y: int) {.cdecl.} # 128
  MoveToplevelWindow: proc(tkwin: Tk_Window, x: int, y: int) {.cdecl.} # 129
  NameOf3DBorder: proc(border: Tk_3DBorder):cstring {.cdecl.} # 130
  NameOfAnchor: proc(anchor: Tk_Anchor):cstring {.cdecl.} # 131
  NameOfBitmap: proc(display: PDisplay, bitmap: Pixmap):cstring {.cdecl.} # 132
  NameOfCapStyle: proc(cap: int):cstring {.cdecl.} # 133
  NameOfColor: proc(colorPtr: PXColor):cstring {.cdecl.} # 134
  NameOfCursor: proc(display: PDisplay, cursor: Tk_Cursor):cstring {.cdecl.} # 135
  NameOfFont: proc(font: Tk_Font):cstring {.cdecl.} # 136
  NameOfImage: proc(model: Tk_ImageModel):cstring {.cdecl.} # 137
  NameOfJoinStyle: proc(join: int):cstring {.cdecl.} # 138
  NameOfJustify: proc(justify: Tk_Justify):cstring {.cdecl.} # 139
  NameOfRelief: proc(relief: int):cstring {.cdecl.} # 140
  NameToWindow: proc(interp: PInterp, pathName: cstring, tkwin: Tk_Window):Tk_Window {.cdecl.} # 141
  OwnSelection: proc(tkwin: Tk_Window, selection: Atom, callback: PTk_LostSelProc, clientData: TClientData) {.cdecl.} # 142
  ParseArgv: proc(interp: PInterp, tkwin: Tk_Window, argcPtr: ptr cint, argv: ptr cstring, argTable: PTk_ArgvInfo, flags: int):int {.cdecl.} # 143
  Reserved144 : pointer # 144
  Reserved145 : pointer # 145
  PhotoGetImage: proc(handle: PhotoHandle, blockPtr: ptr TBlock):int {.cdecl.} # 146
  PhotoBlank: proc(handle: PhotoHandle) {.cdecl.} # 147
  Reserved148 : pointer # 148
  PhotoGetSize: proc(handle: PhotoHandle, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 149
  Reserved150 : pointer # 150
  PointToChar: proc(layout: Tk_TextLayout, x: int, y: int):int {.cdecl.} # 151
  PostscriptFontName: proc(tkfont: Tk_Font, dsPtr: PDString):int {.cdecl.} # 152
  PreserveColormap: proc(display: PDisplay, colormap: Colormap) {.cdecl.} # 153
  QueueWindowEvent: proc(eventPtr: PXEvent, position: QueuePosition) {.cdecl.} # 154
  RedrawImage: proc(image: Tk_Image, imageX: int, imageY: int, width: int, height: int, drawable: Drawable, drawableX: int, drawableY: int) {.cdecl.} # 155
  ResizeWindow: proc(tkwin: Tk_Window, width: int, height: int) {.cdecl.} # 156
  RestackWindow: proc(tkwin: Tk_Window, aboveBelow: int, other: Tk_Window):int {.cdecl.} # 157
  RestrictEvents: proc(callback: PTk_RestrictProc, arg: pointer, prevArgPtr: Pvoid):PTk_RestrictProc {.cdecl.} # 158
  Reserved159 : pointer # 159
  SetAppName: proc(tkwin: Tk_Window, name: cstring):cstring {.cdecl.} # 160
  SetBackgroundFromBorder: proc(tkwin: Tk_Window, border: Tk_3DBorder) {.cdecl.} # 161
  SetClass: proc(tkwin: Tk_Window, className: cstring) {.cdecl.} # 162
  SetGrid: proc(tkwin: Tk_Window, reqWidth: int, reqHeight: int, gridWidth: int, gridHeight: int) {.cdecl.} # 163
  SetInternalBorder: proc(tkwin: Tk_Window, width: int) {.cdecl.} # 164
  SetWindowBackground: proc(tkwin: Tk_Window, pixel: culong) {.cdecl.} # 165
  SetWindowBackgroundPixmap: proc(tkwin: Tk_Window, pixmap: Pixmap) {.cdecl.} # 166
  SetWindowBorder: proc(tkwin: Tk_Window, pixel: culong) {.cdecl.} # 167
  SetWindowBorderWidth: proc(tkwin: Tk_Window, width: int) {.cdecl.} # 168
  SetWindowBorderPixmap: proc(tkwin: Tk_Window, pixmap: Pixmap) {.cdecl.} # 169
  SetWindowColormap: proc(tkwin: Tk_Window, colormap: Colormap) {.cdecl.} # 170
  SetWindowVisual: proc(tkwin: Tk_Window, visual: PVisual, depth: int, colormap: Colormap):int {.cdecl.} # 171
  SizeOfBitmap: proc(display: PDisplay, bitmap: Pixmap, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 172
  SizeOfImage: proc(image: Tk_Image, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 173
  StrictMotif: proc(tkwin: Tk_Window):int {.cdecl.} # 174
  TextLayoutToPostscript: proc(interp: PInterp, layout: Tk_TextLayout) {.cdecl.} # 175
  TextWidth: proc(font: Tk_Font, str: cstring, numBytes: Size):int {.cdecl.} # 176
  UndefineCursor: proc(window: Tk_Window) {.cdecl.} # 177
  UnderlineChars: proc(display: PDisplay, drawable: Drawable, gc: GC, tkfont: Tk_Font, source: cstring, x: int, y: int, firstByte: Size, lastByte: Size) {.cdecl.} # 178
  UnderlineTextLayout: proc(display: PDisplay, drawable: Drawable, gc: GC, layout: Tk_TextLayout, x: int, y: int, underline: int) {.cdecl.} # 179
  Ungrab: proc(tkwin: Tk_Window) {.cdecl.} # 180
  UnmaintainGeometry: proc(window: Tk_Window, container: Tk_Window) {.cdecl.} # 181
  UnmapWindow: proc(tkwin: Tk_Window) {.cdecl.} # 182
  UnsetGrid: proc(tkwin: Tk_Window) {.cdecl.} # 183
  UpdatePointer: proc(tkwin: Tk_Window, x: int, y: int, state: int) {.cdecl.} # 184
  AllocBitmapFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj):Pixmap {.cdecl.} # 185
  Alloc3DBorderFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj):Tk_3DBorder {.cdecl.} # 186
  AllocColorFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj):PXColor {.cdecl.} # 187
  AllocCursorFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj):Tk_Cursor {.cdecl.} # 188
  AllocFontFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj):Tk_Font {.cdecl.} # 189
  CreateOptionTable: proc(interp: PInterp, templatePtr: PTk_OptionSpec):Tk_OptionTable {.cdecl.} # 190
  DeleteOptionTable: proc(optionTable: Tk_OptionTable) {.cdecl.} # 191
  Free3DBorderFromObj: proc(tkwin: Tk_Window, objPtr: PObj) {.cdecl.} # 192
  FreeBitmapFromObj: proc(tkwin: Tk_Window, objPtr: PObj) {.cdecl.} # 193
  FreeColorFromObj: proc(tkwin: Tk_Window, objPtr: PObj) {.cdecl.} # 194
  FreeConfigOptions: proc(recordPtr: pointer, optionToken: Tk_OptionTable, tkwin: Tk_Window) {.cdecl.} # 195
  FreeSavedOptions: proc(savePtr: PTk_SavedOptions) {.cdecl.} # 196
  FreeCursorFromObj: proc(tkwin: Tk_Window, objPtr: PObj) {.cdecl.} # 197
  FreeFontFromObj: proc(tkwin: Tk_Window, objPtr: PObj) {.cdecl.} # 198
  Get3DBorderFromObj: proc(tkwin: Tk_Window, objPtr: PObj):Tk_3DBorder {.cdecl.} # 199
  GetAnchorFromObj: proc(interp: PInterp, objPtr: PObj, anchorPtr: PTk_Anchor):int {.cdecl.} # 200
  GetBitmapFromObj: proc(tkwin: Tk_Window, objPtr: PObj):Pixmap {.cdecl.} # 201
  GetColorFromObj: proc(tkwin: Tk_Window, objPtr: PObj):PXColor {.cdecl.} # 202
  GetCursorFromObj: proc(tkwin: Tk_Window, objPtr: PObj):Tk_Cursor {.cdecl.} # 203
  GetOptionInfo: proc(interp: PInterp, recordPtr: pointer, optionTable: Tk_OptionTable, namePtr: PObj, tkwin: Tk_Window):PObj {.cdecl.} # 204
  GetOptionValue: proc(interp: PInterp, recordPtr: pointer, optionTable: Tk_OptionTable, namePtr: PObj, tkwin: Tk_Window):PObj {.cdecl.} # 205
  GetJustifyFromObj: proc(interp: PInterp, objPtr: PObj, justifyPtr: PTk_Justify):int {.cdecl.} # 206
  GetMMFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj, doublePtr: ptr cdouble):int {.cdecl.} # 207
  GetPixelsFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj, intPtr: ptr cint):int {.cdecl.} # 208
  GetReliefFromObj: proc(interp: PInterp, objPtr: PObj, resultPtr: ptr cint):int {.cdecl.} # 209
  GetScrollInfoObj: proc(interp: PInterp, objc: Size, objv: PPObj, dblPtr: ptr cdouble, intPtr: ptr cint):int {.cdecl.} # 210
  InitOptions: proc(interp: PInterp, recordPtr: pointer, optionToken: Tk_OptionTable, tkwin: Tk_Window):int {.cdecl.} # 211
  Reserved212 : pointer # 212
  RestoreSavedOptions: proc(savePtr: PTk_SavedOptions) {.cdecl.} # 213
  SetOptions: proc(interp: PInterp, recordPtr: pointer, optionTable: Tk_OptionTable, objc: Size, objv: PPObj, tkwin: Tk_Window, savePtr: PTk_SavedOptions, maskPtr: ptr cint):int {.cdecl.} # 214
  InitConsoleChannels: proc(interp: PInterp) {.cdecl.} # 215
  Reserved216 : pointer # 216
  CreateSmoothMethod: proc(interp: PInterp, meth: PTk_SmoothMethod) {.cdecl.} # 217
  Reserved218 : pointer # 218
  Reserved219 : pointer # 219
  GetDash: proc(interp: PInterp, value: cstring, dash: PTk_Dash):int {.cdecl.} # 220
  CreateOutline: proc(outline: PTk_Outline) {.cdecl.} # 221
  DeleteOutline: proc(display: PDisplay, outline: PTk_Outline) {.cdecl.} # 222
  ConfigOutlineGC: proc(gcValues: PXGCValues, canvas: Tk_Canvas, item: PTk_Item, outline: PTk_Outline):int {.cdecl.} # 223
  ChangeOutlineGC: proc(canvas: Tk_Canvas, item: PTk_Item, outline: PTk_Outline):int {.cdecl.} # 224
  ResetOutlineGC: proc(canvas: Tk_Canvas, item: PTk_Item, outline: PTk_Outline):int {.cdecl.} # 225
  CanvasPsOutline: proc(canvas: Tk_Canvas, item: PTk_Item, outline: PTk_Outline):int {.cdecl.} # 226
  SetTSOrigin: proc(tkwin: Tk_Window, gc: GC, x: int, y: int) {.cdecl.} # 227
  CanvasGetCoordFromObj: proc(interp: PInterp, canvas: Tk_Canvas, obj: PObj, doublePtr: ptr cdouble):int {.cdecl.} # 228
  CanvasSetOffset: proc(canvas: Tk_Canvas, gc: GC, offset: PTk_TSOffset) {.cdecl.} # 229
  DitherPhoto: proc(handle: PhotoHandle, x: int, y: int, width: int, height: int) {.cdecl.} # 230
  PostscriptBitmap: proc(interp: PInterp, tkwin: Tk_Window, psInfo: Tk_PostscriptInfo, bitmap: Pixmap, startX: int, startY: int, width: int, height: int):int {.cdecl.} # 231
  PostscriptColor: proc(interp: PInterp, psInfo: Tk_PostscriptInfo, colorPtr: PXColor):int {.cdecl.} # 232
  PostscriptFont: proc(interp: PInterp, psInfo: Tk_PostscriptInfo, font: Tk_Font):int {.cdecl.} # 233
  PostscriptImage: proc(image: Tk_Image, interp: PInterp, tkwin: Tk_Window, psinfo: Tk_PostscriptInfo, x: int, y: int, width: int, height: int, prepass: int):int {.cdecl.} # 234
  PostscriptPath: proc(interp: PInterp, psInfo: Tk_PostscriptInfo, coordPtr: ptr cdouble, numPoints: Size) {.cdecl.} # 235
  PostscriptStipple: proc(interp: PInterp, tkwin: Tk_Window, psInfo: Tk_PostscriptInfo, bitmap: Pixmap):int {.cdecl.} # 236
  PostscriptY: proc(y: cdouble, psInfo: Tk_PostscriptInfo):cdouble {.cdecl.} # 237
  PostscriptPhoto: proc(interp: PInterp, blockPtr: PhotoImageBlock, psInfo: Tk_PostscriptInfo, width: int, height: int):int {.cdecl.} # 238
  CreateClientMessageHandler: proc(callback: PTk_ClientMessageProc) {.cdecl.} # 239
  DeleteClientMessageHandler: proc(callback: PTk_ClientMessageProc) {.cdecl.} # 240
  CreateAnonymousWindow: proc(interp: PInterp, parent: Tk_Window, screenName: cstring):Tk_Window {.cdecl.} # 241
  SetClassProcs: proc(tkwin: Tk_Window, procs: PTk_ClassProcs, instanceData: pointer) {.cdecl.} # 242
  SetInternalBorderEx: proc(tkwin: Tk_Window, left: int, right: int, top: int, bottom: int) {.cdecl.} # 243
  SetMinimumRequestSize: proc(tkwin: Tk_Window, minWidth: int, minHeight: int) {.cdecl.} # 244
  SetCaretPos: proc(tkwin: Tk_Window, x: int, y: int, height: int) {.cdecl.} # 245
  Reserved246 : pointer # 246
  Reserved247 : pointer # 247
  CollapseMotionEvents: proc(display: PDisplay, collapse: int):int {.cdecl.} # 248
  RegisterStyleEngine: proc(name: cstring, parent: Tk_StyleEngine):Tk_StyleEngine {.cdecl.} # 249
  GetStyleEngine: proc(name: cstring):Tk_StyleEngine {.cdecl.} # 250
  RegisterStyledElement: proc(engine: Tk_StyleEngine, templatePtr: PTk_ElementSpec):int {.cdecl.} # 251
  GetElementId: proc(name: cstring):int {.cdecl.} # 252
  CreateStyle: proc(name: cstring, engine: Tk_StyleEngine, clientData: TClientData):Tk_Style {.cdecl.} # 253
  GetStyle: proc(interp: PInterp, name: cstring):Tk_Style {.cdecl.} # 254
  FreeStyle: proc(style: Tk_Style) {.cdecl.} # 255
  NameOfStyle: proc(style: Tk_Style):cstring {.cdecl.} # 256
  AllocStyleFromObj: proc(interp: PInterp, objPtr: PObj):Tk_Style {.cdecl.} # 257
  Reserved258 : pointer # 258
  Reserved259 : pointer # 259
  GetStyledElement: proc(style: Tk_Style, elementId: Size, optionTable: Tk_OptionTable):Tk_StyledElement {.cdecl.} # 260
  GetElementSize: proc(style: Tk_Style, element: Tk_StyledElement, recordPtr: pointer, tkwin: Tk_Window, width: int, height: int, inner: int, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 261
  GetElementBox: proc(style: Tk_Style, element: Tk_StyledElement, recordPtr: pointer, tkwin: Tk_Window, x: int, y: int, width: int, height: int, inner: int, xPtr: ptr cint, yPtr: ptr cint, widthPtr: ptr cint, heightPtr: ptr cint) {.cdecl.} # 262
  GetElementBorderWidth: proc(style: Tk_Style, element: Tk_StyledElement, recordPtr: pointer, tkwin: Tk_Window):int {.cdecl.} # 263
  DrawElement: proc(style: Tk_Style, element: Tk_StyledElement, recordPtr: pointer, tkwin: Tk_Window, d: Drawable, x: int, y: int, width: int, height: int, state: int) {.cdecl.} # 264
  PhotoExpand: proc(interp: PInterp, handle: PhotoHandle, width: int, height: int):int {.cdecl.} # 265
  PhotoPutBlock: proc(interp: PInterp, handle: PhotoHandle, blockPtr: ptr PhotoImageBlock, x: int, y: int, width: int, height: int, compRule: int):int {.cdecl.} # 266
  PhotoPutZoomedBlock: proc(interp: PInterp, handle: PhotoHandle, blockPtr: PhotoImageBlock, x: int, y: int, width: int, height: int, zoomX: int, zoomY: int, subsampleX: int, subsampleY: int, compRule: int):int {.cdecl.} # 267
  PhotoSetSize: proc(interp: PInterp, handle: PhotoHandle, width: int, height: int):int {.cdecl.} # 268
  GetUserInactiveTime: proc(dpy: PDisplay):clong {.cdecl.} # 269
  ResetUserInactiveTime: proc(dpy: PDisplay) {.cdecl.} # 270
  Interp: proc(tkwin: Tk_Window):PInterp {.cdecl.} # 271
  Reserved272 : pointer # 272
  Reserved273 : pointer # 273
  AlwaysShowSelection: proc(tkwin: Tk_Window):int {.cdecl.} # 274
  GetButtonMask: proc(button: uint32):uint32 {.cdecl.} # 275
  GetDoublePixelsFromObj: proc(interp: PInterp, tkwin: Tk_Window, objPtr: PObj, doublePtr: ptr cdouble):int {.cdecl.} # 276
  NewWindowObj: proc(tkwin: Tk_Window):PObj {.cdecl.} # 277
  SendVirtualEvent: proc(tkwin: Tk_Window, eventName: cstring, detail: PObj) {.cdecl.} # 278
  FontGetDescription: proc(tkfont: Tk_Font):PObj {.cdecl.} # 279
  CreatePhotoImageFormatVersion3: proc(formatPtr: PTk_PhotoImageFormatVersion3) {.cdecl.} # 280
  DrawHighlightBorder: proc(tkwin: Tk_Window, fgGC: GC, bgGC: GC, highlightWidth: int, drawable: Drawable) {.cdecl.} # 281
  SetMainMenubar: proc(interp: PInterp, tkwin: Tk_Window, menuName: cstring) {.cdecl.} # 282
  SetWindowMenubar: proc(interp: PInterp, tkwin: Tk_Window, oldMenuName: cstring, menuName: cstring) {.cdecl.} # 283
  ClipDrawableToRect: proc(display: PDisplay, d: Drawable, x: int, y: int, width: int, height: int) {.cdecl.} # 284
  GetSystemDefault: proc(tkwin: Tk_Window, dbName: cstring, className: cstring):PObj {.cdecl.} # 285
  UseWindow: proc(interp: PInterp, tkwin: Tk_Window, string: cstring):int {.cdecl.} # 286
  MakeContainer: proc(tkwin: Tk_Window) {.cdecl.} # 287
  GetOtherWindow: proc(tkwin: Tk_Window):Tk_Window {.cdecl.} # 288
  Get3DBorderColors: proc(border: Tk_3DBorder, bgColorPtr: PXColor, darkColorPtr: PXColor, lightColorPtr: PXColor) {.cdecl.} # 289
  MakeWindow: proc(tkwin: Tk_Window, parent: Window):Window {.cdecl.} # 290
  AttachHWND: proc(tkwin: Tk_Window, hwnd: HWND):Window {.cdecl.} # 0
  GetHINSTANCE: proc():HINSTANCE {.cdecl.} # 1
  GetHWND: proc(window: Window):HWND {.cdecl.} # 2
  HWNDToWindow: proc(hwnd: HWND):Tk_Window {.cdecl.} # 3
  MacOSXInitAppleEvents: proc(interp: PInterp) {.cdecl.} # 4
  MacOSXInvalClipRgns: proc(tkwin: Tk_Window) {.cdecl.} # 6
  MacOSXGetRootControl: proc(drawable: Drawable):pointer {.cdecl.} # 8
  MacOSXSetupTkNotifier: proc() {.cdecl.} # 9
  MacOSXIsAppInFront: proc():int {.cdecl.} # 10
  MacOSXGetTkWindow: proc(w: pointer):Tk_Window {.cdecl.} # 11
  MacOSXGetCGContextForDrawable: proc(drawable: Drawable):pointer {.cdecl.} # 12
  MacOSXGetNSWindowForDrawable: proc(drawable: Drawable):pointer {.cdecl.} # 13
  GenWMConfigureEvent: proc(tkwin: Tk_Window, x: int, y: int, width: int, height: int, flags: int) {.cdecl.} # 16


# Generated init proc
####################

var tkPixPtr{.importc: "tkStubsPtr".} : ptr TkPix 
proc tkPixInit(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl, importc: "Tk_InitStubs".}

proc InitStubs*(interp: PInterp, version: cstring, exact: cint): cstring {.cdecl.} =
  result = tkPixInit(interp, version, exact)
  FindPhoto = tkPixPtr.FindPhoto
  PhotoGetImage = tkPixPtr.PhotoGetImage
  PhotoBlank = tkPixPtr.PhotoBlank
  PhotoGetSize = tkPixPtr.PhotoGetSize
  PhotoExpand = tkPixPtr.PhotoExpand
  PhotoPutBlock = tkPixPtr.PhotoPutBlock
  PhotoPutZoomedBlock = tkPixPtr.PhotoPutZoomedBlock
  PhotoSetSize = tkPixPtr.PhotoSetSize
  return result 