# Generate a simple Replace U icon (R letter on dark background)
# Outputs a 32x32 .ico file

Add-Type -AssemblyName System.Drawing

$size = 32
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# Dark background matching Replace U aesthetic (near-black)
$bgColor = [System.Drawing.Color]::FromArgb(24, 24, 24)
$g.Clear($bgColor)

# White "R" letter
$font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$brush = [System.Drawing.Brushes]::White
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
$rect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
$g.DrawString("R", $font, $brush, $rect, $format)

$g.Dispose()

# Save as .ico
$icoPath = Join-Path $PSScriptRoot "replace-u.ico"
$stream = [System.IO.File]::Create($icoPath)

# ICO header
$stream.Write([byte[]]@(0,0,1,0,1,0), 0, 6)  # ICONDIR: reserved, type=1, count=1
# ICONDIRENTRY: 32x32, 0 colors, 0 reserved, 1 plane, 32bpp
$stream.Write([byte[]]@(32, 32, 0, 0, 1, 0, 32, 0), 0, 8)

# Convert bitmap to PNG bytes for the icon data
$pngStream = New-Object System.IO.MemoryStream
$bmp.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $pngStream.ToArray()
$pngStream.Dispose()

# Size of image data (4 bytes, little-endian)
$sizeBytes = [BitConverter]::GetBytes([int]$pngBytes.Length)
$stream.Write($sizeBytes, 0, 4)

# Offset to image data (4 bytes, little-endian) = 6 + 16 = 22
$offsetBytes = [BitConverter]::GetBytes([int]22)
$stream.Write($offsetBytes, 0, 4)

# Image data
$stream.Write($pngBytes, 0, $pngBytes.Length)

$stream.Close()
$bmp.Dispose()

Write-Host "Icon created: $icoPath"
