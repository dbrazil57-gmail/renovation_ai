# Local vector previews only. Never installs launcher assets or calls an AI API.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$workspacePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$previewPath = Join-Path $workspacePath 'output/design-review/icon-refinements'
[IO.Directory]::CreateDirectory($previewPath) | Out-Null

$largeStar = 'M78 20 C76 29 74 31 66 33 C74 35 76 38 78 46 C80 38 83 35 91 33 C83 31 80 29 78 20 Z'
$smallStar = 'M79 22 C78 27 76 29 71 30 C76 31 78 33 79 38 C80 33 82 31 87 30 C82 29 80 27 79 22 Z'
$options = @(
 @{ Id='A'; Name='Current favourite'; Colour='Olive + cream'; Bg='#39491C'; Fg='#FFF6E3'; Paths=@(
   @{D='M27 31 L51 44 L69 40 L69 45 L54 49 L54 71 L84 76 L84 81 L27 83 Z M32 39 L32 76 L49 70 L49 48 Z'; W=0}, @{D=$largeStar; W=0}) },
 @{ Id='B'; Name='Lighter room lines'; Colour='Deep teal + ivory'; Bg='#12665F'; Fg='#FFF7E8'; Paths=@(
   @{D='M29 33 L51 45 L68 41 M29 33 L29 80 L51 72 L82 78 M51 45 L51 72 M29 80 L82 78'; W=3.8}, @{D=$smallStar; W=0}) },
 @{ Id='C'; Name='Framed room'; Colour='Warm cream + olive'; Bg='#F6F0E2'; Fg='#3D4C27'; Paths=@(
   @{D='M29 31 L77 31 L77 80 L29 80 Z M29 31 L51 46 L77 31 M51 46 L51 70 L29 80 M51 70 L77 80'; W=3.5}, @{D='M83 19 C82 23 80 25 76 26 C80 27 82 29 83 33 C84 29 86 27 90 26 C86 25 84 23 83 19 Z'; W=0}) },
 @{ Id='D'; Name='Geometric reveal'; Colour='Navy + champagne'; Bg='#1F3042'; Fg='#E8D6AD'; Paths=@(
   @{D='M28 33 L52 43 L52 74 L28 82 Z M52 43 L79 35 L79 79 L52 74 M52 74 L80 81'; W=4}, @{D=$smallStar; W=0}) },
 @{ Id='E'; Name='Soft doorway'; Colour='Terracotta + cream'; Bg='#A75D43'; Fg='#FFF5E5'; Paths=@(
   @{D='M31 81 L31 44 C31 17 77 17 77 44 L77 81 Z M31 81 L52 71 L77 81 M52 45 L52 71'; W=4}, @{D=$smallStar; W=0}) },
 @{ Id='F'; Name='Open room planes'; Colour='Graphite + sage'; Bg='#2A302E'; Fg='#C3D0AE'; Paths=@(
   @{D='M27 33 L52 46 L78 33 L78 81 L52 72 L27 81 Z M52 46 L52 72 M27 33 L27 81'; W=4}, @{D='M81 19 C80 23 78 25 74 26 C78 27 80 29 81 33 C82 29 84 27 88 26 C84 25 82 23 81 19 Z'; W=0}) }
)

function VectorPath([string] $data) {
 $tokens = @([regex]::Matches($data, '[MLCZ]|-?\d+(?:\.\d+)?') | ForEach-Object Value)
 $path = New-Object Drawing.Drawing2D.GraphicsPath
 $path.FillMode = [Drawing.Drawing2D.FillMode]::Alternate
 $cursor = New-Object Drawing.PointF(0, 0)
 $index = 0
 while ($index -lt $tokens.Count) {
  $command = $tokens[$index++]
  switch ($command) {
   'M' { $path.StartFigure(); $cursor = New-Object Drawing.PointF([single]$tokens[$index], [single]$tokens[$index+1]); $index += 2 }
   'L' { $next = New-Object Drawing.PointF([single]$tokens[$index], [single]$tokens[$index+1]); $path.AddLine($cursor, $next); $cursor = $next; $index += 2 }
   'C' { $first = New-Object Drawing.PointF([single]$tokens[$index], [single]$tokens[$index+1]); $second = New-Object Drawing.PointF([single]$tokens[$index+2], [single]$tokens[$index+3]); $next = New-Object Drawing.PointF([single]$tokens[$index+4], [single]$tokens[$index+5]); $path.AddBezier($cursor, $first, $second, $next); $cursor = $next; $index += 6 }
   'Z' { $path.CloseFigure() }
   default { throw "Unsupported vector command: $command" }
  }
 }
 return ,$path
}

function DrawIcon($graphics, $option, [single]$left, [single]$top, [single]$size) {
 $saved = $graphics.Save()
 $graphics.TranslateTransform($left, $top)
 $graphics.ScaleTransform(($size / 108), ($size / 108))
 $background = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml($option.Bg))
 $rounded = New-Object Drawing.Drawing2D.GraphicsPath
 $rounded.AddArc(0, 0, 48, 48, 180, 90); $rounded.AddArc(60, 0, 48, 48, 270, 90)
 $rounded.AddArc(60, 60, 48, 48, 0, 90); $rounded.AddArc(0, 60, 48, 48, 90, 90); $rounded.CloseFigure()
 $graphics.FillPath($background, $rounded)
 $graphics.TranslateTransform(54, 54); $graphics.ScaleTransform(.84, .84); $graphics.TranslateTransform(-54, -54)
 $foreground = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml($option.Fg))
 foreach ($shape in $option.Paths) {
  $path = VectorPath $shape.D
  if ($shape.W -eq 0) { $graphics.FillPath($foreground, $path) }
  else {
   $pen = New-Object Drawing.Pen($foreground.Color, [single]$shape.W)
   $pen.StartCap = [Drawing.Drawing2D.LineCap]::Round; $pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
   $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
   $graphics.DrawPath($pen, $path); $pen.Dispose()
  }
  $path.Dispose()
 }
 $foreground.Dispose(); $background.Dispose(); $rounded.Dispose(); $graphics.Restore($saved)
}

$board = New-Object Drawing.Bitmap(1230, 1020)
$canvas = [Drawing.Graphics]::FromImage($board)
$canvas.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$canvas.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$canvas.Clear([Drawing.ColorTranslator]::FromHtml('#F7F3EA'))
$ink = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#253127'))
$heading = New-Object Drawing.Font('Segoe UI', 25, [Drawing.FontStyle]::Bold)
$caption = New-Object Drawing.Font('Segoe UI', 18, [Drawing.FontStyle]::Bold)
$body = New-Object Drawing.Font('Segoe UI', 14)
$canvas.DrawString('RenoVision - icon refinements', $heading, $ink, 34, 18)
$canvas.DrawString('A remains the preferred direction. All options are previews.', $body, $ink, 36, 65)
for ($index = 0; $index -lt $options.Count; $index++) {
 $option = $options[$index]
 $column = $index % 3; $row = [math]::Floor($index / 3)
 $left = 35 + $column * 405; $top = 112 + $row * 435
 DrawIcon $canvas $option ($left + 50) $top 272
 $canvas.DrawString(($option.Id + ' - ' + $option.Name), $caption, $ink, $left, ($top + 292))
 $canvas.DrawString($option.Colour, $body, $ink, $left, ($top + 332))
 DrawIcon $canvas $option ($left + 305) ($top + 295) 40
 $svgShapes = ($option.Paths | ForEach-Object { if ($_.W -eq 0) { '<path fill-rule="evenodd" d="' + $_.D + '"/>' } else { '<path fill="none" stroke="' + $option.Fg + '" stroke-width="' + $_.W + '" stroke-linecap="round" stroke-linejoin="round" d="' + $_.D + '"/>' } }) -join ''
 $svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><rect width="108" height="108" rx="24" fill="' + $option.Bg + '"/><g transform="translate(54 54) scale(.84) translate(-54 -54)" fill="' + $option.Fg + '">' + $svgShapes + '</g></svg>'
 [IO.File]::WriteAllText((Join-Path $previewPath ($option.Id + '.svg')), $svg)
}
$board.Save((Join-Path $previewPath 'renovision-icon-refinements.png'), [Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $board.Dispose(); $ink.Dispose(); $heading.Dispose(); $caption.Dispose(); $body.Dispose()
Write-Output (Join-Path $previewPath 'renovision-icon-refinements.png')
