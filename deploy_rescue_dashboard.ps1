$ErrorActionPreference = 'Stop'

flutter build web
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter web build failed.'
}

Copy-Item -Path 'web\rescue.html' -Destination 'build\web\rescue.html' -Force
if (-not (Test-Path 'build\web\rescue.html')) {
    throw 'Rescue dashboard page was not copied into the hosting directory.'
}

npx --yes firebase-tools deploy --only hosting --project silentsos-7d50a
if ($LASTEXITCODE -ne 0) {
    throw 'Firebase Hosting deploy failed.'
}
