type
  SizeOp* = enum
    soNone, EQ, NE, LT, LTE, GT, GTE

  FileSizeUnit* = enum
    Bytes = "B"
    Kilobytes = "KB"
    Megabytes = "MB"
    Gigabytes = "GB"
    Terabytes = "TB"

  FSize* = ref object
    size*: float64
    unit*: FileSizeUnit
    bytes*: int64
    op*: SizeOp

proc toBytes*(size: float64, unit: FileSizeUnit = Bytes): int64 =
  case unit
  of Bytes: int64(size)
  of Kilobytes: int64(size * 1024.0)
  of Megabytes: int64(size * 1024.0 * 1024.0)
  of Gigabytes: int64(size * 1024.0 * 1024.0 * 1024.0)
  of Terabytes: int64(size * 1024.0 * 1024.0 * 1024.0 * 1024.0)

proc makeSize(size: float64, unit: FileSizeUnit): FSize =
  result = FSize(size: size, unit: unit, op: soNone)
  result.bytes = toBytes(size, unit)

proc withOp(fs: FSize, op: SizeOp): FSize =
  result = fs
  result.op = op

proc `==`*(fs: FSize): FSize = fs.withOp(EQ)
proc `!=`*(fs: FSize): FSize = fs.withOp(NE)
proc `<`*(fs: FSize): FSize = fs.withOp(LT)
proc `<=`*(fs: FSize): FSize = fs.withOp(LTE)
proc `>`*(fs: FSize): FSize = fs.withOp(GT)
proc `>=`*(fs: FSize): FSize = fs.withOp(GTE)

proc bytes*(i: int): FSize = makeSize(float64(i), Bytes)
proc bytes*(i: float): FSize = makeSize(i, Bytes)

proc kilobytes*(i: float): FSize = makeSize(i, Kilobytes)
proc megabytes*(i: float): FSize = makeSize(i, Megabytes)
proc gigabytes*(i: float): FSize = makeSize(i, Gigabytes)
proc terabytes*(i: float): FSize = makeSize(i, Terabytes)

proc kb*(i: int): FSize = kilobytes(float64(i))
proc mb*(i: int): FSize = megabytes(float64(i))
proc gb*(i: int): FSize = gigabytes(float64(i))
proc tb*(i: int): FSize = terabytes(float64(i))

proc kb*(i: float): FSize = kilobytes(i)
proc mb*(i: float): FSize = megabytes(i)
proc gb*(i: float): FSize = gigabytes(i)
proc tb*(i: float): FSize = terabytes(i)

proc KB*(i: float): FSize = kilobytes(i)
proc MB*(i: float): FSize = megabytes(i)
proc GB*(i: float): FSize = gigabytes(i)
proc TB*(i: float): FSize = terabytes(i)