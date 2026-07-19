Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$foregroundPath = Join-Path $projectRoot 'assets\branding\app_icon_foreground_v11.png'
$outputPath = Join-Path $projectRoot 'assets\branding\play_feature_graphic_1024x500.png'
$desktopPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'chameulin_feature_graphic_1024x500.png'

$canvas = New-Object System.Drawing.Bitmap 1024, 500
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$area = New-Object System.Drawing.Rectangle 0, 0, 1024, 500
$background = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $area,
    [System.Drawing.ColorTranslator]::FromHtml('#425F3A'),
    [System.Drawing.ColorTranslator]::FromHtml('#6F8B55'),
    0
)
$graphics.FillRectangle($background, $area)

$glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(24, 255, 248, 218))
$graphics.FillEllipse($glow, 272, -230, 480, 480)
$graphics.FillEllipse($glow, 676, 250, 360, 360)
$graphics.FillEllipse($glow, -150, 245, 330, 330)

$foreground = [System.Drawing.Image]::FromFile($foregroundPath)
$graphics.DrawImage($foreground, 187, -75, 650, 650)

$foreground.Dispose()
$glow.Dispose()
$background.Dispose()
$graphics.Dispose()

$canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Save($desktopPath, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()

Write-Output $outputPath
Write-Output $desktopPath
