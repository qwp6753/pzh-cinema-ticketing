param(
    [string]$MySqlCommand = 'mysql',
    [string]$User = 'root',
    [string]$HostName = '127.0.0.1',
    [int]$Port = 3306,
    [switch]$IncludeDemo
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$sqlFiles = @('database/01_schema.sql', 'database/02_seed.sql')
if ($IncludeDemo) { $sqlFiles += 'database/03_demo.sql' }
$sqlFiles += 'database/04_views.sql'
Write-Host '将在所选MySQL实例的pzh_cinema库创建新表。请使用空业务库；已有同名表会报错。'
Write-Host 'MySQL将交互式请求密码。脚本不保存或打印密码。'
$sqlContent = ($sqlFiles | ForEach-Object { [System.IO.File]::ReadAllText((Join-Path $projectDirectory $_), [System.Text.Encoding]::UTF8) }) -join [Environment]::NewLine
$previousOutputEncoding = $OutputEncoding
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)
Push-Location -LiteralPath $projectDirectory
try {
    $sqlContent | & $MySqlCommand '--default-character-set=utf8mb4' '--batch' '--protocol=TCP' "--host=$HostName" "--port=$Port" "--user=$User" '-p'
    if ($LASTEXITCODE -ne 0) { throw '导入失败。MySQL DDL无法整体回滚；请先检查失败位置与已有表，不要盲目重复导入。' }
    Write-Host '数据库导入完成。可运行05_readonly_checks.sql进行只读检查。'
} finally {
    $OutputEncoding = $previousOutputEncoding
    Pop-Location
}
