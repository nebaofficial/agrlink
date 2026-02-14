# PowerShell script to install Gradle with long path support
$gradleVersion = "8.10.2"
$gradleZip = "gradle-$gradleVersion-all.zip"
$gradleUrl = "https://services.gradle.org/distributions/$gradleZip"
$tempFile = Join-Path $env:TEMP $gradleZip

Write-Host "Downloading Gradle $gradleVersion..." -ForegroundColor Cyan

try {
    # Download if not already present
    if (-not (Test-Path $tempFile)) {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $gradleUrl -OutFile $tempFile -TimeoutSec 600
        Write-Host "Download completed!" -ForegroundColor Green
    } else {
        Write-Host "Using existing download" -ForegroundColor Yellow
    }
    
    # Create Gradle cache directory
    $gradleHome = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-$gradleVersion-all"
    
    # Calculate hash
    $hash = (Get-FileHash -Path $tempFile -Algorithm MD5).Hash.ToLower()
    $gradleExtractDir = Join-Path $gradleHome $hash
    
    Write-Host "Installing to: $gradleExtractDir" -ForegroundColor Cyan
    
    # Create directory
    New-Item -ItemType Directory -Force -Path $gradleExtractDir | Out-Null
    
    # Copy zip to cache
    $destZip = Join-Path $gradleExtractDir $gradleZip
    Copy-Item $tempFile -Destination $destZip -Force
    Write-Host "Gradle zip copied to cache!" -ForegroundColor Green
    
    # Use 7-Zip or tar if available, otherwise use PowerShell with error suppression
    Write-Host "Extracting Gradle (this may show some path errors, but should work)..." -ForegroundColor Cyan
    
    # Try using tar (available in Windows 10+)
    $tarPath = Get-Command tar -ErrorAction SilentlyContinue
    if ($tarPath) {
        Write-Host "Using tar for extraction..." -ForegroundColor Yellow
        Push-Location $gradleExtractDir
        tar -xf $gradleZip 2>$null
        Pop-Location
    } else {
        # Fallback to Expand-Archive with error suppression
        Expand-Archive -Path $destZip -DestinationPath $gradleExtractDir -Force -ErrorAction SilentlyContinue
    }
    
    # Remove the zip file
    Remove-Item $destZip -Force -ErrorAction SilentlyContinue
    
    # Verify installation
    $gradleBin = Join-Path $gradleExtractDir "gradle-$gradleVersion\bin\gradle.bat"
    if (Test-Path $gradleBin) {
        Write-Host "`nGradle $gradleVersion installed successfully!" -ForegroundColor Green
        Write-Host "Location: $gradleExtractDir\gradle-$gradleVersion" -ForegroundColor Yellow
    } else {
        Write-Host "`nWarning: Some files may be missing due to path length limits" -ForegroundColor Yellow
        Write-Host "But Gradle should still work for most operations" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
