<#
.SYNOPSIS
  WSL2 Ubuntu 안에 Nexus 개발용 Postgres + pgvector 를 준비한다. (1회 실행)

.DESCRIPTION
  같은 폴더의 db-setup-wsl.sh 를 WSL 안에서 root 로 실행한다.
  여러 번 돌려도 안전하다(멱등).

  Docker 가 있는 환경이라면 이 스크립트 대신 `npm run db:up:docker` 를 쓰면 된다.

.EXAMPLE
  npm run db:setup
#>
param(
  [string]$Distro = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'

# WSL 이 있는지부터 확인한다. 없으면 여기서 끝내는 편이 낫다 —
# 이 스크립트가 하는 일은 전부 WSL 안에서 일어난다.
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
  Write-Error @"
WSL 을 찾을 수 없습니다.

  wsl --install -d Ubuntu

로 설치한 뒤 다시 실행하거나, Docker 가 있다면 `npm run db:up:docker` 를 쓰십시오.
"@
  exit 1
}

$installed = (wsl.exe -l -q) -replace "`0", '' -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($installed -notcontains $Distro) {
  Write-Error "'$Distro' 배포판이 없습니다. 설치된 것: $($installed -join ', ')"
  exit 1
}

$scriptPath = Join-Path $PSScriptRoot 'db-setup-wsl.sh'
if (-not (Test-Path $scriptPath)) {
  Write-Error "db-setup-wsl.sh 를 찾을 수 없습니다: $scriptPath"
  exit 1
}

# Windows 경로를 WSL 경로로 바꾼다 (C:\... -> /mnt/c/...).
$wslPath = (wsl.exe -d $Distro --exec wslpath -a "$scriptPath") -replace "`0", '' -replace "`r?`n", ''

Write-Host "WSL($Distro) 안에서 Postgres 준비를 시작합니다. 패키지 설치에 몇 분 걸릴 수 있습니다…" -ForegroundColor Cyan
wsl.exe -d $Distro -u root --exec /bin/bash $wslPath
if ($LASTEXITCODE -ne 0) {
  Write-Error "준비 중 실패했습니다 (exit $LASTEXITCODE)."
  exit $LASTEXITCODE
}
