param(
    [string]$Src,
    [int]$NewWidth = 720
)
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($Src)
Write-Host "Original: $($img.Width)x$($img.Height)"
$nw = $NewWidth
$nh = [int]($img.Height * $nw / $img.Width)
$dst = [System.IO.Path]::ChangeExtension($Src, $null) + "_sm.png"
$bmp = New-Object System.Drawing.Bitmap $nw, $nh
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, 0, 0, $nw, $nh)
$bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
$bmp.Dispose()
Write-Host "Saved: $dst ($nw x $nh)"
