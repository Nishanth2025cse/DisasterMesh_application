$src = "d:\Design thinking\assets\images\clean_logo.png"
$folders = @("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi")

foreach ($f in $folders) {
    $dir = "d:\Design thinking\android\app\src\main\res\$f"
    Copy-Item $src -Destination "$dir\ic_launcher.png" -Force
    Copy-Item $src -Destination "$dir\ic_launcher_round.png" -Force
}
Copy-Item $src -Destination "d:\Design thinking\assets\images\logo.png" -Force
Copy-Item $src -Destination "d:\Design thinking\web\favicon.png" -Force
Write-Host "Updated all launcher icons with valid PNG format!"
