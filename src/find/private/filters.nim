proc storeFile(res: Results, fpath: string) =
  res.fileResults[fpath] = FileFinder(path: fpath, info: getFileInfo(fpath))

proc storeFile(res: Results, f: FileFinder) =
  res.fileResults[f.path] = f

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

proc sortByName*[R: Results](res: R, order: algorithm.SortOrder = Ascending): R =
  ## Sorts files and directories by name
  let s = proc(x, y: (string, FileFinder)): int =
                  cmp(x[1].getName, y[1].getName)
  res.fileResults.sort(s, order)
  result = res

proc sortByType*[R: Results](res: R): R =
  ## Sorts files and directories by type
  ##(directories before files), then by name

proc sortByAccessedTime*[R: Results](res: R, order: algorithm.SortOrder = Descending): R =
  ## Sorts files and directories by the
  ## last accessed time This is the time that
  ## the file was last accessed, read or written to
  let s = proc(x, y: (string, FileFinder)): int =
            cmp(x[1].getLastAccessTime, y[1].getLastAccessTime)
  res.fileResults.sort(s, order)
  result = res

proc sortByModifiedTime*[R: Results](res: R, order: algorithm.SortOrder = Descending): R =
  ## Sorts files and directories by the last modified time
  let s = proc(x, y: (string, FileFinder)): int =
            cmp(x[1].getLastModificationTime, y[1].getLastModificationTime)
  res.fileResults.sort(s, order)
  result = res

proc sortByCreationTime*[R: Results](res: R, order: algorithm.SortOrder = Descending): R =
  ## Sorts files and directories by creation time
  let s = proc(x, y: (string, FileFinder)): int =
            cmp(x[1].getCreationTime, y[1].getCreationTime)
  res.fileResults.sort(s, order)
  result = res

proc sortBySize*[R: Results](res: R, order: algorithm.SortOrder = Descending): R =
  ## Sorts files and directories by size
  let s = proc(x, y: (string, FileFinder)): int =
            cmp(x[1].getSize, y[1].getSize)
  res.fileResults.sort(s, order)
  result = res

template Today*(): DateTime = now()
template Yesterday*(): DateTime = now() - 1.days

proc only*[R: Results](res: R, dateTime: DateTime): R =
  ## Refine the current `Results` table by `DateTime`.
  var i = 0
  var paths: seq[string]
  let dateFormat = "yyyy-MM-dd"
  for p in res.fileResults.keys:
    paths.add p
  for p in paths:
    let createdTime = format(res.fileResults[p].getCreationTime, dateFormat)
    let needTime = format(dateTime.toTime, dateFormat) 
    if createdTime != needTime:
      res.fileResults.del(p)
  result = res

proc only*[R: Results](res: R, interval: TimeInterval): R =
  ## Refine the current `Results` table by `TimeInterval`
  result = res.only(now() - interval)