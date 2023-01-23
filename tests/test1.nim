import std/[unittest, strutils]
import find

let dir = "./examples"

test "can init":
  check finder() != nil

test "can find basic stuff":
  let res = finder(dir).get
  check res.len == 6

test "can iterate resuls":
  let res = finder(dir).get
  for f in res.files():
    check f != nil

test "can find by pattern (*.txt)":
  let res = finder(dir).name("*.txt").get
  check res.len == 4

test "can find by pattern (20*.txt)":
  let res = finder(dir).name("20*.txt").get
  check res.len == 3

test "can find by size (> 15.bytes)":
  let res = finder(dir).size(> 15.bytes).get
  check res.len == 1
  for f in res.files:
    check "20.0 Bytes" in f.getSize() # string size with unit label
    check 20.0 == f.getSize(true)     # float size
