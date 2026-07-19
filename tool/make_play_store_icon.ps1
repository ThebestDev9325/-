Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$foregroundPath = Join-Path $projectRoot 'assets\branding\app_icon_foreground_v11.png'
$outputPath = Join-Path $projectRoot 'assets\branding\play_store_icon_512.png'
$desktopPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'chameulin_app_icon_512.png'

$canvas = New-Object System.Drawing.Bitmap 512, 512
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#527548'))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$foreground = [System.Drawing.Image]::FromFile($foregroundPath)
$graphics.DrawImage($foreground, -51, -51, 614, 614)
$canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Save($desktopPath, [System.Drawing.Imaging.ImageFormat]::Png)

$foreground.Dispose()
$graphics.Dispose()
$canvas.Dispose()

Write-Output $outputPath
Write-Output $desktopPath
