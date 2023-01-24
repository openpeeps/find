import std/[unittest, strutils, re]
import find

let dir = "./examples"

test "LOCAL: can init":
  check finder() != nil

test "LOCAL: can find basic stuff":
  let res = finder(dir).get
  check res.len == 9

test "LOCAL: can iterate resuls":
  let res = finder(dir).get
  for f in res.files():
    check f != nil

test "LOCAL: can find by pattern (*.txt)":
  let res = finder(dir).name("*.txt").get
  check res.len == 6

test "LOCAL: can find by pattern (20*.txt)":
  let res = finder(dir).name("20*.txt").get
  check res.len == 3

test "LOCAL: can find by size (== 0.bytes)":
  let res = finder(dir).size(== 0.bytes).get
  check res.len == 4
  for f in res.files:
    check 0.0 == f.getSize(true)
    check f.getSize() == "0.0 Bytes"

test "LOCAL: can find by size (!= 0.bytes)":
  let res = finder(dir).size(!= 0.bytes).get
  check res.len == 5
  for f in res.files:
    check 0.0 != f.getSize(true)
    check f.getSize() notin "0.0 Bytes"

test "LOCAL: can find by size (> 2.mb)":
  let res = finder(dir).size(> 2.mb).get
  check res.len == 1
  for f in res.files:
    check f.getSize() == "4.79808 MB"
    check 4.79808 == f.getSize(true)

test "LOCAL: can find by size (<= 10.mb)":
  let res = finder(dir).size(<= 10.mb).get
  check res.len == 9

test "LOCAL: can find using regex":
  let res = finder(dir).name(re"20[\w-]+\.txt").get
  check res.len == 3

test "LOCAL: can find using regex + size":
  let res = finder(dir).name(re"20[\w-]+\.txt")
                       .size(== 20.bytes).get
  check res.len == 1

test "LOCAL: can find by ext and size (< 4.82.mb)":
  let res = finder(dir).ext("jpg").size(< 4.82.mb).get
  check res.len == 1

test "LOCAL: can find by ext and size (> 1.442.mb)":
  let res = finder(dir).ext("jpg").size(> 1.442.mb).get
  check res.len == 1

test "LOCAL: can find by size (>= 0.03376.TB)":
  let res = finder(dir).size(>= 0.03376.TB).get
  check res.len == 0

test "LOCAL: can combine `size` criteria + `sortByName` filter":
  var i = 0
  let res = finder(dir).size(== 0.bytes).get
  for f in files(res.sortByName):
    if f.getName == "2022-This-is-deprecated.txt":
      check i == 0
    elif f.getName == "2023-Something-cool.txt":
      check i == 1
    elif f.getName == "Awesome.txt":
      check i == 2
    elif f.getName == "Bawesome.txt":
      check i == 3
    inc i
