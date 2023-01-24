proc execLocalFinder(finder: Finder) =
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
            res.storeFile(fpath)
      else:
        # Searching using UNIX patterns
        if finder.criteria.patterns.len != 0:
          for pattern in finder.criteria.patterns:
            for fpath in walkFiles(absolutePath(finder.criteria.path) / pattern):
              let thisFile = FileFinder(path: fpath, info: getFileInfo(fpath))
              if finder.criteria.bySize:
                if not checkFileSize(finder, thisFile): continue
              res.fileResults[fpath] = thisFile
        elif finder.criteria.regexPatterns.len != 0:
          for pattern in finder.criteria.regexPatterns:
            for fpath in walkDirRec(absolutePath(finder.criteria.path), yieldFilter = {pcFile},
                        followFilter = {pcDir}, relative = false, checkDir = false):
              let f = FileFinder(path: fpath, info: getFileInfo(fpath))
              if finder.criteria.bySize:
                if not checkFileSize(finder, f): continue
              if not re.match(fpath.extractFilename, pattern): continue
              res.storeFile(fpath)
  of SearchInDirectories:
    discard
  finder.results = res
