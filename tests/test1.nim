import std/[unittest, strutils, re, os]
import ../src/find

let dir = "./examples"

test "LOCAL: can init":
  check newFinder() != nil

test "LOCAL: can find basic stuff":
  var res: seq[string]
  newFinder().path(dir).collect(res)
  check res.len == 10

test "LOCAL: can iterate results":
  var res: seq[string]
  newFinder().path(dir).collect(res)
  for f in res:
    check f.len > 0

test "LOCAL: can find by pattern (*.txt)":
  var res: seq[string]
  newFinder().path(dir).name("*.txt").collect(res)
  check res.len == 6

test "LOCAL: can find by pattern (20*.txt)":
  var res: seq[string]
  newFinder().path(dir).name("20*.txt").collect(res)
  check res.len == 3

suite "Size tests":
  test "LOCAL: can find by size (== 0.bytes)":
    var res: seq[string]
    newFinder().path(dir).size(== 0.bytes).collect(res)
    check res.len == 5

  test "LOCAL: can find by size (!= 0.bytes)":
    var res: seq[string]
    newFinder().path(dir).size(!= 0.bytes).collect(res)
    check res.len == 5

  test "LOCAL: can find by size (> 2.mb)":
    var res: seq[string]
    newFinder().path(dir).size(> 2.mb).collect(res)
    check res.len == 1

  test "LOCAL: can find by size (<= 10.mb)":
    var res: seq[string]
    newFinder().path(dir).size(<= 10.mb).collect(res)
    check res.len == 10

  test "LOCAL: can find using regex":
    var res: seq[string]
    newFinder().path(dir).namePattern(r"20[\w-]+\.txt").collect(res)
    check res.len == 3

  test "LOCAL: can find using regex + size":
    var res: seq[string]
    newFinder().path(dir).namePattern(r"20[\w-]+\.txt").size(== 20.bytes).collect(res)
    check res.len == 1

  test "LOCAL: can find by ext and size (< 4.82.mb)":
    var res: seq[string]
    newFinder().path(dir).ext("jpg").size(< 4.82.mb).collect(res)
    check res.len == 1

  test "LOCAL: can find by ext and size (> 1.442.mb)":
    var res: seq[string]
    newFinder().path(dir).ext("jpg").size(> 1.442.mb).collect(res)
    check res.len == 1

  test "LOCAL: can find by size (>= 0.03376.TB)":
    var res: seq[string]
    newFinder().path(dir).size(>= 0.03376.TB).collect(res)
    check res.len == 0

suite "Content Contains tests":
  test "LOCAL: can find by content (contains 'Lorem')":
    var res: seq[string]
    newFinder().path(dir).contains("Lorem").collect(res)
    check res.len == 1

  test "LOCAL: can find by content (contains 'Hello')":
    var res: seq[string]
    newFinder().path(dir).contains("Hello").collect(res)
    check res.len == 1