# Set the root directory
$rootDir = "C:\Users\User1\Documents"
$outputDir = Join-Path $rootDir "_file_index"

# Create output directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Gather file information
Write-Host "Gathering file information..."
$fileInfo = Get-ChildItem -Path $rootDir -Recurse -File | Select-Object @{
    Name='filename'; Expression={$_.Name}
}, @{
    Name='extension'; Expression={$_.Extension.ToLower()}
}, @{
    Name='full_path'; Expression={$_.FullName}
}, @{
    Name='relative_path'; Expression={$_.FullName.Replace($rootDir + "\", "")}
}, @{
    Name='directory'; Expression={$_.DirectoryName}
}, @{
    Name='last_modified'; Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}
}, @{
    Name='size_bytes'; Expression={$_.Length}
}

# Save to CSV
Write-Host "Saving to CSV..."
$csvPath = Join-Path $outputDir "file_index.csv"
$fileInfo | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Convert to JSON
Write-Host "Converting to JSON..."
$jsonPath = Join-Path $outputDir "file_index.json"
$fileInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Create HTML index pages
Write-Host "Creating HTML index pages..."

# Get unique directories (up to 2 levels deep)
$directories = $fileInfo | ForEach-Object {
    $relativePath = Split-Path $_.relative_path
    if (($relativePath -split '\\').Count -le 2) {
        $relativePath
    }
} | Sort-Object -Unique

# Add root directory
$directories = @('') + ($directories | Where-Object { $_ })

foreach ($dir in $directories) {
    $dirPath = Join-Path $outputDir $dir
    New-Item -ItemType Directory -Force -Path $dirPath | Out-Null

    $htmlFiles = $fileInfo | Where-Object {
        $_.extension -eq '.html' -and
        (Split-Path $_.relative_path) -eq $dir
    }

    $cssStyle = @"
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        .file-list { margin-top: 20px; }
        .file-item, .directory-item { margin: 10px 0; }
        .directory-item { padding-left: 20px; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .metadata { color: #666; margin-left: 10px; font-size: 0.9em; }
    </style>
"@

    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Index of $(if ($dir) { $dir } else { 'root' })</title>
    $cssStyle
</head>
<body>
    <h1>Index of $(if ($dir) { $dir } else { 'root' })</h1>
    <div class="file-list">
"@

    # For root directory, add links to subdirectories
    if ($dir -eq '') {
        $subdirs = $directories | Where-Object { $_ -ne '' }
        if ($subdirs) {
            $htmlContent += "<h2>Subdirectories:</h2>`n"
            foreach ($subdir in $subdirs) {
                # Create correct relative path for subdirectory index
                $htmlContent += @"
                <div class="directory-item">
                    <a href="./$subdir/index.html">$subdir</a>
                </div>
"@
            }
        }
    }

    # Add HTML files section if there are any
    if ($htmlFiles) {
        $htmlContent += "<h2>HTML Files:</h2>`n"
        foreach ($file in $htmlFiles) {
            # Calculate the path to the root directory
            $depth = ($dir -split '\\').Count
            $upwardPath = "../" * $depth

            # Construct the full path to the HTML file from the Documents root
            $htmlContent += @"
            <div class="file-item">
                <a href="$upwardPath../$($file.relative_path)">$($file.filename)</a>
                <span class="metadata">(Last modified: $($file.last_modified))</span>
            </div>
"@
        }
    }

    $htmlContent += @"
    </div>
</body>
</html>
"@

    $indexPath = Join-Path $dirPath "index.html"
    $htmlContent | Out-File -FilePath $indexPath -Encoding UTF8
}

Write-Host "Process complete! Output files are in: $outputDir"
