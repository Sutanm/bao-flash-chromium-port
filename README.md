# 端口归档（BaoFlashBrowser · Chromium 138 / 140 原生 PPAPI Flash）

本目录是**可移植的留痕归档**：记录"在 Chromium 138 与 140 上跑通原生 PPAPI Flash"所需的全部补丁、清单与校验值。
不包含 Chromium 全量源码，也不包含 Flash 插件二进制（版权原因）。

## 内容

| 路径 | 说明 |
| --- | --- |
| `patches/138-port.patch` | 138（Electron 37 / Chromium 138.0.7204.35）完整补丁（52 新增 + 31 修改） |
| `patches/140-port.patch` | 140（Electron 38 / Chromium 140.0.7339.41）完整补丁（1782 文件，286 853 行新增） |
| `manifests/140-name-status.txt` | 140 变更文件清单（A/M/D 状态） |
| `manifests/140-numstat.txt` | 140 每文件增删行数 |
| `manifests/138-name-status.txt` | 138 变更文件清单 |
| `manifests/138-numstat.txt` | 138 每文件增删行数 |
| `manifests/140-key-files.sha256` | 13 个关键手改文件的 SHA-256（防漂移） |
| `scripts/restore-140.ps1` | 从 chromium 140 干净树 + 补丁恢复出可用工作树 |
| `scripts/verify-140.ps1` | 校验恢复结果（关键文件哈希 + 变更计数 + 关键符号） |

## 版本指纹

```
140: base 84e1454fbb49226f0b2b0de01343417681d9af10
     head 08ee1eba6ffe3c62d149793361e1ed6149d1bdd1
     chrome/VERSION = MAJOR=140 MINOR=0 BUILD=7339 PATCH=41
     electron = v38.0.0（src/electron）
     patch  = 1782 files changed, 286853 insertions(+), 7 deletions(-)

138: head 32b3d14f10612408b31890269b0e8b01fb9d892e
     chrome/VERSION = MAJOR=138 MINOR=0 BUILD=7204 PATCH=35
     electron = v37.0.0（src/electron）
     patch  = 83 files changed
```

## 恢复到新机器

```powershell
# 1) 取干净源码（与 base 同一 commit）
git clone --no-checkout https://chromium.googlesource.com/chromium/src.git D:\cr140
cd D:\cr140
git checkout 84e1454fbb49226f0b2b0de01343417681d9af10
gclient sync --no-history   # 需要 .gclient 指向 chromium/src + electron/src

# 2) 打补丁
git am --3way D:\port-archive\patches\140-port.patch
#    或者：git apply --3way D:\port-archive\patches\140-port.patch

# 3) 校验
pwsh -File D:\port-archive\scripts\verify-140.ps1 -Src D:\cr140

# 4) 构建（args 见 harness 文档）
gn gen out/Testing --args='import("//electron/build/args/testing.gn") enable_plugins=true symbol_level=1'
ninja -C out/Testing -j 6 electron
```

> `electron/src` 也要 checkout 到与 chromium 140 匹配的 Electron v38 分支，否则 `import("//electron/build/args/testing.gn")` 会失败。

## 相关文档（BaoFlashBrowser 仓库内）

- `docs/specs/2026-11-17-chromium140-ppapi-revival-ai-guide.md` — 面向 AI 的 140 复现手册（16 阶段 + 错误字典）
- `docs/specs/2026-11-15-forward-version-feasibility.md` — 可行性/历程（§1.14.11 = 最终状态）
- `docs/reports/2026-11-17-port-preservation-plan.md` — 保存方案（本地快照 / 小仓库 / 远程 fork / 冷备）与决策

## 合规提示

- Chromium 源码为 BSD-3 许可，补丁可自由分发。
- **Flash 插件二进制（`pepflashplayer*.dll`）不得进入本归档或任何公开仓库**；归档只记录"用哪个版本、怎么加载"。
