param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$brandDir = Join-Path $Root 'assets\brand'
$androidRes = Join-Path $Root 'android\app\src\main\res'
$webDir = Join-Path $Root 'web'
$installerAssets = Join-Path $Root 'installer\windows\assets'
$windowsIcon = Join-Path $Root 'windows\runner\resources\app_icon.ico'

New-Item -ItemType Directory -Force $brandDir, (Join-Path $webDir 'icons'), $installerAssets | Out-Null

function New-BrandBitmap {
  param([int]$Size)

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  $background = [System.Drawing.Color]::FromArgb(9, 9, 11)
  $surface = [System.Drawing.Color]::FromArgb(24, 24, 27)
  $border = [System.Drawing.Color]::FromArgb(39, 39, 42)
  $accent = [System.Drawing.Color]::FromArgb(34, 197, 94)

  $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, $Size, $Size),
    $background,
    $surface,
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
  )
  $g.FillRectangle($bgBrush, 0, 0, $Size, $Size)

  $scale = $Size / 1024.0
  $borderPen = New-Object System.Drawing.Pen $border, ([Math]::Max(1, 3 * $scale))
  $accentPen = New-Object System.Drawing.Pen $accent, ([Math]::Max(1, 12 * $scale))
  $surfaceBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(238, 17, 17, 19))

  $margin = 96 * $scale
  $card = [System.Drawing.RectangleF]::new($margin, $margin, $Size - $margin * 2, $Size - $margin * 2)
  $radius = 112 * $scale
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = $radius * 2
  $path.AddArc($card.X, $card.Y, $diameter, $diameter, 180, 90)
  $path.AddArc($card.Right - $diameter, $card.Y, $diameter, $diameter, 270, 90)
  $path.AddArc($card.Right - $diameter, $card.Bottom - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($card.X, $card.Bottom - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  $g.FillPath($surfaceBrush, $path)
  $g.DrawPath($borderPen, $path)

  $blockBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(54, 34, 197, 94))
  $blocks = @(
    @(300, 352, 284, 104),
    @(442, 492, 286, 104),
    @(300, 632, 428, 104)
  )
  foreach ($block in $blocks) {
    $rect = [System.Drawing.RectangleF]::new($block[0] * $scale, $block[1] * $scale, $block[2] * $scale, $block[3] * $scale)
    $g.FillRectangle($blockBrush, $rect)
    $g.DrawRectangle($accentPen, $rect.X, $rect.Y, $rect.Width, $rect.Height)
  }

  $g.DrawLine($accentPen, 220 * $scale, 260 * $scale, 220 * $scale, 760 * $scale)

  $bgBrush.Dispose(); $borderPen.Dispose(); $accentPen.Dispose()
  $surfaceBrush.Dispose(); $blockBrush.Dispose(); $path.Dispose(); $g.Dispose()

  return $bmp
}

function Save-BrandPng {
  param([string]$Path, [int]$Size)
  $bmp = New-BrandBitmap -Size $Size
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

function New-Ico {
  param([string]$Path, [int[]]$Sizes)
  $images = @()
  foreach ($size in $Sizes) {
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) "outstaff_tracker_icon_$size.png"
    Save-BrandPng -Path $temp -Size $size
    $images += ,([PSCustomObject]@{ Size = $size; Bytes = [System.IO.File]::ReadAllBytes($temp) })
    Remove-Item $temp
  }

  $headerSize = 6 + ($images.Count * 16)
  $offset = $headerSize
  $stream = New-Object System.IO.MemoryStream
  $writer = New-Object System.IO.BinaryWriter $stream
  $writer.Write([UInt16]0)
  $writer.Write([UInt16]1)
  $writer.Write([UInt16]$images.Count)
  foreach ($image in $images) {
    $dimension = if ($image.Size -eq 256) { 0 } else { $image.Size }
    $writer.Write([Byte]$dimension)
    $writer.Write([Byte]$dimension)
    $writer.Write([Byte]0)
    $writer.Write([Byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$image.Bytes.Length)
    $writer.Write([UInt32]$offset)
    $offset += $image.Bytes.Length
  }
  foreach ($image in $images) {
    $writer.Write($image.Bytes)
  }
  [System.IO.File]::WriteAllBytes($Path, $stream.ToArray())
  $writer.Dispose(); $stream.Dispose()
}

function New-WizardBitmap {
  param([string]$Path, [int]$Width, [int]$Height, [bool]$Large)
  $bmp = New-Object System.Drawing.Bitmap $Width, $Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, $Width, $Height),
    [System.Drawing.Color]::FromArgb(9, 9, 11),
    [System.Drawing.Color]::FromArgb(24, 24, 27),
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
  )
  $g.FillRectangle($bg, 0, 0, $Width, $Height)
  $accent = [System.Drawing.Color]::FromArgb(34, 197, 94)
  $muted = [System.Drawing.Color]::FromArgb(161, 161, 170)
  $white = [System.Drawing.Color]::FromArgb(250, 250, 250)
  $borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(39, 39, 42)), 1
  $accentPen = New-Object System.Drawing.Pen $accent, 2
  $accentBrush = New-Object System.Drawing.SolidBrush $accent
  $mutedBrush = New-Object System.Drawing.SolidBrush $muted
  $whiteBrush = New-Object System.Drawing.SolidBrush $white
  if ($Large) {
    $g.DrawRectangle($borderPen, 14, 18, $Width - 29, $Height - 37)
    $g.FillRectangle($accentBrush, 24, 30, 4, $Height - 60)
    $titleFont = New-Object System.Drawing.Font 'Segoe UI', 18, ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Object System.Drawing.Font 'Segoe UI', 8.5, ([System.Drawing.FontStyle]::Regular)
    $g.DrawString('Outstaff', $titleFont, $whiteBrush, 36, 40)
    $g.DrawString('Tracker', $titleFont, $whiteBrush, 36, 66)
    $g.DrawString('Kimai time analytics', $bodyFont, $mutedBrush, 38, 112)
    for ($i = 0; $i -lt 7; $i++) {
      $x = 38 + $i * 15
      $h = 28 + (($i * 17) % 74)
      $g.FillRectangle($accentBrush, $x, $Height - 42 - $h, 7, $h)
    }
    $g.DrawLine($accentPen, 38, $Height - 44, $Width - 28, $Height - 44)
    $titleFont.Dispose(); $bodyFont.Dispose()
  } else {
    $g.DrawRectangle($borderPen, 0, 0, $Width - 1, $Height - 1)
    $g.FillRectangle($accentBrush, 9, 10, 5, $Height - 20)
    $titleFont = New-Object System.Drawing.Font 'Segoe UI', 10, ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Object System.Drawing.Font 'Segoe UI', 6.5, ([System.Drawing.FontStyle]::Regular)
    $g.DrawString('OT', $titleFont, $whiteBrush, 19, 11)
    $g.DrawString('time', $bodyFont, $mutedBrush, 20, 29)
    $titleFont.Dispose(); $bodyFont.Dispose()
  }
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Bmp)
  $g.Dispose(); $bmp.Dispose(); $bg.Dispose(); $borderPen.Dispose(); $accentPen.Dispose()
  $accentBrush.Dispose(); $mutedBrush.Dispose(); $whiteBrush.Dispose()
}

Save-BrandPng -Path (Join-Path $brandDir 'app_icon.png') -Size 1024
New-Ico -Path $windowsIcon -Sizes @(16, 32, 48, 64, 128, 256)

$androidIcons = @{
  'mipmap-mdpi\ic_launcher.png' = 48
  'mipmap-hdpi\ic_launcher.png' = 72
  'mipmap-xhdpi\ic_launcher.png' = 96
  'mipmap-xxhdpi\ic_launcher.png' = 144
  'mipmap-xxxhdpi\ic_launcher.png' = 192
}
foreach ($target in $androidIcons.GetEnumerator()) {
  Save-BrandPng -Path (Join-Path $androidRes $target.Key) -Size $target.Value
}

Save-BrandPng -Path (Join-Path $webDir 'favicon.png') -Size 32
Save-BrandPng -Path (Join-Path $webDir 'icons\Icon-192.png') -Size 192
Save-BrandPng -Path (Join-Path $webDir 'icons\Icon-512.png') -Size 512
Save-BrandPng -Path (Join-Path $webDir 'icons\Icon-maskable-192.png') -Size 192
Save-BrandPng -Path (Join-Path $webDir 'icons\Icon-maskable-512.png') -Size 512

New-WizardBitmap -Path (Join-Path $installerAssets 'wizard_large.bmp') -Width 164 -Height 314 -Large $true
New-WizardBitmap -Path (Join-Path $installerAssets 'wizard_small.bmp') -Width 55 -Height 55 -Large $false

Write-Host 'Brand assets generated.'
