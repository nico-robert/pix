type
  Resvg* = ref object
    width*, height*: cint
    pixmap*: seq[uint8]

type
  error* = enum
    RESVG_OK = 0,
    RESVG_ERROR_NOT_AN_UTF8_STR,
    RESVG_ERROR_FILE_OPEN_FAILED,
    RESVG_ERROR_MALFORMED_GZIP,
    RESVG_ERROR_ELEMENTS_LIMIT_REACHED,
    RESVG_ERROR_INVALID_SIZE,
    RESVG_ERROR_PARSING_FAILED

  image_rendering* = enum
    RESVG_IMAGE_RENDERING_OPTIMIZE_QUALITY,
    RESVG_IMAGE_RENDERING_OPTIMIZE_SPEED

  shape_rendering* = enum
    RESVG_SHAPE_RENDERING_OPTIMIZE_SPEED,
    RESVG_SHAPE_RENDERING_CRISP_EDGES,
    RESVG_SHAPE_RENDERING_GEOMETRIC_PRECISION

  text_rendering* = enum
    RESVG_TEXT_RENDERING_OPTIMIZE_SPEED,
    RESVG_TEXT_RENDERING_OPTIMIZE_LEGIBILITY,
    RESVG_TEXT_RENDERING_GEOMETRIC_PRECISION

type
  options* = object
  optionsPtr* = ptr options

  render_tree* = object
  render_treePtr* = ptr render_tree

type
  transform* {.importc: "resvg_transform", header: "resvg.h".} = object
    a*, b*, c*, d*, e*, f*: cfloat

  size* {.importc: "resvg_size", header: "resvg.h".} = object
    width*, height*: cfloat

  rect* {.importc: "resvg_rect", header: "resvg.h".} = object
    x*, y*, width*, height*: cfloat