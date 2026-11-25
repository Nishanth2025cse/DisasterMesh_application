Add-Type -AssemblyName System.Drawing
$src = "d:\Design thinking\assets\images\logo.png"
$dst = "d:\Design thinking\assets\images\clean_logo.png"
$img = [System.Drawing.Image]::FromFile($src)
$img.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()

Write-Host "Converted image successfully to clean_logo.png"
