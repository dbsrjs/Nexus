# PowerPoint 로 슬라이드마다 PNG 를 뽑는다 — 눈으로 검수하기 위함이다.
#
# LibreOffice 로 렌더하면 맑은 고딕 · Consolas 가 대체 글꼴로 바뀌어 줄바꿈과
# 넘침이 실제와 달라진다. 받는 사람이 여는 것은 PowerPoint 라 PowerPoint 로 본다.
#
# 쓰는 법: powershell -ExecutionPolicy Bypass -File render.ps1 -Pptx 덱.pptx -OutDir render
#
# 한글이 들어 있어 이 파일은 UTF-8 BOM 으로 저장한다(PowerShell 5.1 이 BOM 없는
# UTF-8 을 ANSI 로 읽어 파싱이 깨진다).
param(
  [Parameter(Mandatory = $true)][string]$Pptx,
  [string]$OutDir = 'render',
  [int]$Width = 1600,
  [int]$Height = 900
)
$ErrorActionPreference = 'Stop'

$pptxPath = (Resolve-Path $Pptx).Path
New-Item -ItemType Directory -Force $OutDir | Out-Null
$outPath = (Resolve-Path $OutDir).Path
Get-ChildItem $outPath -Filter 'slide-*.png' -ErrorAction SilentlyContinue | Remove-Item -Force

# PowerPoint 는 인스턴스가 하나뿐이다. COM 으로 만들면 **사용자가 띄워 둔
# PowerPoint 에 붙는다** — 끝낼 때 Quit() 을 무조건 부르면 사용자의 창까지 닫힌다.
$app = New-Object -ComObject PowerPoint.Application
$deck = $null
try {
  try {
    # ReadOnly · 창 없이 연다. 사용자의 편집 상태를 건드리지 않는다.
    $deck = $app.Presentations.Open($pptxPath, $true, $false, $false)
  } catch {
    if ($_.Exception.HResult -eq -2147188160 -or "$_" -match '80048240') {
      Write-Error ("PowerPoint 가 파일을 열지 못했습니다(0x80048240). 같은 덱이 " +
        "'제한된 보기'나 편집 창으로 이미 열려 있으면 이렇게 됩니다 — 사용자에게 " +
        "PowerPoint 창을 닫아 달라고 한 뒤 다시 실행하세요.")
    }
    throw
  }
  $i = 0
  foreach ($slide in $deck.Slides) {
    $i++
    $png = Join-Path $outPath ('slide-{0:D2}.png' -f $i)
    $slide.Export($png, 'PNG', $Width, $Height)
  }
  Write-Output "렌더: $i 장 -> $outPath"
} finally {
  if ($deck) { $deck.Close() }
  # 우리가 연 것 말고 아무것도 없을 때만 끈다 — 제한된 보기 창도 센다.
  if ($app.Presentations.Count -eq 0 -and $app.ProtectedViewWindows.Count -eq 0) {
    $app.Quit()
  }
  [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($app)
}
