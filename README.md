<p align="center">
  <img src="https://github.com/openpeeps/find/blob/main/.github/logo.png" width="90px"><br>
  Finds files and directories based on different criteria<br>via an intuitive fluent interface. 👑 Written in Nim language
</p>

<p align="center">
  <code>nimble install find</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/find/">API reference</a><br><br>
  <img src="https://github.com/openpeeps/find/workflows/test/badge.svg" alt="Github Actions"> <img src="https://github.com/openpeeps/find/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- [x] Fluent interface for composing search criteria
- [x] Wildcard name patterns (`*` and `?`) and file-extension filters
- [x] Regular expressions on the basename or full path
- [x] Size filters in human-friendly units (`B`, `KB`, `MB`, `GB`, `TB`) with `==`, `!=`, `<`, `<=`, `>`, `>=` operators
- [x] Content search (literal strings or `/regex/`) and content exclusion
- [x] Modification-time filters (`modifiedAfter` / `modifiedBefore`)
- [x] Recursive and non-recursive search
- [x] Hidden files and directories ignored by default
- [x] Zero-copy, memory-mapped content scanning
- [x] Open Source | `MIT` License
- [x] Written in Nim language

## Usage

Add `find` to your `find.nimble` dependencies, then import it:

```nim
import find
```

### Quick start

Search a directory for all `*.txt` files and collect the matches into a `seq[string]`:

```nim
import find

var files: seq[string]
newFinder()
  .path("./examples")
  .name("*.txt")
  .collect(files)

echo files.len # 6
```

`newFinder()` defaults to searching for files (`fkFile`). Use `finder()` as an alias.

### Iterate results

`find` is also an iterator, yielding each matching path as it is found:

```nim
import std/strutils
import find

for path in newFinder().path("./examples").name("*.txt").find():
  echo extractFilename(path)
```

### Filter by file extension

```nim
import find

var images: seq[string]
newFinder()
  .path("./examples")
  .ext("jpg") # no leading dot
  .size(< 5.mb)
  .collect(images)
# -> boris-baldinger-eUFfY6cwjSU-unsplash.jpg
```

### Filter by size

```nim
import find

# files larger than 2 MB
var big: seq[string]
newFinder().path("./examples").size(> 2.mb).collect(big)

# same, via named helpers
var small: seq[string]
newFinder().path("./examples").largerThan(1.mb).collect(small)

# exact match (empty files)
var empty: seq[string]
newFinder().path("./examples").size(== 0.bytes).collect(empty)
```

Size helpers: `bytes`, `kb`, `mb`, `gb`, `tb` (plus `KB`, `MB`, `GB`, `TB`). `smallerThan` works like `largerThan` with a `<` rule.

### Regular expressions

```nim
import std/re
import find

# match the basename
var res: seq[string]
newFinder().path("./examples").namePattern(r"20[\w-]+\.txt").collect(res)

# match the full path
newFinder().path("./examples").pathRegex(r"examples/.+\.md")
```

### Search file contents

```nim
import find

# files containing a literal string
var res: seq[string]
newFinder().path("./examples").contains("Lorem").collect(res)

# exclude files containing a string
newFinder().path("./examples").ext("txt").notContains("Lorem")

# a string wrapped in / / is treated as a regular expression
newFinder().path("./examples").contains(r"/Hello\s+World/")
```

### By modification time

```nim
import std/times
import find

var recent: seq[string]
newFinder()
  .path("./examples")
  .modifiedAfter(toTime(now() - initDuration(days = 7)))
  .collect(recent)
```

### Search directories

```nim
import find

var dirs: seq[string]
newFinder(fkDir).path("./examples").collect(dirs)
```

`fkAny` matches every entry kind. Available kinds: `fkAny`, `fkFile`, `fkDir`, `fkLinkToFile`, `fkLinkToDir`.

### Non-recursive search

```nim
import find

newFinder().path("./examples").recursive(false)
```

For more examples check [/tests](https://github.com/openpeeps/find/tree/main/tests) | [API reference](https://openpeeps.github.io/find/)

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/find/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/find/fork)

### 🎩 License
Find | MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeep).<br>
Copyright &copy; 2026 George Lemon &amp; Contributors &mdash; All rights reserved.
