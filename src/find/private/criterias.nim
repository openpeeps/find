
proc name*(finder: Finder, pattern: string): Finder =
  ## Add one file name for searching
  finder.criteria.patterns.add pattern
  result = finder

proc name*(finder: Finder, pattern: Regex): Finder =
  finder.criteria.regexPatterns.add pattern
  result = finder

proc ext*(finder: Finder, fileExtension: varargs[string]): Finder =
  finder.criteria.extensions = toSeq fileExtension
  result = finder

proc ext*(finder: Finder, fileExtensions: openarray[string]): Finder =
  finder.criteria.extensions = toSeq fileExtensions
  result = finder

proc lastTimeModified*[F: Finder](finder: F, since: string): F =
  ## Search for files or directories by last modified dates.

proc lastTimeModified*[F: Finder](finder: F, startFrom, endTo: string): F =
  ## Search for files or directories by last modified dates.

proc exclude*[F: Finder](finder: F, pattern: string): F =
  ## Excludes files or directories by name or pattern

proc exists*[F: Finder](finder: F): bool = 
  ## Check if any results were found

proc ignoreUnreadableDirs*[F: Finder](finder: F): F =
  ## Tells Finder to ignore unreadable directories.

proc ignoreVCS*[F: Finder](finder: F, toIgnore: bool): F =
  ## Tell finder to ignore Version Control Systems, such as
  ## Git and Mercurial. Those files are ignored by default
  ## when looking for files and directories, but you can change
  ## this behaviour by using this proc.
  finder.filters.ignoreVCSFiles = toIgnore

proc recursive*[F: Finder](finder: F): F =
  finder.filters.isRecursive = true
  result = finder

proc isHiddenFile(finder: Finder, absPath: string): bool =
  # ignore hidden files
  # TODO find a better way to check hidden files.
  result = absPath.contains("/.")

proc `==`*[S: FSize](fs: S): S =
  fs.op = EQ
  result = fs

proc `!=`*[S: FSize](fs: S): S =
  fs.op = NE
  result = fs

proc `<`*[S: FSize](fs: S): S =
  fs.op = LT
  result = fs

proc `<=`*[S: FSize](fs: S): S =
  fs.op = LTE
  result = fs

proc `>`*[S: FSize](fs: S): S =
  fs.op = GT
  result = fs

proc `>=`*(fs: FSize): FSize =
  fs.op = GTE
  result = fs

proc toBytes(fs: FSize): float64 =
  result = case fs.unit:
    of Bytes:
      fs.size
    of Kilobytes:
      fs.size * 1000
    of Megabytes:
      fs.size * toFloat(100^3)
    of Gigabytes:
      fs.size * toFloat(1000^3)
    of Terabytes:
      fs.size * toFloat(1*10^12)

proc bytes*(i: float): FSize =
  result = FSize(size: i, unit: Bytes)
  result.bytes = i

proc kilobytes*(i: float): FSize =
  ## FSize of `i` kilobytes
  result = FSize(size: i, unit: Kilobytes)
  result.bytes = result.toBytes

proc megabytes*(i: float): FSize =
  ## FSize of `i` megabytes
  result = FSize(size: i, unit: Megabytes)
  result.bytes = result.toBytes

proc gigabytes*(i: float): FSize =
  ## FSize of `i` gigabytes
  result = FSize(size: i, unit: Gigabytes)
  result.bytes = result.toBytes

proc terabytes*(i: float): FSize =
  ## FSize of `i` terabytes
  result = FSize(size: i, unit: Terabytes)
  result.bytes = result.toBytes

proc kb*(i: int): FSize = toFloat(i).kilobytes
proc mb*(i: int): FSize = toFloat(i).megabytes
proc gb*(i: int): FSize = toFloat(i).gigabytes
proc tb*(i: int): FSize = toFloat(i).terabytes

proc kb*(i: float): FSize = i.kilobytes
proc mb*(i: float): FSize = i.megabytes
proc gb*(i: float): FSize = i.gigabytes
proc tb*(i: float): FSize = i.terabytes

proc size*[F: Finder](finder: F, fs: FSize): F =
  finder.criteria.size.min = fs
  finder.criteria.bySize = true
  result = finder

proc size*[F: Finder](finder: F, min, max: FSize): F =
  finder.criteria.size.min = min
  finder.criteria.size.max = max
  finder.criteria.bySize = true
  result = finder

proc checkFileSize(finder: Finder, file: FileFinder): bool =
  let fs = file.getFileSize.toBiggestFloat
  if finder.criteria.size.min != nil:
    let
      min: FSize = finder.criteria.size.min
      max: FSize = finder.criteria.size.max
    # if fs.unit != min.unit: return
    return
      case finder.criteria.size.min.op:
        of EQ:    fs == min.bytes
        of NE:    fs != min.bytes
        of LT:    fs < min.bytes
        of LTE:   fs <= min.bytes
        of GT:    fs > min.bytes
        of GTE:   fs >= min.bytes

proc sort*[F: Finder](finder: F, sortType: SortType): F =
  ## Sorts files and directories

proc sortByName*[F: Finder](finder: F): F =
  ## Sorts files and directories by name

proc sortByType*[F: Finder](finder: F): F =
  ## Sorts files and directories by type
  ##(directories before files), then by name

proc sortByAccessedTime*[F: Finder](finder: F): F =
  ## Sorts files and directories by the
  ## last accessed time This is the time that
  ## the file was last accessed, read or written to

proc sortByModifiedTime*[F: Finder](finder: F): F =
  ## Sorts files and directories by the last modified time