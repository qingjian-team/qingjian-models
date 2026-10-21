# 维护说明

打包、发布模型与仓库约定。模型文件本身不进 git，只发 Release 附件；提交钩子会拦下超过 1MB 的文件。

## 目录与标签

模型按系列分目录：`models/zhiyi/`、`models/hanzhang/tongbian/`、`models/hanzhang/zhiwei/`。
每个目录至少有 `LICENSE`，打包时拷进压缩包。

一个模型的一个版本对应一个 Release，标签是「目录把斜杠换成横杠」+ `-v` + 版本号：
`zhiyi-v1.0.0`、`hanzhang-tongbian-v1.0.0`、`hanzhang-zhiwei-v1.0.0`。各模型分开发，更新一个不用重传别的。

版本号是「主.次.修订」：

- 主版本：文件格式或输入法读取方式变了，旧版输入法读不了。输入法写死认哪个主版本，只取这个主版本里最新的。
- 次版本：重训或换了权重，格式不变。
- 修订：只改打包、许可或说明，权重不变。

上游自己的名字（如知意的 `1.4V2-Long-L12`）不进标签，写在 Release 说明里。

含章·通变随安装包发（主仓库 `tools/release/data-bundle.sh` 把它打进产品数据包），这里的 Release 是它的出处，设置里不提供下载。

## 打包

```bash
./pack.sh zhiyi 1.0.0 "<模型目录>"
./pack.sh hanzhang/zhiwei 1.0.0 "<模型目录>"
```

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
