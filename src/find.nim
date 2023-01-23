# Supranim is a simple MVC-style web framework for building
# fast web applications, REST API microservices and other cool things.
#
# (c) 2021 Supranim is released under MIT License
#          George Lemon | Made by Humans from OpenPeep
#          https://supranim.com   |    https://github.com/supranim

# https://github.com/symfony/symfony/blob/6.1/src/Symfony/Component/Finder/Finder.php#method_directories
# https://symfony.com/doc/current/components/finder.html#files-or-directories
import std/[os, osproc, tables, times, strutils, sequtils, math]

type
  FinderType* {.pure.} = enum
    Native, Unix, Remote

  SearchType* = enum
    SearchInFiles, SearchInDirectories

  SortType* = enum
    SortByModifiedTime, SortByChangedTime, SortByAccessedTime, SortByType, SortByName

  StreamFinder* {.pure.} = enum
    Local, FTP, S3, WebDav

  File* = ref object
    path: string
    info: FileInfo

  Directory = object
    name: string
    path: string

  Results* = ref object
    sortType: SortType
    case searchType: SearchType
    of SearchInFiles:
      fileResults: OrderedTableRef[string, File]
    of SearchInDirectories:
      dirResults: OrderedTableRef[string, Directory]

  Filters* = tuple[
    path: string,
    isRecursive: bool,
    ignoreHiddenFiles: bool,
    ignoreUnreadableDirectories: bool,
    ignoreVCSFiles: bool,
    extensions: seq[string]
  ]

  Finder* = ref object
    driver: FinderType
      ## Type of Finder instance, it can be either
      ##`Native`, `Unix` or `Remote`
    streamType: StreamFinder
      ## Where to search 
    searchType: SearchType
      ## What to search, files or directories
    filters: Filters
      ## Filters for current Finder instance
    results: Results
      ## Holds an instance of `Results`
    total: int
      ## Holds total results

const vcsPatterns = [".svn", "_svn", "CVS", "_darcs",
                    ".arch-params", ".monotone", ".bzr", ".git", ".hg"]

proc finder*(path = ".", driver = Native, streamType = Local,
            searchType = SearchInFiles, isRecursive = false): Finder =
  var f = Finder(driver: driver, streamType: streamType, searchType: searchType)
  # setup filters
  f.filters.path = path
  f.filters.isRecursive = isRecursive
  f.filters.ignoreVCSFiles = true
  result = f

proc cmd(inputCmd: string, inputArgs: openarray[string]): auto {.discardable.} =
  ## Short hand for executing shell commands via execProcess
  result = execProcess(inputCmd, args=inputArgs, options={poStdErrToStdOut, poUsePath})

proc name*(finder: Finder, pattern: string): Finder =
  ## Add one file name for searching
  result = finder

proc name*(finder: Finder, fileNames: openarray[string]): Finder =
  ## Add one or more file names to the current search criteria
  result = finder

proc ext*(finder: Finder, fileExtension: varargs[string]): Finder =
  finder.filters.extensions = toSeq fileExtension
  result = finder

proc ext*(finder: Finder, fileExtensions: openarray[string]): Finder =
  finder.filters.extensions = toSeq fileExtensions
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
# File API
#

proc getInfo*(file: File): FileInfo =
  ## Returns an instance of `FileInfo`
  ## https://nim-lang.org/docs/os.html#FileInfo
  result = file.info

proc getPath*(file: File, toAbsolutePath = true): string =
  ## Returns path on disk for given File. Set `toAbsolutePath` false
  ## to return the relative path. 
  result = if toAbsolutePath: file.path.absolutePath() else: file.path

proc getFileSize*(file: File): BiggestInt =
  ## Returns the file size of file (in bytes)
  result = file.info.size

proc getSize*(file: File): string =
  ## Returns the current file size of given File
  ## auto-converted to Bytes, KB, MB, GB, or TB.
  var sizes = ["Bytes", "KB", "MB", "GB", "TB"];
  let bytes = toBiggestFloat(file.getFileSize)
  let i = floor log2(bytes) / log2(toFloat 1000)
  let size = (bytes / pow(toFloat 1000, i))
  result = $(size) & indent(sizes[i.toInt], 1)

proc getLastAccessTime*(file: File): Time =
  ## Returns the file's last read or write access time
  result = file.info.lastAccessTime

proc getLastModificationTime*(file: File): Time =
  ## Returns the file's last read or write access time
  result = file.info.lastWriteTime

proc files*[F: Finder](finder: typedesc[F], ignoreHiddenFiles = true, followSymlinks = false): F =
  ## Restricts the matching to files only

proc directories*[F: Finder](finder: typedesc[F]): F =
  ## Restricts the matching to directories only

proc recursive*[F: Finder](finder: F): F =
  finder.filters.isRecursive = true
  result = finder

proc execNativeFinder(finder: Finder) =
  var res = Results(searchType: finder.searchType)
  case finder.searchType:
  of SearchInFiles:
    res.fileResults = newOrderedTable[string, File]()
    var byExt = finder.filters.extensions.len != 0
    for fpath in walkDirRec(finder.filters.path, yieldFilter = {pcFile},
                  followFilter = {pcDir}, relative = false, checkDir = false):
      let f: tuple[dir, name, ext: string] = fpath.splitFile()
      if byExt:
        if f.ext in finder.filters.extensions:
          res.fileResults[fpath] = File(path: fpath, info: getFileInfo(fpath))
      else:
        res.fileResults[fpath] = File(path: fpath, info: getFileInfo(fpath))
  of SearchInDirectories:
    discard
  # var byExtension = if ext.len == 0: false else: true
  # for file in walkDirRec(path):
  #   if file.isHidden: continue
  #   if byExtension:
  #     if file.endsWith(ext):
  #       result.add(file)
  #   else:
  #     result.add file
  finder.results = res

proc get*(finder: Finder): Results =
  ## Execute Finder query and return the results
  case finder.driver:
    of Native: execNativeFinder(finder)
    of Unix: discard
    of Remote: discard
  result = finder.results

iterator files*(res: Results): File =
  for k, f in res.fileResults.pairs:
    yield f

iterator dirs*(res: Results): Directory =
  for k, d in res.dirResults.pairs:
    yield d

proc len*(res: Results): int =
  case res.searchType:
  of SearchInFiles:
    result = res.fileResults.len
  of SearchInDirectories:
    result = res.dirResults.len

when isMainModule:
  let res = finder().ext(".nim").recursive.get
  for f in res.files():
    echo f.getPath()
    echo f.getInfo()
    echo f.getSize()
  echo res.len