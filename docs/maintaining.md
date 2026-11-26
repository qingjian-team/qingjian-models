# 维护说明

打包、发布模型与仓库约定。模型文件本身不进 git，只发 Release 附件；提交钩子会拦下超过 1MB 的文件。

## 目录与标签

模型按系列分目录：`models/lm/`、`models/zhiyi/`、`models/zhiyi-onnx/`、`models/zhiyi-feather/`、`models/zhiyi-feather-onnx/`、`models/hanzhang/tongbian/`、`models/hanzhang/zhiwei/`。
`lm` 是青简语言模型 `lm.qj`（主仓库 `dict-convert bigram` 统计、`pack lm` 打包）。
`zhiyi` 是 safetensors（macOS 用 candle 跑），`zhiyi-onnx` 是知意输入法发布的 int8 ONNX 原样转发（Windows 用 ONNX Runtime 跑），分词表与词表两边相同。
知意的几条模型线各占一组目录，用户在输入法里选用哪个，同时在线：`zhiyi` / `zhiyi-onnx` 是 1.4V2-Long-L12，`zhiyi-feather` / `zhiyi-feather-onnx` 是 zhen-feather。
上游同一条线出新版（feather 的下一版）在原目录升次版本；新的一条线另开目录。转发只带青简运行要的文件，不带上游的 `candle_ref/`（GPL-3.0-only）、测试向量与联想用的图。
每个目录至少有 `LICENSE`，打包时拷进压缩包。

一个模型的一个版本对应一个 Release，标签是「目录把斜杠换成横杠」+ `-v` + 版本号：
`lm-v1.0.0`、`zhiyi-v1.0.0`、`zhiyi-onnx-v1.0.0`、`hanzhang-tongbian-v1.0.0`、`hanzhang-zhiwei-v1.0.0`。各模型分开发，更新一个不用重传别的。

版本号是「主.次.修订」：

- 主版本：文件格式或输入法读取方式变了，旧版输入法读不了。输入法写死认哪个主版本，只取这个主版本里最新的。
- 次版本：重训或换了权重，格式不变。
- 修订：只改打包、许可或说明，权重不变。

上游自己的名字（如知意的 `1.4V2-Long-L12`）不进标签，写在 Release 说明里。

随包的模型（语言模型、Linux 版的含章·通变）由主仓库 `tools/release/models.lock` 钉住标签与压缩包的 SHA-256，打包时 `tools/release/models-fetch.py` 从这里的 Release 下载、核对、解开。
换随包模型的版本：发新 Release，再改主仓库的 `models.lock`。

## 清单 index.json

设置程序每次打开时取一次仓库根目录的 `index.json`（Gitee 与 GitHub 同时取，先回来的用），「实验功能」里列出的模型就是它，取不到时用上次存下的那份。
上架一个模型或一个新版本，就是发好 Release 后在这里加或改一条；不用发新版输入法，除非它要新的引擎格式。

- `format`：清单本身的写法。改了字段的意思就加一，旧输入法看到读不懂的会提示更新。
- 每个模型一条：
  - `id`：装到下载目录的 `models/<id>/`，配置里也记这个。定了不改，升版本只改下面的 `version` 与各 `tag`。
  - `name`、`description`：卡片的标题与说明。标题写上游的型号原文。
  - `engine`：`zhiyi` 或 `hanzhang`，用哪套代码跑。
  - `engine_format`：这套代码要认得的模型格式。同一引擎换了模型结构（如知意 1.4V2-Long-L12 是 1、zhen-feather 是 2）就加一；输入法认不得的显示「需要新版输入法」，不给下载。
  - `version`：与 Release 标签里的版本号一致。
  - `license`：SPDX 写法；`author`：名字与主页。
  - `recommended`：卡片上的「推荐」，只改标签，不替用户换模型。没有就是不推荐。
  - `deprecated`：弃用的不再给下载；已经装了的照样能用，卡片上标出来，删不删由用户。没有就是没弃用。
  - `variants`：同一个模型给不同运行方式的包，输入法取自己能跑的那个：`runtime` 是 `candle`（safetensors 与 `.qjm`）或 `onnx`；`tag` 是 Release 标签；`archive_dir` 是压缩包里那一层目录；`bytes` 是拼好的整个压缩包的字节数，照抄 `manifest.json` 的 `archive.bytes`。

清单只写怎么找、怎么显示；文件对不对仍按每个 Release 的 `manifest.json` 核对。

## 打包

```bash
./pack.sh zhiyi 1.0.0 "<模型目录>"
./pack.sh hanzhang/zhiwei 1.0.0 "<模型目录>"
./pack.sh lm 1.0.0 "<放 lm.qj 的目录>"
./pack.sh zhiyi-onnx 1.0.0 "<解开的 laya-zhen-long-l12-int8g.zip>"
```

`zhiyi-onnx` 的来源是知意输入法 Release `model-zhen-long-l12` 的 `laya-zhen-long-l12-int8g.zip`；打包前核对 `laya.int8g.onnx` 的 SHA-256 与上游 `scripts/fetch_model.py` 里的 `ONNX_SHA256` 一致。
`zhiyi-feather` / `zhiyi-feather-onnx` 的来源是知意模型仓库（dd1000001000/zhiyi_models）的 Release，`-safetensors.zip` 与 `-int8g.zip`；
打包前核对 `model.safetensors`、`laya.int8g.onnx` 的 SHA-256 与那个 Release 说明里列的一致（Hugging Face `zhiyi-ime/` 下同名仓库是同一份权重）。

`pack.sh` 只打运行要的文件（每个模型的清单写在脚本里），加上 `models/<模型>/LICENSE`，打成 tar.gz，按 95MB 切块，输出到 `dist/<标签>/`：

- `<标签>.tar.gz.part1`、`part2`……：Gitee 单个附件不能超过 100MB，所以切块；
- `manifest.json`：模型、版本号、标签，每块的文件名、字节数、SHA-256，以及拼回来的整个压缩包的字节数与 SHA-256。

脚本最后会把分块拼回去核对一遍，对不上就报错退出。压缩包解开是 `<模型目录>/` 一层，比如 `hanzhang/zhiwei/`。

## 发布

1. 打包，核对 `manifest.json`。
2. GitHub 与 Gitee 各建同名 Release，上传 `dist/<标签>/` 里的全部文件（分块与 `manifest.json`）。两边的文件必须一模一样。
3. Gitee 每个仓库的附件总共不超过 1GB，旧版本没人用了就删掉。
4. 主仓库里记下新标签与清单，输入法按它下载：先试 Gitee，失败再试 GitHub；逐块核对，拼好再核对整个压缩包，再解到用户的模型目录。

Release 发出去就不改；要换文件，就发一个新版本、用新标签。

## 提交信息

`<类型>(<范围>): <说明>`，范围写模型目录，跨几个的可以省略。例如 `feat(zhiyi): 发布 v1.0.0`、`build: pack.sh 改按 95MB 切块`。
类型：`feat` 新模型或新版本 / `fix` 修打包或许可文件 / `docs` 只改文字 / `build` 打包脚本 / `ci` / `chore`。

启用本地钩子（提交前拦大文件、检查提交信息）：

```sh
git config core.hooksPath .githooks
```
