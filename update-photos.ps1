# Scans Photography_media/ subfolders and writes photography-manifest.js
# Run this after adding or removing photos, then commit.
# Galleries listed in this order; unlisted folders appended alphabetically.

$galleryOrder = @('Warm Nature', 'Animals', 'Outdoor', 'Studio')

# Override covers: folder name → filename (otherwise first photo alphabetically)
$coverOverrides = @{
    'Outdoor' = 'BarisonMatteo_Extra_01.jpg'
    'Animals' = 'Still 2026-05-10 133233_1.3.1.jpg'
}

$root = $PSScriptRoot
$mediaDir = Join-Path $root "Photography_media"
$outFile  = Join-Path $root "photography-manifest.js"

$allFolders = Get-ChildItem -Path $mediaDir -Directory |
    Where-Object { $_.Name -ne 'hq' }

# Sort: pinned order first, then alphabetical for any new folders
$sorted = @()
foreach ($name in $galleryOrder) {
    $match = $allFolders | Where-Object { $_.Name -eq $name }
    if ($match) { $sorted += $match }
}
$sorted += $allFolders | Where-Object { $_.Name -notin $galleryOrder } | Sort-Object Name

$galleries = @()

$sorted | ForEach-Object {
        $folder = $_.Name
        $photos = Get-ChildItem -Path $_.FullName -File |
            Where-Object { $_.Extension -match '^\.(jpe?g|png|webp)$' } |
            Sort-Object Name |
            ForEach-Object { $_.Name }

        if ($photos.Count -gt 0) {
            $galleries += @{
                title  = $folder
                folder = "Photography_media/$folder"
                cover  = if ($coverOverrides.ContainsKey($folder) -and ($photos -contains $coverOverrides[$folder])) { $coverOverrides[$folder] } else { $photos[0] }
                photos = @($photos)
            }
        }
    }

$json = $galleries | ConvertTo-Json -Depth 3 -Compress
$js = "window.PHOTOGRAPHY_MANIFEST = $json;"
[System.IO.File]::WriteAllText($outFile, $js, [System.Text.UTF8Encoding]::new($false))

Write-Host "Wrote $($galleries.Count) galleries to photography-manifest.js"
foreach ($g in $galleries) {
    Write-Host "  $($g.title): $($g.photos.Count) photos (cover: $($g.cover))"
}
