# 青简模型

[青简输入法](https://github.com/qingjian-team/qingjian)用到的本地模型。全部在本机运行，不联网，不发送任何输入内容。

模型文件发在 Release 里，GitHub 与 Gitee 各放一份。语言模型随各平台安装包；整句模型在「设置 → 实验功能」里点下载（Linux 版随包带含章·通变），不用手动来这里取。

## 模型

| 模型 | 做什么 | 怎么拿到 | 许可 |
|---|---|---|---|
| 青简语言模型 | 二元语言模型，整句候选的底子：词频与相邻词对次数，来自中文维基与 LCCC | 随安装包 | CC-BY-SA-4.0 AND MIT |
| 含章·通变 | 按敲的拼音给整句候选重新排序，不读前文 | 实验功能里下载（Linux 随包） | GPL-3.0-or-later |
| 含章·知微 | 读光标前面的字，给整句候选重新排序 | 实验功能里下载 | GPL-3.0-or-later |
| 知意 1.4V2-Long-L12 | 读光标前面的字与敲的拼音挑候选，来自[知意输入法](https://github.com/dd1000001000/zhiyi_ime) | 实验功能里下载（推荐） | Apache-2.0 |
| 知意（ONNX int8） | 同上，知意输入法发布的 int8 ONNX 原样转发，Windows 用 ONNX Runtime 跑（GPU 走 DirectML） | 实验功能里下载（推荐） | Apache-2.0 |

含章是青简自己训练的模型系列。知意由知意输入法的作者训练并授权，感谢他的合作。

同一时间只用一个模型。实验功能里的模型还在试用，排序效果与占用会随版本调整。

## 目录

```
models/<模型>/LICENSE   每个模型的许可证，随模型一起打包
pack.sh                 把模型目录打包、切块、写下载清单
docs/maintaining.md     打包与发布 Release 的步骤、仓库约定
```

## 许可

打包脚本与仓库配置按 GPL-3.0-or-later 发布（`LICENSE`）。每个模型按 `models/<模型>/LICENSE` 发布：青简语言模型是 CC-BY-SA-4.0 AND MIT（来自语料的许可），含章系列是 GPL-3.0-or-later，知意是 Apache-2.0，版权归各自作者。
