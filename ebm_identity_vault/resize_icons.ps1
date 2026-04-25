Add-Type -AssemblyName System.Drawing
$sourcePath = "C:\Users\sc\.gemini\antigravity\brain\0bf4eef5-5240-4f66-a0b8-7f7a27abb739\extension_icon_base_1777119762819.png"
$destFolder = "c:\Users\sc\Develop\dev\ebm al\ebm\ebm_identity_vault\icons"

if (-not (Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder
}

$srcImage = [System.Drawing.Image]::FromFile($sourcePath)

$sizes = @(16, 48, 128)

foreach ($size in $sizes) {
    $destBitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($destBitmap)
    
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    
    $graphics.DrawImage($srcImage, 0, 0, $size, $size)
    
    $outputPath = Join-Path $destFolder ("icon" + $size + ".png")
    $destBitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $graphics.Dispose()
    $destBitmap.Dispose()
    Write-Host "Generated: $outputPath"
}

$srcImage.Dispose()
