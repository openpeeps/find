proc getInfo*(file: FileFinder): FileInfo =
  ## Returns an instance of `FileInfo`
  ## https://nim-lang.org/docs/os.html#FileInfo
  result = file.info

proc getName*(file: FileFinder): string =
  result = file.path.extractFilename

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

proc getCreationTime*(file: FileFinder): Time =
  ## Returns the creation time
  result = file.info.creationTime