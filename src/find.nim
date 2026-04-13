# A super fast template engine for cool kids
#
# (c) 2026 George Lemon | LGPL-v3 License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/find

import std/[os, strutils, times, tables, options, re, memfiles]
import ./find/size
export size

## This module implements a powerful and flexible file searching library, allowing developers
## to easily find files and directories based on various criteria such as name patterns,
## size, modification time, content patterns, and more.
## 
## The `Finder` type provides a fluent API for configuring search parameters, and the
## `find` iterator performs the actual search operation, yielding matching file paths.

type
  FinderSearchKind* = enum
    ## Represents the type of file system entry found during the search.
    fkAny, fkFile, fkDir, fkLinkToFile, fkLinkToDir

  FileSizeUnit* = enum
    Bytes = "Bytes"
    Kilobytes = "KB"
    Megabytes = "MB"
    Gigabytes = "GB"
    Terabytes = "TB"

  Finder* = ref object
    ## Represents the configuration for a file search operation, including search criteria and options.
    kind*: FinderSearchKind
      ## Specifies the type of file system entries
      ## to search for (e.g., files, directories, symbolic links). Default to `fkAny`,
      ## which includes all types
    roots*: seq[string]
      # A sequence of root directories to start the search from. The search will be performed
      # within these directories and their subdirectories (if recursive search is enabled).
    recursiveSearch*: bool = true
      # Indicates whether the search should be performed recursively through subdirectories. Default is `true`.
    namePatterns*: seq[string] # supports * and ?
      # A sequence of filename patterns to filter search results. Patterns can include wildcards like `*` and `?`.
      # If no patterns are specified, all filenames will be considered a match.
    hasMinSize: bool = false
    minSizeBytes: int64
    hasMaxSize: bool = false
    maxSizeBytes: int64
    hasModifiedAfter: bool = false
    modifiedAfterTime: Time
      # Indicates whether to filter results based on modification time, and if so, the cutoff time for filtering.
    hasModifiedBefore: bool = false
      # Indicates whether to filter results based on modification time, and if so, the cutoff time for filtering.
    modifiedBeforeTime: Time
      # The cutoff time for filtering results based on modification time. Only files modified before this time will be included in the search results.
    sizeRule: Option[FSize]
      # An optional `FSize` instance that defines size-based filtering criteria
      # for the search. This can be used to specify
    ignoreHiddenPaths: bool = true
      # Indicates whether hidden files and directories should
      # be ignored during the search. Default is `true`
    nameRegexPatterns*: seq[Regex]
      ## A sequence of regular expression patterns to filter search
      ## results based on the file/directory name (basename)
    pathRegexPatterns*: seq[Regex]
      ## A sequence of regular expression patterns to filter search
      ## results based on the full file/directory path
    extensions*: seq[string]
      # A sequence of file extensions to filter search results.
      # Only files with the specified extensions will be included in the search results.
      # Extensions should be specified without the leading dot (e.g., "txt" for text files).
    excludeBinary*: bool = true
      # Indicates whether binary files should be excluded
      # from the search results. Default is `false`.
    contentPatterns*: seq[string]
    contentRegexPatterns*: seq[Regex]
    notContentPatterns*: seq[string]
    notContentRegexPatterns*: seq[Regex]

let humanRegex = {
  "[[:alnum:]]": "([0-9A-Za-z])",   # alphanumeric
  "[[:alpha:]]": "([A-Za-z])",      # alphabetic
  "[[:ascii:]]": """[\x00-\x7F]""", # ASCII
  "[[:blank:]]": """([\t ])""",     # blank
}.toTable()

const vcsPatterns =
  [".svn", "_svn", "CVS", "_darcs", ".arch-params",
      ".monotone", ".bzr", ".git", ".hg"]

proc wildcardMatch(text, pattern: string): bool =
  var ti = 0
  var pi = 0
  var star = -1
  var mark = 0

  while ti < text.len:
    if pi < pattern.len and (pattern[pi] == '?' or pattern[pi] == text[ti]):
      inc(ti)
      inc(pi)
    elif pi < pattern.len and pattern[pi] == '*':
      star = pi
      mark = ti
      inc(pi)
    elif star != -1:
      pi = star + 1
      inc(mark)
      ti = mark
    else:
      return false

  while pi < pattern.len and pattern[pi] == '*':
    inc(pi)

  pi == pattern.len

proc matchesName(f: Finder, path: string): bool =
  let fileName = extractFilename(path)

  # wildcard group (OR inside group)
  if f.namePatterns.len > 0:
    var ok = false
    for p in f.namePatterns:
      if wildcardMatch(fileName, p):
        ok = true
        break
    if not ok:
      return false

  # basename regex group (OR inside group)
  if f.nameRegexPatterns.len > 0:
    var ok = false
    for rx in f.nameRegexPatterns:
      if fileName.match(rx):
        ok = true
        break
    if not ok: return false

  # full-path regex group (OR inside group)
  if f.pathRegexPatterns.len > 0:
    var ok = false
    for rx in f.pathRegexPatterns:
      if path.match(rx):
        ok = true
        break
    if not ok: return false
  true

proc memContains(hay: ptr UncheckedArray[char], hayLen: int, needle: string): bool =
  ## Zero-copy substring search on mapped memory.
  if hay.isNil or hayLen <= 0: return false
  if needle.len == 0: return true
  if hayLen < needle.len: return false

  let last = hayLen - needle.len
  let first = needle[0]

  for i in 0..last:
    if hay[i] != first:
      continue

    var j = 1
    while j < needle.len and hay[i + j] == needle[j]:
      inc j

    if j == needle.len:
      return true
  false

proc matchesContent(f: Finder, path: string): bool =
  var mf: MemFile
  try:
    mf = memfiles.open(path, mode = fmRead, mappedSize = -1)
    defer: mf.close()

    let n = mf.size
    if n <= 0 or mf.mem == nil: return false

    let data = cast[ptr UncheckedArray[char]](mf.mem)
    for pat in f.contentPatterns:
      if not memContains(data, n, pat):
        return false

    for pat in f.notContentPatterns:
      if memContains(data, n, pat):
        return false

    if f.contentRegexPatterns.len > 0 or f.notContentRegexPatterns.len > 0:
      var content = newString(n)
      copyMem(addr content[0], mf.mem, n)

      for rx in f.contentRegexPatterns:
        if not content.contains(rx):
          return false
      for rx in f.notContentRegexPatterns:
        if content.contains(rx):
          return false
    return true
  except CatchableError:
    return false

proc matchesFilters(f: Finder, path: string, isDir: bool): bool =
  # Checks if the given file path matches the filters specified in the `Finder` instance

  # Check if the file type matches the search kind
  if isDir and f.kind notin {fkAny, fkDir, fkLinkToDir}: return false
  if (not isDir) and f.kind notin {fkAny, fkFile, fkLinkToFile}: return false
  if not f.matchesName(path): return false

  # Size filters (applies only to files)
  if not isDir:
    if f.hasMinSize or f.hasMaxSize:
      try:
        let sz = int64(getFileSize(path))
        if f.hasMinSize and sz < f.minSizeBytes: return false
        if f.hasMaxSize and sz > f.maxSizeBytes: return false
      except OSError:
        return false
    elif f.sizeRule.isSome:
      try:
        let sz = int64(getFileSize(path))
        let szRule = f.sizeRule.get()
        case szRule.op
        of EQ:
          if sz != szRule.bytes: return false
        of NE:
          if sz == szRule.bytes: return false
        of LT:
          if sz >= szRule.bytes: return false
        of LTE:
          if sz > szRule.bytes: return false
        of GT:
          if sz <= szRule.bytes: return false
        of GTE:
          if sz < szRule.bytes: return false
        else: discard
      except OSError:
        return false

  # Modification time filters (applies to both files and directories)
  if f.hasModifiedAfter or f.hasModifiedBefore:
    try:
      let mt = getLastModificationTime(path)
      if f.hasModifiedAfter and mt < f.modifiedAfterTime: return false
      if f.hasModifiedBefore and mt > f.modifiedBeforeTime: return false
    except OSError:
      return false

  if not isDir:
    # Extension filter (applies only to files)
    if f.extensions.len > 0:
      for ext in f.extensions:
        if path.endsWith("." & ext):
          result = true
          break # at least one extension matches
    else:
      result = true
    
    if result:
      # Content filters (applies only to files) when specified
      # If any content-based filters are defined, we need to check them.
      # If no content filters are defined, we can skip this step
      if f.contentPatterns.len > 0 or f.contentRegexPatterns.len > 0 or
        f.notContentPatterns.len > 0 or f.notContentRegexPatterns.len > 0:
          result = f.matchesContent(path)    

#
# Public API
#
proc isVcsPath*(path: string): bool =
  ## Returns true if the path matches any VCS pattern (directory or file)
  for vcs in vcsPatterns:
    if extractFilename(path) == vcs:
      return true
  return false

proc newFinder*(kind: FinderSearchKind = fkFile): Finder =
  ## Creates a new `Finder` instance with the specified search kind and default configuration.
  result = Finder(kind: kind)

proc finder*(kind: FinderSearchKind = fkFile): Finder =
  ## Creates a new `Finder` instance with the specified search kind and default configuration.
  result = Finder(kind: kind)

proc path*(f: Finder, root: string): Finder =
  ## Adds a root directory to the `Finder` instance for searching.
  ## If the root is already present, it will not be added again.
  if not f.roots.contains(root):
    f.roots.add(root)
  f

proc recursive*(f: Finder, enabled = true): Finder =
  ## Sets whether the `Finder` should search directories recursively.
  f.recursiveSearch = enabled
  f

proc name*(f: Finder, pattern: string): Finder =
  ## Adds a filename pattern to the `Finder` instance for filtering search results.
  f.namePatterns.add(pattern)
  f

proc ext*(f: Finder, extension: string): Finder =
  ## Adds a file extension filter to the `Finder` instance. The search
  ## will only include files with the specified extension.
  let ext = extension.strip().toLowerAscii()
  if ext.len > 0 and not f.extensions.contains(ext):
    f.extensions.add(ext)
  f

proc parseSize*(raw: string): int64 =
  var s = raw.strip.toUpperAscii()
  if s.len == 0: raise newException(ValueError, "Size cannot be empty")
  if s.endsWith("B"): s = s[0 .. ^2]

  var mul: int64 = 1
  if s.len > 0:
    case s[^1]
    of 'K': mul = 1024'i64; s = s[0 .. ^2]
    of 'M': mul = 1024'i64 * 1024'i64; s = s[0 .. ^2]
    of 'G': mul = 1024'i64 * 1024'i64 * 1024'i64; s = s[0 .. ^2]
    of 'T': mul = 1024'i64 * 1024'i64 * 1024'i64 * 1024'i64; s = s[0 .. ^2]
    else: discard

  if s.len == 0: raise newException(ValueError, "Invalid size format")
  result = int64(parseInt(s)) * mul

proc largerThan*(f: Finder, size: FSize): Finder =
  f.hasMinSize = true
  f.minSizeBytes = int64(size.bytes)
  f.sizeRule = some(size)
  f

proc smallerThan*(f: Finder, size: FSize): Finder =
  f.hasMaxSize = true
  f.maxSizeBytes = int64(size.bytes)
  f.sizeRule = some(size)
  f

proc size*(f: Finder, rule: FSize): Finder =
  f.sizeRule = some(rule)
  f

proc modifiedAfter*(f: Finder, t: Time): Finder =
  f.hasModifiedAfter = true
  f.modifiedAfterTime = t
  f

proc modifiedBefore*(f: Finder, t: Time): Finder =
  f.hasModifiedBefore = true
  f.modifiedBeforeTime = t
  f

proc namePattern*(f: Finder, pattern: string): Finder =
  ## Adds a regex filter for the file/directory basename.
  let rxStr = humanRegex.getOrDefault(pattern, pattern)
  f.nameRegexPatterns.add(re(rxStr))
  f

proc pathRegex*(f: Finder, pattern: string): Finder =
  ## Adds a regex filter for the full path.
  let rxStr = humanRegex.getOrDefault(pattern, pattern)
  f.pathRegexPatterns.add(re(rxStr))
  f

proc contains*(f: Finder, pattern: string): Finder =
  ## Adds a string or regex pattern to match file contents.
  if pattern.len > 2 and pattern[0] == '/' and pattern[^1] == '/':
    f.contentRegexPatterns.add(re(pattern[1 .. ^2]))
  else:
    f.contentPatterns.add(pattern)
  f

proc notContains*(f: Finder, pattern: string): Finder =
  ## Adds a string or regex pattern to exclude files by content.
  if pattern.len > 2 and pattern[0] == '/' and pattern[^1] == '/':
    f.notContentRegexPatterns.add(re(pattern[1 .. ^2]))
  else:
    f.notContentPatterns.add(pattern)
  f

iterator find*(f: Finder): string =
  ## Performs the file search based on the criteria specified in the `Finder`
  ## instance and yields matching file paths. The search is performed using a depth-first approach,
  ## and it handles both files and directories according to the specified search kind and filters.
  var stack: seq[string] = @[]
  for r in f.roots:
    stack.add(r)

  while stack.len > 0:
    let current = stack[^1]
    stack.setLen(stack.len - 1)
    
    if isHidden(current): continue
    
    if fileExists(current):
      if f.matchesFilters(current, false):
        yield current
      continue
    
    if not dirExists(current): continue

    try:
      for kind, path in walkDir(current, relative = false):
        if isHidden(path): continue
        case kind
        of pcDir, pcLinkToDir:
          if f.matchesFilters(path, true):
            yield path
          if f.recursiveSearch:
            stack.add(path)
        of pcFile, pcLinkToFile:
          if f.matchesFilters(path, false):
            yield path
    except OSError:
      discard

proc collect*(f: Finder, res: var seq[string]) =
  ## Collects all matching file paths from the `Finder` search into a provided sequence
  for p in f.find():
    res.add(p)
