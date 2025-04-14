
# Optimiertes PowerShell-Skript zur Duplikaterkennung in großen Dateibeständen

$minSize = 10240
$outfile = "duplicates{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmm")
$teilhashSize = 4096
 

function Get-TeilHash($file, $size = $teilhashSize) {
    try {
        $stream = [System.IO.File]::OpenRead($file)
        $buffer = New-Object byte[] $size
        $read = $stream.Read($buffer, 0, $size)
        $stream.Close()
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $hash = $md5.ComputeHash($buffer, 0, $read)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "")
    } catch {
        return $null
    }
}

function Get-VollHash($file) {
    try {
        return (Get-FileHash -Algorithm MD5 -Path $file -ErrorAction SilentlyContinue).Hash
    } catch {
        return $null
    }
}

Clear-Host
Write-Host "Programm zum Auffinden von doppelten Dateiinhalten `n"

$drives = Get-PSDrive -PSProvider FileSystem # | Where-Object {$_.Free -ne $null} (auskommentiert, da an diesem PC keine Angaben zu Inhalten vorhanden)
Write-Host "Zur Auswahl stehen die Laufwerke:`n"
$drives | ForEach-Object { Write-Host $_ }

$drivesToCheck = Read-Host "`nWelche Laufwerke wollen Sie untersuchen? (alle oder z. B. C,D)"
if ($drivesToCheck -eq "alle") {
    $selectedDrives = $drives
} else {
    $letters = $drivesToCheck -split ',' | ForEach-Object { $_.Trim().ToUpper() }
    $selectedDrives = $letters | ForEach-Object {
        Get-PSDrive -Name $_ -ErrorAction SilentlyContinue
    }
}

$exclude =  @(
        "C:\Windows",
        "C:\System Volume Information",
        "C:\$Recycle.Bin",
        "C:\Program Files",
        "C:\Program Files (x86)",
        "C:\Users\cppde\.p2"
    )


$jobs = @()
$countFiles =0
foreach ($drive in $selectedDrives) 
{
    $root = $drive.Root
    # $excluded = Get-ExcludedPaths $root
    write-host "Job started on $drive "
    $jobs += Start-Job -ScriptBlock {
        param($root, $exclude, $minSize)
        $localMap = @{}
        Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $fullPath = $_.FullName
                ($_.Length -ge $minSize) -and 
                ($exclude | Where-Object { $fullPath.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }).Count -eq 0
            } |
            ForEach-Object {
            # $countFiles++
                if (-not $localMap.ContainsKey($_.Length)) {
                    $localMap[$_.Length] = @()
                }
                $localMap[$_.Length] += $_.FullName
            }
        return $localMap
    } -ArgumentList $root, $exclude, $minSize
}

write-host "Dateigrößen sammeln"
$sizeMap = @{}
foreach ($job in $jobs) {
    
    write-host "Dateigrößen sammeln auf $($job.Name)"
    $result = Receive-Job -Job $job -Wait
   
    foreach ($kvp in $result.GetEnumerator()) {
        if (-not $sizeMap.ContainsKey($kvp.Key)) {
            $sizeMap[$kvp.Key] = @()
        }
        $sizeMap[$kvp.Key] += $kvp.Value
    }
    write-host "Beenden $($job.Name)"
    Remove-Job $job
}
write-host "sizeMap hat $($sizeMap.Count) Einträge"
Add-Content -Path $outfile -Value "sizeMap hat $($sizeMap.Count) Einträge"
write-host " Duplikatsuche mit Teil- und VollHash "
$hashMap = @{}
write-host " Duplikatsuche mit Teil "
foreach ($entry in $sizeMap.GetEnumerator()) {
    $files = $entry.Value
    if ($files.Count -ge 2) {
        $preHashMap = @{}
        foreach ($file in $files) {
            $preHash = Get-TeilHash $file
            if ($preHash) {
                if (-not $preHashMap.ContainsKey($preHash)) {
                    $preHashMap[$preHash] = @()
                    #write-host "Neuer Teilhash $preHash"
                }
                $preHashMap[$preHash] += $file
                #write-host " Teilhash $($preHashMap.count)"
            }
        }
        write-host " Duplikatsuche mit Vollhash "
        foreach ($group in $preHashMap.GetEnumerator()) {
            if ($group.Value.Count -ge 2) {
                foreach ($file in $group.Value) {
                    $fullHash = Get-VollHash $file
                    if ($fullHash) {
                        if (-not $hashMap.ContainsKey($fullHash)) {
                            $hashMap[$fullHash] = @()
                            write-host "Neuer Vollhash $fullHash"
                        }
                        $hashMap[$fullHash] += $file
                        write-host " Vollhash $($hashMap.count)"
                    }
                }
            }
        }
    }
}

write-host " Ausgabe "
foreach ($entry in $hashMap.GetEnumerator()) 
{
    $files = $entry.Value
    if ($files.Count -ge 2) {
        $space = 0
        Add-Content -Path $outfile -Value "Hash: $($entry.Key)"
        foreach ($f in $files) {
            Write-Host " $f"
            Add-Content -Path $outfile -Value "  $f"
            $space += (Get-Item $f).Length
        }
        Add-Content -Path $outfile -Value "→ $($files.Count) Dateien mit gleichem Inhalt`n"
        Add-Content -Path $outfile -Value "→ $($space ) Platzbedarf`n"
  
    }
}
Add-Content -Path $outfile -Value "Insgesamt $($hashMap.Count) Größengruppen auf $drivesToCheck`n"
$endOfJob = "Ende: $(Get-Date -Format 'yyyyMMdd_HHmm')"
Add-Content -Path $outfile -Value $endOfJob