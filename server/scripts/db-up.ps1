<#
.SYNOPSIS
  WSL 안의 개발용 Postgres 를 띄우고 Windows 에서 붙을 수 있는 상태로 유지한다.

.DESCRIPTION
  WSL2 는 배포판의 마지막 세션이 닫히면 배포판을 정지시킨다. 그러면 그 안에서
  systemd 가 돌리던 Postgres 도 함께 죽어, Windows 쪽에서 127.0.0.1:5432 가
  ECONNREFUSED 가 된다. (.wslconfig 의 vmIdleTimeout 은 유틸리티 VM 만 잡고
  배포판은 잡지 못한다.)

  그래서 세션을 하나 열어 둔 채로 둔다. 이 스크립트가 그 세션을 백그라운드로
  띄우고, Postgres 가 응답할 때까지 기다린다.

  Docker 를 쓰는 환경이라면 이 스크립트 대신 `docker compose up -d` 를 쓰면 된다.

.EXAMPLE
  npm run db:up
#>
param(
  [string]$Distro = 'Ubuntu',
  [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'

function Test-Postgres {
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $task = $client.ConnectAsync('127.0.0.1', 5432)
    $ok = $task.Wait(2000) -and $client.Connected
    $client.Close()
    return $ok
  } catch { return $false }
}

if (Test-Postgres) {
  Write-Host "Postgres 이미 응답 중 — 127.0.0.1:5432" -ForegroundColor Green
  exit 0
}

# 배포판을 붙잡아 둘 세션. 창 없이 백그라운드로 띄운다.
Write-Host "WSL 세션 유지 프로세스 시작 ($Distro)…"
Start-Process -FilePath 'wsl.exe' `
  -ArgumentList @('-d', $Distro, '-u', 'root', '--exec', '/bin/sleep', 'infinity') `
  -WindowStyle Hidden | Out-Null

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
  if (Test-Postgres) {
    Write-Host "Postgres 준비 완료 — 127.0.0.1:5432" -ForegroundColor Green
    exit 0
  }
  Start-Sleep -Milliseconds 800
}

Write-Error @"
${TimeoutSeconds}초 안에 Postgres 가 응답하지 않았습니다.

확인해 볼 것:
  wsl -d $Distro -u root -- systemctl status postgresql
  wsl -d $Distro -u root -- ss -lnt | grep 5432

DATABASE_URL 은 반드시 127.0.0.1 을 쓸 것. Windows 에서 localhost 는 ::1 로 먼저
해석되는데 WSL 포워딩은 IPv4 만 동작한다.
"@
exit 1
