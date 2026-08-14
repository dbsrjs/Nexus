# Nexus — Android 에뮬레이터 개발 환경 설치 (사용자가 직접 실행)
#
# 관리자 권한 불필요. 전부 사용자 폴더에 설치한다.
# 이미 설치된 단계는 건너뛰므로 여러 번 실행해도 안전하다.
#
# 라이선스 동의 질문이 나오면 y 를 입력하십시오.

# PS5.1 은 native 명령의 stderr 를 NativeCommandError 로 감싸므로 Stop 을 쓰지 않는다.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # 진행률 표시가 다운로드를 크게 느리게 한다

$Jdk = "$env:LOCALAPPDATA\Programs\jdk21"
$Sdk = "$env:LOCALAPPDATA\Android\Sdk"
$Tmp = "$env:TEMP\nexus-android-setup"
$Api = 36
$Image = "system-images;android-$Api;google_apis;x86_64"
$AvdName = 'nexus_pixel'

New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

function Step($n, $msg) { Write-Host ""; Write-Host "=== $n) $msg ===" -ForegroundColor Cyan }

# ── 1) JDK 21 ────────────────────────────────
Step 1 'JDK 21 (sdkmanager 는 JDK 17+ 필요, 이 PC 기본 java 는 8)'
if (Test-Path "$Jdk\bin\java.exe") {
  Write-Host "  이미 있음: $Jdk"
} else {
  Write-Host "  다운로드 중… (~180MB)"
  $zip = "$Tmp\jdk21.zip"
  Invoke-WebRequest -Uri 'https://aka.ms/download-jdk/microsoft-jdk-21-windows-x64.zip' -OutFile $zip
  $ex = "$Tmp\jdk-extract"
  Remove-Item -Recurse -Force $ex -ErrorAction SilentlyContinue
  Expand-Archive -Path $zip -DestinationPath $ex -Force
  $inner = Get-ChildItem $ex -Directory | Select-Object -First 1
  New-Item -ItemType Directory -Force -Path (Split-Path $Jdk) | Out-Null
  Remove-Item -Recurse -Force $Jdk -ErrorAction SilentlyContinue
  Move-Item $inner.FullName $Jdk
  Write-Host "  설치: $Jdk"
}
if (-not (Test-Path "$Jdk\bin\java.exe")) { Write-Host "JDK 설치 실패" -ForegroundColor Red; exit 1 }

$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = $Sdk
$env:ANDROID_SDK_ROOT = $Sdk
$env:Path = "$Jdk\bin;$Sdk\platform-tools;$Sdk\emulator;" + $env:Path

# ── 2) commandline-tools ─────────────────────
Step 2 'Android commandline-tools'
$SdkManager = "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
if (Test-Path $SdkManager) {
  Write-Host "  이미 있음"
} else {
  Write-Host "  최신 URL 조회 중…"
  [xml]$repo = (Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/repository2-3.xml' -UseBasicParsing).Content
  # 루트가 sdk:sdk-repository 라 네임스페이스 접두사가 붙는다 → local-name() XPath 사용
  $node = $repo.SelectSingleNode("//*[local-name()='remotePackage'][@path='cmdline-tools;latest']")
  if (-not $node) { Write-Host "cmdline-tools 를 찾지 못했습니다" -ForegroundColor Red; exit 1 }
  $arc = $node.SelectNodes(".//*[local-name()='archive']") |
    Where-Object { $_.SelectSingleNode("*[local-name()='host-os']").InnerText -eq 'windows' } |
    Select-Object -First 1
  $url = "https://dl.google.com/android/repository/" +
    $arc.SelectSingleNode("*[local-name()='complete']/*[local-name()='url']").InnerText

  Write-Host "  다운로드 중… (~150MB)"
  $zip = "$Tmp\cmdline-tools.zip"
  Invoke-WebRequest -Uri $url -OutFile $zip
  $ex = "$Tmp\ct-extract"
  Remove-Item -Recurse -Force $ex -ErrorAction SilentlyContinue
  Expand-Archive -Path $zip -DestinationPath $ex -Force
  New-Item -ItemType Directory -Force -Path "$Sdk\cmdline-tools" | Out-Null
  Remove-Item -Recurse -Force "$Sdk\cmdline-tools\latest" -ErrorAction SilentlyContinue
  Move-Item "$ex\cmdline-tools" "$Sdk\cmdline-tools\latest"
  Write-Host "  설치: $Sdk\cmdline-tools\latest"
}
if (-not (Test-Path $SdkManager)) { Write-Host "cmdline-tools 설치 실패" -ForegroundColor Red; exit 1 }

# ── 3) 라이선스 ──────────────────────────────
Step 3 '라이선스 동의 — 질문마다 y 를 입력하십시오'
& $SdkManager --sdk_root=$Sdk --licenses

# ── 4) 패키지 ────────────────────────────────
Step 4 "SDK 패키지 설치 (시스템 이미지 ~1.5GB, 시간이 걸립니다)"
$listing = & $SdkManager --sdk_root=$Sdk --list 2>$null
$bt = $listing | Select-String -Pattern "build-tools;$Api\.[\d.]+" -AllMatches |
  ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -Last 1
if (-not $bt) { $bt = "build-tools;$Api.0.0" }

$packages = @('platform-tools', 'emulator', "platforms;android-$Api", $bt, $Image)
$packages | ForEach-Object { Write-Host "  - $_" }
& $SdkManager --sdk_root=$Sdk $packages

$ok = $true
foreach ($p in @("$Sdk\platform-tools\adb.exe", "$Sdk\emulator\emulator.exe")) {
  if (Test-Path $p) { Write-Host "  OK   $p" } else { Write-Host "  없음 $p" -ForegroundColor Red; $ok = $false }
}
if (-not $ok) {
  Write-Host ""
  Write-Host "패키지가 설치되지 않았습니다. 위에서 라이선스에 모두 y 로 답했는지 확인하십시오." -ForegroundColor Red
  exit 1
}

# ── 5) AVD ───────────────────────────────────
Step 5 "AVD 생성 ($AvdName)"
$AvdManager = "$Sdk\cmdline-tools\latest\bin\avdmanager.bat"
$have = & $AvdManager list avd 2>$null | Select-String -Pattern "Name: $AvdName"
if ($have) {
  Write-Host "  이미 있음"
} else {
  "no`n" | & $AvdManager create avd -n $AvdName -k $Image -d pixel_7 --force
  Write-Host "  생성: $AvdName"
}

# ── 6) 환경변수 영구 등록 ─────────────────────
Step 6 '환경변수 등록 (사용자 범위)'
[Environment]::SetEnvironmentVariable('JAVA_HOME', $Jdk, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_HOME', $Sdk, 'User')
[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $Sdk, 'User')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
foreach ($p in @("$Sdk\platform-tools", "$Sdk\emulator")) {
  if ($userPath -notlike "*$p*") { $userPath = "$userPath;$p" }
}
[Environment]::SetEnvironmentVariable('Path', $userPath, 'User')
Write-Host "  JAVA_HOME · ANDROID_HOME · PATH 등록 완료"

# ── 7) Flutter 연결 ──────────────────────────
Step 7 'Flutter 에 SDK · JDK 위치 알리기'
$flutter = (Get-Command flutter.bat -ErrorAction SilentlyContinue).Source
if ($flutter -and (Test-Path $flutter)) {
  & $flutter config --android-sdk $Sdk | Out-Null

  # 시스템 기본 java 가 8 이면 Gradle 이 그것을 집어
  # "Run this build using a Java 11 or newer JVM" 으로 실패한다. 명시적으로 고정한다.
  & $flutter config --jdk-dir $Jdk | Out-Null

  Write-Host "  완료 (android-sdk, jdk-dir)"
  & $flutter doctor
} else {
  Write-Host "  flutter 를 PATH 에서 찾지 못했습니다." -ForegroundColor Yellow
  Write-Host "  Flutter 설치 후 아래를 직접 실행하십시오:" -ForegroundColor Yellow
  Write-Host "    flutter config --android-sdk `"$Sdk`""
  Write-Host "    flutter config --jdk-dir `"$Jdk`""
}

Write-Host ""
Write-Host "설치 완료." -ForegroundColor Green
Write-Host "에뮬레이터 기동:  $Sdk\emulator\emulator.exe -avd $AvdName"
