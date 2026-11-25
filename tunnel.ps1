while ($true) {
    Write-Host "Starting persistent tunnel connection..."
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -R 80:localhost:8000 nokey@localhost.run
    Start-Sleep -Seconds 2
}
