# 校验 BaoFlashBrowser 140 移植状态是否完整
# 用法: pwsh -File verify-140.ps1 -Src D:\cr140
param(
    [Parameter(Mandatory = $true)][string]$Src,
    [string]$HashFile = (Join-Path $PSScriptRoot '..\manifests\140-key-files.sha256')
)

$ErrorActionPreference = 'Continue'
$fail = 0

function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "  OK    $what" -ForegroundColor Green }
    else { Write-Host "  FAIL  $what" -ForegroundColor Red; $script:fail++ }
}

Write-Host "== 1. 关键文件哈希 =="
if (Test-Path -LiteralPath $HashFile) {
    foreach ($line in Get-Content -LiteralPath $HashFile) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split '\s+', 2
        $want = $parts[0]; $rel = $parts[1]
        $p = Join-Path $Src $rel
        if (-not (Test-Path -LiteralPath $p)) { Check $false "$rel（缺失）"; continue }
        $got = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower()
        Check ($got -eq $want) "$rel"
    }
} else { Write-Warning "缺少哈希清单: $HashFile" }

Write-Host "== 2. 目录规模 =="
foreach ($d in @('ppapi', 'content\renderer\pepper', 'content\browser\renderer_host\pepper', 'content\ppapi_plugin')) {
    $n = (Get-ChildItem -LiteralPath (Join-Path $Src $d) -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Check ($n -gt 0) "$d 文件数 = $n"
}

Write-Host "== 3. 关键符号 =="
$pairs = @(
    @('ppapi\buildflags\buildflags.gni', 'enable_ppapi'),
    @('ppapi\proxy\interface_list.cc', 'PPB_Flash'),
    @('content\renderer\pepper\pepper_graphics_2d_host.cc', 'TransferableResource::Make'),
    @('content\renderer\pepper\pepper_graphics_2d_host.cc', 'resource_image'),
    @('content\renderer\render_frame_impl.cc', 'CreatePlugin'),
    @('content\app\content_main_runner_impl.cc', 'PpapiPluginMain'),
    @('sandbox\policy\sandbox_type.cc', 'Ppapi'),
    @('content\renderer\pepper\web_font_shim.cc', 'x')
)
foreach ($pair in $pairs) {
    $p = Join-Path $Src $pair[0]
    if (-not (Test-Path -LiteralPath $p)) { Check $false "$($pair[0])（缺失）"; continue }
    $hit = (Select-String -LiteralPath $p -Pattern $pair[1] -SimpleMatch -Quiet)
    Check ([bool]$hit) "$($pair[0]) 含 '$($pair[1])'"
}

Write-Host "== 4. git 状态 =="
Push-Location $Src
$changed = @(git status --porcelain 2>$null)
Write-Host "  变更条目: $($changed.Count)"
Pop-Location

Write-Host ""
if ($fail -eq 0) { Write-Host "全部通过 ✅" -ForegroundColor Green; exit 0 }
else { Write-Host "有 $fail 项未通过 ❌" -ForegroundColor Red; exit 1 }
