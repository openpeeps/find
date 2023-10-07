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
- [x] Fluent Interface
- [x] `Driver` Local Filesystem
- [ ] `Driver` SSH via libssh
- [ ] `Driver` FTP/SFTP
- [ ] `Driver` WebDAV
- [x] Open Source | `MIT` License
- [x] Written in Nim language

## Examples

Get all `.txt` files from directory
```nim
let res: Results = finder("./examples").name("*.txt").get
```

Get all `.txt` files from directory using `size` criteria
```nim
let res = finder("./examples").name("*.txt").size(< 10.mb).get
for file in res.files():
  echo file.getSize
```

Find files using regular expression
```nim
let res = finder("./examples").name(re"20[\w-]+\.txt").get
for file in res.files:
  echo file.getName 
```

For more examples check [/tests](https://github.com/openpeeps/find/tree/main/tests) | [API reference](https://openpeeps.github.io/find/)

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/find/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/find/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)
- 🥰 [Donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
Find | MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeep).<br>
Copyright &copy; 2023 OpenPeeps & Contributors &mdash; All rights reserved.
