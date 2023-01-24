<p align="center">
  <img src="https://github.com/openpeep/find/blob/main/.github/logo.png" width="90px"><br>
  Finds files and directories based on different criteria<br>via an intuitive fluent interface. Written in Nim language
</p>

## 😍 Key Features
- [x] Fluent Interface
- [x] `Driver` Local Filesystem
- [ ] `Driver` SSH via libssh
- [ ] `Driver` FTP/SFTP
- [ ] `Driver` WebDAV
- [x] Open Source | `MIT` License
- [x] Written in Nim language

## Installing
```
nimble install find
```

## Examples

Get all `.txt` files from directory
```nim
let res: Results = finder("./examples").name("*.txt").get
```

Get all `.txt` files from directory using `size` criteria
```
let res: Results = finder("./examples").name("*.txt").size(< 10.mb).get
for file in res.files():
  echo file.getPath
```


### ❤ Contributions
Contribute with code, ideas, bugfixing or you can even

### Support
Create a VPS and [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4) | 🥰 [Donate via PayPal address](https://www.paypal.com/donate/?hosted_button_id=RJK3ZTDWPL55C)

### 🎩 License
Find | MIT license. [Made by Humans from OpenPeep](https://github.com/openpeep).<br>
Copyright &copy; 2023 OpenPeep & Contributors &mdash; All rights reserved.