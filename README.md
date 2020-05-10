
# API: pixel

```nim
import pixel
```

## **type** PNMKind


```nim
PNMKind = enum
 P1, P2, P3, P4, P5, P6
```

## **type** PNMHeaders


```nim
PNMHeaders = object
 kind: PNMKind
 width, height: Natural
 maxVal: uint16
```

## **type** PNM


```nim
PNM = object
 headers: PNMHeaders
 data: seq[uint16]
```

## **type** InvalidPNMError

Invalid PNM format.

```nim
InvalidPNMError = object of CatchableError
```

## **proc** readPNMHeader

Reads PNM headers.

```nim
proc readPNMHeader(strm: Stream): PNMHeaders {.raises: [Defect, IOError, OSError, InvalidPNMError, ValueError], tags: [ReadIOEffect].}
```

## **proc** readPNM

Reads PNM.

```nim
proc readPNM(strm: Stream): PNM {.raises: [Defect, IOError, OSError, InvalidPNMError, ValueError], tags: [ReadIOEffect].}
```

## **proc** readPNM


```nim
proc readPNM(src: string): PNM {.inline, raises: [Defect, IOError, OSError, InvalidPNMError, ValueError], tags: [ReadIOEffect].}
```

## **proc** write

Writes PNM.

```nim
proc write(strm: Stream; width, height: Natural; maxVal: uint16;
 data: openArray[uint16]; kind: PNMKind) {.raises: [Defect, IOError, OSError, ValueError], tags: [WriteIOEffect].}
```

## **proc** write

Writes PNM.

```nim
proc write(strm: Stream; pnm: PNM) {.inline, raises: [Defect, IOError, OSError, ValueError], tags: [WriteIOEffect].}
```

## **proc** write

Writes PNM.

```nim
proc write(dest: string; pnm: PNM) {.inline, raises: [Defect, IOError, OSError, ValueError], tags: [WriteIOEffect].}
```

## **proc** writePPM

Writes PPM.

```nim
proc writePPM(strm: Stream; width, height: Natural; maxVal: uint16;
 data: openArray[uint16]; binary = true) {.inline, raises: [Defect, IOError, OSError], tags: [WriteIOEffect].}
```

## **proc** writePGM

Writes PGM.

```nim
proc writePGM(strm: Stream; width, height: Natural; maxVal: uint16;
 data: openArray[uint16]; binary = true) {.inline, raises: [Defect, IOError, OSError], tags: [WriteIOEffect].}
```

## **proc** writePBM

Writes PBM.

```nim
proc writePBM(strm: Stream; width, height: Natural; data: openArray[uint16];
 binary = true) {.inline, raises: [Defect, IOError, OSError], tags: [WriteIOEffect].}
```
