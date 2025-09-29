Param(
  [string]$Source = 'content.tex'
 , [string]$OutDir = 'chapters_new'
 , [switch]$Clean
 , [switch]$KeepPreamble
 , [switch]$Verbose
)

# Split LaTeX content.tex into individual chapter files.
# Usage:
#   pwsh scripts/split_chapters.ps1 -Source content.tex -OutDir chapters_new -KeepPreamble -Clean -Verbose

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source)) {
  Write-Error "Source file not found: $Source"
}

# Ensure output dir
if ((Test-Path $OutDir) -and $Clean) {
  Get-ChildItem -Path $OutDir -File -Filter '*.tex' | Remove-Item -Force
}
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# Read all text (preserve encoding by default UTF-8)
$text = Get-Content -Raw -Path $Source

<#
  Pattern: we want to treat each line that starts with \chapter{ as a boundary.
  We'll capture the title but more importantly the index positions so we can slice.
  We consider optional leading whitespace before \chapter.
#>
$pattern = '(?m)^(\s*\\chapter\{([^}]*)\})'

$matches = [System.Text.RegularExpressions.Regex]::Matches($text, $pattern)
if ($matches.Count -eq 0) {
  Write-Warning "No \\chapter found in $Source"
  exit 0
}

# Helper: sanitize filename
function Sanitize([string]$name) {
  # Remove LaTeX special chars and trim
  $s = $name -replace '[\\/:*?"<>|]', ' ' -replace '\\s+', ' ' -replace '\\$', ''
  $s = $s.Trim()
  # Replace spaces with underscore, limit length
  if ($s.Length -gt 60) { $s = $s.Substring(0,60) }
  return ($s -replace ' ', '_')
}

# We'll iterate over matches, slice text between their indices.
$chapters = @()
for ($i=0; $i -lt $matches.Count; $i++) {
  $chapterStart = $matches[$i].Index
  $chapterCmd   = $matches[$i].Groups[1].Value  # full \chapter{...}
  $titleOnly    = $matches[$i].Groups[2].Value
  $chapterEnd   = if ($i -lt $matches.Count - 1) { $matches[$i+1].Index } else { $text.Length }
  $length = $chapterEnd - $chapterStart
  $segment = $text.Substring($chapterStart, $length)
  $chapters += [pscustomobject]@{Title=$titleOnly; Body=$segment; Cmd=$chapterCmd}
}

# Optionally extract preamble (everything before first chapter) into a separate file
$preamble = $null
if ($matches.Count -gt 0) {
  $firstChapIndex = $matches[0].Index
  if ($firstChapIndex -gt 0) {
    $preamble = $text.Substring(0, $firstChapIndex)
    if ($KeepPreamble) {
      $preambleFile = Join-Path $OutDir '000-Preamble.tex'
      Set-Content -Path $preambleFile -Value $preamble -Encoding UTF8
      if ($Verbose) { Write-Host "Wrote $preambleFile" -ForegroundColor DarkCyan }
    }
  }
}

$index = 1
$pad = [Math]::Max(2, [Math]::Ceiling([Math]::Log10([double]([Math]::Max(10,$chapters.Count+1)))))

foreach ($c in $chapters) {
  $safe = Sanitize $c.Title
  if ([string]::IsNullOrWhiteSpace($safe)) { $safe = 'Chapter' }
  $num = $index.ToString('D' + $pad)
  $fileName = "$num-$safe.tex"
  $outPath = Join-Path $OutDir $fileName
  # Ensure body starts with the \chapter line exactly once
  $body = $c.Body.TrimStart()
  if (-not ($body -match '^\\chapter')) {
    # Prepend if somehow stripped
    $body = "$($c.Cmd)`n$body"
  }
  Set-Content -Path $outPath -Value $body -Encoding UTF8
  Write-Host "Wrote $outPath" -ForegroundColor Green
  if ($Verbose) { Write-Host "  Title: $($c.Title)" -ForegroundColor Gray }
  $index++
}

Write-Host "Total chapters: $($chapters.Count) -> directory: $OutDir" -ForegroundColor Cyan
if ($preamble -and $KeepPreamble) {
  Write-Host "Preamble saved as 000-Preamble.tex" -ForegroundColor Cyan
}
