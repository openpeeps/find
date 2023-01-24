proc storeFile(res: Results, fpath: string) =
  res.fileResults[fpath] = FileFinder(path: fpath, info: getFileInfo(fpath))

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