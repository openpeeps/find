# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["examples"]


# Dependencies

requires "nim >= 1.6.10"
requires "libssh2"

task tests, "Run test":
  exec "testament p 'tests/*.nim'"

task dev, "dev":
  echo "\n✨ Compiling..." & "\n"
  exec "nim c --gc:arc --out:bin/finder src/find.nim"