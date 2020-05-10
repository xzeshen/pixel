import streams, strutils, strformat, bio


## PNM consists three formats: PPM
## .. code-block:: Text
##   P3
##   # example.ppm
##   4 4
##   15
##    0  0  0    0  0  0    0  0  0   15  0 15
##    0  0  0    0 15  7    0  0  0    0  0  0
##    0  0  0    0  0  0    0 15  7    0  0  0
##   15  0 15    0  0  0    0  0  0    0  0  0
## 
## Materials:
##   http://paulbourke.net/dataformats/ppm/


type
  ## P1 - Portable Bit Map(plain).
  ## P2 - Portable Gray Map(plain).
  ## P3 - Portable Pixel Map(plain).
  ## P4 - Portable Bit Map(binary).
  ## P5 - Portable Gray Map(binary).
  ## P6 - Portable Pixel Map(binary).
  PNMKind* = enum
    P1, P2, P3, P4, P5, P6

  PNMHeaders* = object
    kind: PNMKind
    width, height: Natural
    maxVal: uint16 # The maximum color value

  PNM* = object
    headers: PNMHeaders
    data: seq[uint16]

  InvalidPNMError* = object of CatchableError ## Invalid PNM format.


proc skipComment(strm: Stream) {.inline.} =
  ## Skips comments and whitespace.
  while strm.peekChar in Whitespace:
    discard strm.readChar
    if strm.atEnd:
      raise newException(InvalidPNMError, "Invalid PNM format.")

  while strm.peekChar == '#':
    while not strm.atEnd and strm.readChar != '\n':
      continue

    while strm.peekChar in Whitespace:
      discard strm.readChar
      if strm.atEnd:
        raise newException(InvalidPNMError, "Invalid PNM format.")

proc readPNMNumber(strm: Stream): int {.inline.} =
  ## Reads width, height and maxVal.
  var s = ""

  while not strm.atEnd and strm.peekChar notin Whitespace:
    s.add strm.readChar

  if s.len != 0:
    try:
      result = parseInt(s)
    except ValueError:
      raise newException(InvalidPNMError, "Invalid PNM format.")
  else:
    raise newException(InvalidPNMError, "Invalid PNM format.")

proc readPNMHeader*(strm: Stream): PNMHeaders =
  ## Reads PNM headers.
  let magicNumber = strm.readStr(2)
  case magicNumber
  of "P1":
    result.kind = P1
  of "P2":
    result.kind = P2
  of "P3":
    result.kind = P3
  of "P4":
    result.kind = P4
  of "P5":
    result.kind = P5
  of "P6":
    result.kind = P6
  else:
    raise newException(InvalidPNMError, "Invalid PNM format.")

  strm.skipComment()

  result.width = strm.readPNMNumber

  strm.skipComment()

  result.height = strm.readPNMNumber

  strm.skipComment()

  case result.kind
  of P2, P3, P5, P6:
    result.maxVal = uint16(strm.readPNMNumber)
    strm.skipComment()
  else:
    result.maxVal = 1'u16

proc readPNM*(strm: Stream): PNM =
  ## Reads PNM.
  result.headers = strm.readPNMHeader
  
  case result.headers.kind
  of P1, P2, P3:
    let size = result.headers.width * result.headers.height * 3
    result.data = newSeq[uint16](size)
    for idx in 0 ..< size:
      result.data[idx] = uint16(strm.readPNMNumber)
      while not strm.atEnd and strm.peekChar in Whitespace:
        discard strm.readChar
  else:
    let size = result.headers.width * result.headers.width * 3
    result.data = newSeq[uint16](size)
    if result.headers.maxVal > 255:
      for idx in 0 ..< size:
        result.data[idx] = strm.readLEUint16
    else:
      for idx in 0 ..< size:
        result.data[idx] = strm.readLEUint8

proc readPNM*(src: string): PNM {.inline.} =
  let strm = newFileStream(src, fmRead)
  result = strm.readPNM

proc alignPNMData(s: string, count: Natural): string {.inline.} =
  ## Aligns PNM Data.
  if s.len < count:
    result = newString(count + 1)
    let start = count - s.len
    for idx in 0 ..< start:
      result[idx] = ' '
    for idx in start ..< count:
      result[idx] = s[idx - start]
    result[^1] = ' '
  else:
    result = s & ' '

proc writePNMData(strm: Stream, width, height: Natural, maxVal: uint16, data: openArray[uint16]) =
  ## Writes PNM Data.
  let 
    size = ($maxVal).len
    width = width.int
    realWidth = width * 3 

  for row in 0 ..< height.int:
    let rowPos = row * realWidth
    for idx in 0 ..< 3:
      let pos = width * idx
      for col in pos ..< pos + width:
        strm.write alignPNMData($(data[rowPos + col]), size)
      if idx != 2:
        strm.write "  "
    if row != height - 1:
      strm.write '\n'

proc writePNMBinary(strm: Stream, maxVal: uint16, data: openArray[uint16]) {.inline.} =
  ## Write PBM(binary version).
  if maxVal > 255:
    for i in data:
      strm.write i
  else:
    for i in data:
      strm.write byte(i)

proc write*(strm: Stream, width, height: Natural, maxVal: uint16, data: openArray[uint16], kind: PNMKind) =
  ## Writes PNM.
  assert width * height * 3 == data.len

  case kind
  of P2, P3, P5, P6:
    strm.writeLine fmt"{kind} {width} {height} {maxVal}"
  else:
    strm.writeLine fmt"{kind} {width} {height}"

  case kind
  of P1, P2, P3:
    strm.writePNMData(width, height, maxVal, data)
  of P4, P5, P6:
    strm.writePNMBinary(maxVal, data)

proc write*(strm: Stream, pnm: PNM) {.inline.} =
  ## Writes PNM.
  strm.write(pnm.headers.width, pnm.headers.height, pnm.headers.maxVal, 
             pnm.data, pnm.headers.kind)

proc write*(dest: string, pnm: PNM) {.inline.} =
  ## Writes PNM.
  let strm = newFileStream(dest, fmWrite)
  write(strm, pnm)

proc writePPM*(strm: Stream, width, height: Natural, maxVal: uint16, 
               data: openArray[uint16], binary = true) {.inline.} =
  ## Writes PPM.
  strm.write(width, height, maxVal, data, binary)

proc writePGM*(strm: Stream, width, height: Natural, maxVal: uint16, 
               data: openArray[uint16], binary = true) {.inline.} =
  ## Writes PGM.
  strm.write(width, height, maxVal, data, binary)

proc writePBM*(strm: Stream, width, height: Natural, 
               data: openArray[uint16], binary = true) {.inline.} =
  ## Writes PBM.
  strm.write(width, height, 0'u16, data, binary)


when isMainModule:
  import random

  randomize(1314)

  block:
    let 
      strm = newFileStream("test.ppm", fmWrite)
      maxVal = 355'u16
      width = 4
      height = 4
      realWidth = width * 3

    var
      data = newSeq[uint16](4 * 4 * 3)

    for row in 0 ..< height:
      let pos = row * realWidth
      for col in 0 ..< realWidth:
        data[pos + col] = uint16(rand(0 ..< maxVal.int))

    write(strm, width, height, maxVal, data, kind = P6)
    strm.close()

  block:
    let
      strm = newFileStream("test.ppm", fmRead)

    echo strm.readPNM()
