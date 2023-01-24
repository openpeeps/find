# Finds files and directories based on different criteria
#
# (c) 2023 Find | MIT License
#          George Lemon | Made by Humans from OpenPeep
#          https://github.com/supranim

# https://github.com/symfony/symfony/blob/6.1/src/Symfony/Component/Finder/Finder.php#method_directories
# https://symfony.com/doc/current/components/finder.html#files-or-directories
import std/[os, tables, times, re, strutils, sequtils,
          math, asyncdispatch, asyncftpclient, net]
# import std/posix except Time
import pkg/libssh2

type
  FinderDriverType* {.pure.} = enum
    LOCAL, SSH, FTP

  SearchType* = enum
    SearchInFiles, SearchInDirectories

  SortType* = enum
    SortByModifiedTime, SortByChangedTime, SortByAccessedTime, SortByType, SortByName

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

  AbstractDriver = ref object of RootObj
    searchType: SearchType
    criteria: Criterias
    filters: Filters

  LocalFinder* = ref object of AbstractDriver

  # SSH
  AuthType = enum
    authPassword
    authPublicKeyFile

  # https://github.com/yglukhov/asyncssh/blob/master/asyncssh.nim
  # https://github.com/treeform/asyncssh/blob/master/src/asyncssh.nim
  SSHFinder* = ref object of AbstractDriver
    sock: AsyncFD
    session: Session
    host: string
    port: Port
    username: string
    case authType: AuthType:
    of authPassword:
      password: string
    of authPublicKeyFile:
      pubKeyFile, privateKeyFile, passphrase: string

  # FTP
  Finder* = ref object
    case driver: FinderDriverType
    of LOCAL:
      local: LocalFinder
    of SSH:
      ssh: SSHFinder
    of FTP:
      ftp: AsyncFtpClient

    searchType: SearchType
    criteria: Criterias
    filters: Filters
    results: Results
      ## An instance of `Results`

# https://regex101.com/
# https://github.com/nitely/nregex/blob/master/src/nregex.nim
let humanRegex = {
  "[[:alnum:]]": "([0-9A-Za-z])",   # alphanumeric
  "[[:alpha:]]": "([A-Za-z])",      # alphabetic
  "[[:ascii:]]": """[\x00-\x7F]""", # ASCII
  "[[:blank:]]": """([\t ])""",     # blank

}.toTable

const vcsPatterns = [".svn", "_svn", "CVS", "_darcs", ".arch-params",
                      ".monotone", ".bzr", ".git", ".hg"]

proc finder*(path = ".", driver = LOCAL, searchType = SearchInFiles,
            isRecursive = false): Finder =
  var f = Finder(driver: driver, searchType: searchType)
  f.criteria.path = path
  f.filters.isRecursive = isRecursive
  f.filters.ignoreVCSFiles = true
  result = f

# proc cmd(inputCmd: string, inputArgs: openarray[string]): auto {.discardable.} =
#   ## Short hand for executing shell commands via execProcess
#   result = execProcess(inputCmd, args=inputArgs, options={poStdErrToStdOut, poUsePath})

include find/private/file
include find/private/criterias
include find/private/filters

include find/local
include find/ssh


proc get*(finder: Finder): Results =
  ## Execute Finder query and return the results
  if finder.criteria.patterns.len == 0 and
      finder.criteria.regexPatterns.len == 0:
    finder.criteria.patterns = @["*"]
  case finder.driver:
    of LOCAL: execLocalFinder(finder)
    of SSH: discard
    of FTP: discard
  result = finder.results

when isMainModule:
  let res = finder("./examples/", driver = LOCAL).name("*.txt").size(> 15.bytes, < 20.bytes).get
  for f in res.files():
    echo f.getPath()
    echo f.getSize()
    # echo f.getInfo()