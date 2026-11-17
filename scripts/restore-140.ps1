# 从干净 Chromium 140 树恢复 BaoFlashBrowser 的 PPAPI 移植状态
# 用法: pwsh -File restore-140.ps1 -Src D:\cr140 [-Patch D:\port-archive\patches\140-port.patch]
param(
    [Parameter(Mandatory = $true)][string]$Src,
    [string]$Patch = (Join-Path $PSScriptRoot '..\patches\140-port.patch'),
    [string]$Base = '84e1454fbb49226f0b2b0de01343417681d9af10'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Src)) { throw "源码目录不存在: $Src" }
if (-not (Test-Path -LiteralPath $Patch)) { throw "补丁不存在: $Patch" }

Write-Host "[1/4] 检查当前 HEAD 是否与 base 兼容..."
Push-Location $Src
try {
    $head = (git rev-parse HEAD).Trim()
    $mergeBase = (git merge-base HEAD $Base 2>$null)
    if ($head -ne $Base -and $mergeBase -ne $Base) {
        Write-Warning "HEAD=$head 与 base=$Base 不一致；补丁可能需要 3-way 合并。"
    } else {
        Write-Host "      HEAD=$head（与 base 兼容）"
    }

    Write-Host "[2/4] 应用补丁（3-way）..."
    git apply --3way --whitespace=nowarn $Patch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "git apply 返回 $LASTEXITCODE；尝试 git am..."
        git am --3way $Patch
        if ($LASTEXITCODE -ne 0) { throw "补丁应用失败，请手工处理冲突" }
    }

    Write-Host "[3/4] 统计变更..."
    $changed = @(git status --porcelain)
    Write-Host "      工作树变更条目: $($changed.Count)（预期 1782 左右）"

    Write-Host "[4/4] 完成。下一步："
    Write-Host "      gn gen out/Testing --args='import(""//electron/build/args/testing.gn"") enable_plugins=true symbol_level=1'"
    Write-Host "      ninja -C out/Testing -j 6 electron"
} finally {
    Pop-Location
}
