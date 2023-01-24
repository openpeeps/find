import std/[unittest, strutils, re]
import find

let dir = "./examples"

test "LOCAL: can init":
  check finder() != nil

test "LOCAL: can find basic stuff":
  let res = finder(dir).get
  check res.len == 7

test "LOCAL: can iterate resuls":
  let res = finder(dir).get
  for f in res.files():
    check f != nil

test "LOCAL: can find by pattern (*.txt)":
  let res = finder(dir).name("*.txt").get
  check res.len == 4

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
  check res.len == 3
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
  check res.len == 7

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

test "LOCAL: can find by size (>= 0.03376.tb)":
  let res = finder(dir).size(>= 0.03376.tb).get
  check res.len == 0