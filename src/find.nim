# Finds files and directories based on different criteria
#
# (c) 2023 Find | MIT License
#          George Lemon | Made by Humans from OpenPeep
#          https://github.com/supranim

# https://github.com/symfony/symfony/blob/6.1/src/Symfony/Component/Finder/Finder.php#method_directories
# https://symfony.com/doc/current/components/finder.html#files-or-directories
import std/[os, osproc, tables, times, re, strutils, sequtils, math]

type
  FinderType* {.pure.} = enum
    Native, Unix, Remote

  SearchType* = enum
    SearchInFiles, SearchInDirectories

  SortType* = enum
    SortByModifiedTime, SortByChangedTime, SortByAccessedTime, SortByType, SortByName

  StreamFinder* {.pure.} = enum
    Local, FTP, S3, WebDav

  FileSizeOp* {.pure.} = enum
    EQ = "=="
    NE = "!="
    LT = "<"
    GT = ">"
    LTE = "<="
    GTE = ">="

  FileSizeUnit* {.pure.} = enum
    Bytes = "Bytes"
    Kilobytes = "KB"
    Megabytes = "MB"
    Gigabytes = "GB"
    Terabytes = "TB"

  FSize = ref object
    op: FileSizeOp
    unit: FileSizeUnit
    size: float

  FileFinder* = ref object
    path: string
    info: FileInfo

  Directory = object
    name: string
    path: string

  Results* = ref object
    sortType: SortType
    case searchType: SearchType
    of SearchInFiles:
      fileResults: OrderedTableRef[string, FileFinder]
    of SearchInDirectories:
      dirResults: OrderedTableRef[string, Directory]

  Filters* = tuple[
    isRecursive: bool,
    ignoreHiddenFiles: bool,
    ignoreUnreadableDirectories: bool,
    ignoreVCSFiles: bool,
  ]

  Criterias* = tuple[
    path: string,
    patterns, extensions: seq[string],
    regexPatterns: seq[Regex],
    size: tuple[min, max: FSize],
    bySize: bool
  ]

  Finder* = ref object
    driver: FinderType
      ## Type of Finder instance, it can be either
      ##`Native`, `Unix` or `Remote`
    streamType: StreamFinder
      ## Where to search 
    searchType: SearchType
      ## What to search, files or directories
    criteria: Criterias
    filters: Filters
    results: Results
      ## An instance of `Results`

const vcsPatterns = [".svn", "_svn", "CVS", "_darcs", ".arch-params",
                      ".monotone", ".bzr", ".git", ".hg"]

proc finder*(path = ".", driver = Native, streamType = Local,
            searchType = SearchInFiles, isRecursive = false): Finder =
  var f = Finder(driver: driver, streamType: streamType, searchType: searchType)
  f.criteria.path = path
  f.filters.isRecursive = isRecursive
  f.filters.ignoreVCSFiles = true
  result = f

proc cmd(inputCmd: string, inputArgs: openarray[string]): auto {.discardable.} =
  ## Short hand for executing shell commands via execProcess
  result = execProcess(inputCmd, args=inputArgs, options={poStdErrToStdOut, poUsePath})

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

proc size*[F: Finder](finder: F, size: int): F =
  ## Filter files or directories by given size

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

#
# Forward
#
proc getSize*(file: FileFinder): string

#
# Criteria API
# Public proc to refine your search
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

proc bytes*(i: int): FSize =
  result = FSize(size: i.toFloat, unit: Bytes)

proc kilobytes*(i: int): FSize =
  result = FSize(size: i.toFloat, unit: Kilobytes)

proc megabytes*(i: int): FSize =
  result = FSize(size: i.toFloat, unit: Megabytes)

proc gigabytes*(i: int): FSize =
  result = FSize(size: i.toFloat, unit: Gigabytes)

proc terabytes*(i: int): FSize =
  result = FSize(size: i.toFloat, unit: Terabytes)

proc size*[F: Finder](finder: F, fs: FSize): F =
  finder.criteria.size.min = fs
  finder.criteria.bySize = true
  result = finder

proc size*[F: Finder](finder: F, min, max: FSize): F =
  finder.criteria.size.min = min
  finder.criteria.size.max = max
  finder.criteria.bySize = true
  result = finder

#
# Results & Filters API
# Public procs to refine or iterate search results.
# These filters are applied after getting a Results instance.
proc size*[R: Results](res: R): R =
  ## Filter current results by size

iterator files*(res: Results): FileFinder =
  for k, f in res.fileResults.pairs:
    yield f

iterator dirs*(res: Results): Directory =
  for k, d in res.dirResults.pairs:
    yield d

proc len*(res: Results): int =
  ## Return the number of items in current `Results`.
  case res.searchType:
  of SearchInFiles:
    result = res.fileResults.len
  of SearchInDirectories:
    result = res.dirResults.len

proc count*(res: Results): int =
  ## An alias for `len`
  result = res.len

#
# FileFinder API
#

proc getInfo*(file: FileFinder): FileInfo =
  ## Returns an instance of `FileInfo`
  ## https://nim-lang.org/docs/os.html#FileInfo
  result = file.info

proc getPath*(file: FileFinder): string =
  ## Returns path on disk for given FileFinder 
  result = file.path

proc getFileSize*(file: FileFinder): BiggestInt =
  ## Returns the file size of file (in bytes)
  result = file.info.size

proc getSizeByUnit(file: FileFinder): tuple[size: float, unit: FileSizeUnit] =
  if file.getFileSize == 0:
    return
  let
    bytes = toBiggestFloat(file.getFileSize)
    i = floor log2(bytes) / log2(toFloat 1000)
    size = (bytes / pow(toFloat 1000, i))
  result = (size, FileSizeUnit(i.toInt))

proc getSize*(file: FileFinder): string =
  ## Returns the current file size of given FileFinder
  ## auto-converted to Bytes, KB, MB, GB, or TB.
  let s = file.getSizeByUnit()
  result = $(s.size) & indent($(s.unit), 1)

proc getSize*(file: FileFinder, hideSizeLabel: bool): float =
  ## Returns the current file size of given FileFinder as float value,
  ## auto-converted to Bytes, KB, MB, GB or TB, without a label
  result = file.getSizeByUnit().size

proc getLastAccessTime*(file: FileFinder): Time =
  ## Returns the file's last read or write access time
  result = file.info.lastAccessTime

proc getLastModificationTime*(file: FileFinder): Time =
  ## Returns the file's last read or write access time
  result = file.info.lastWriteTime

proc files*[F: Finder](finder: typedesc[F], ignoreHiddenFiles = true, followSymlinks = false): F =
  ## Restricts the matching to files only

proc directories*[F: Finder](finder: typedesc[F]): F =
  ## Restricts the matching to directories only

proc recursive*[F: Finder](finder: F): F =
  finder.filters.isRecursive = true
  result = finder

proc checkFileSize(finder: Finder, file: FileFinder): bool =
  let fs = file.getSizeByUnit
  if finder.criteria.size.min != nil:
    let
      min: FSize = finder.criteria.size.min
      max: FSize = finder.criteria.size.max
    return case finder.criteria.size.min.op:
              of EQ:    min.size == fs.size
              of NE:    min.size != fs.size
              of LT:    min.size < fs.size
              of LTE:   min.size <= fs.size
              of GT:    fs.size > min.size
              of GTE:   fs.size >= min.size

proc putFile(res: Results, fpath: string) =
  res.fileResults[fpath] = FileFinder(path: fpath, info: getFileInfo(fpath))

proc isHiddenFile(finder: Finder, absPath: string): bool =
  # ignore hidden files
  # TODO find a better way to check hidden files.
  result = absPath.contains("/.")

proc nativeFinder(finder: Finder) =
  var res = Results(searchType: finder.searchType)
  case finder.searchType:
  of SearchInFiles:
    res.fileResults = newOrderedTable[string, FileFinder]()
    var byExt = finder.criteria.extensions.len != 0
    if finder.filters.isRecursive:
      for dpath in walkDirRec(absolutePath(finder.criteria.path), yieldFilter = {pcDir},
                  followFilter = {pcDir}, relative = false, checkDir = false):
        discard
    else:
      if byExt:
        # Searching using ext() proc
        for pattern in finder.criteria.patterns:
          for fpath in walkFiles(absolutePath(finder.criteria.path) / pattern):
            if isHiddenFile(finder, fpath):
              continue
            let f: tuple[dir, name, ext: string] = fpath.splitFile()
            if f.ext notin finder.criteria.extensions:
              continue
            res.putFile(fpath)
      else:
        # Searching using UNIX patterns
        if finder.criteria.patterns.len != 0:
          for pattern in finder.criteria.patterns:
            for fpath in walkFiles(absolutePath(finder.criteria.path) / pattern):
              let thisFile = FileFinder(path: fpath, info: getFileInfo(fpath))
              if finder.criteria.bySize:
                if not checkFileSize(finder, thisFile):continue
              res.fileResults[fpath] = thisFile
        elif finder.criteria.regexPatterns.len != 0:
          for pattern in finder.criteria.regexPatterns:
            for fpath in walkDirRec(absolutePath(finder.criteria.path), yieldFilter = {pcFile},
                        followFilter = {pcDir}, relative = false, checkDir = false):
              let f = FileFinder(path: fpath, info: getFileInfo(fpath))
              if finder.criteria.bySize:
                if not checkFileSize(finder, f): continue
              if not re.match(fpath.extractFilename, pattern): continue
              res.putFile(fpath)
  of SearchInDirectories:
    discard
  finder.results = res

proc get*(finder: Finder): Results =
  ## Execute Finder query and return the results
  if finder.criteria.patterns.len == 0 and
      finder.criteria.regexPatterns.len == 0:
    finder.criteria.patterns = @["*"]
  case finder.driver:
    of Native: nativeFinder(finder)
    of Unix: discard
    of Remote: discard
  result = finder.results

when isMainModule:
  let res = finder("./examples/").name(re"20[\w-]+\.txt").size(> 15.bytes, < 20.bytes).get
  for f in res.files():
    echo f.getPath()
    echo f.getSize()
    # echo f.getInfo()