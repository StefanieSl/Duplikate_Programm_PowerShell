
cls

# Ueberschrift: Zweck des Programms anzeigen
write-host "Programm zum Auffinden von doppelten Dateiinhalten"

# Vorhandene Laufwerke ermitteln
$drives = Get-PSDrive -PSProvider FileSystem  |
        Where-Object {$_.Root -ne $null}

# dem Anwender die Auswahl anbieten
write-host "Zur Auswahl stehen die Laufwerke "
foreach($drive in $drives) {
    write-host $drive
}


# Usereingabe der gewünschten Laufwerke
$drivesToCheck = read-host "Welche Laufwerke wollen Sie untersuchen?`n Eingabe 'alle' oder einzelne Laufwerke, getrennt mit Komma"

# Auswerten der Usereingabe

if($drivesToCheck -eq "alle") {

    # alle: auf jedem Laufwerk suchen
    $drivesToCheck = $drives

} else {

    # ein oder mehrere Laufwerke // c c,e c,d,e c,
    $array = $drivesToCheck -split ','
    
    #selectedDrives wird leeres Array
    $selectedDrives = @()

    foreach($letter in $array) {
        # Eingabe in Laufwerk umwandeln // falsche Eingabe verhindern
        if($letter -match '[A-Za-z]$') {
            $drive = Get-PSDrive -Name $letter -ErrorAction SilentlyContinue
            write-host "Add $($drive.Root)"
            $selectedDrives += $drive
        }
    }
    $drivesToCheck = $selectedDrives
}

# Map initialisiern
$sizeMap = @{} # map<int,stringList> sizemap

cls

foreach($drive in $drivesToCheck) {
    Write-Host "Untersuche $($drive.Root) `n"

    # Ergebnisse nach Größe sortieren // nur Dateien anzeigen
    Get-Childitem -Path $drive.Root -Recurse -File -ErrorAction SilentlyContinue |
        
        # Lambda-Funktion: Länge und Namen in die Map schreiben
        ForEach-Object {
            
            # Leere Map anlegen
            if(-not $sizeMap. ($_.Length)) {
                $sizeMap[$_.Length] = @()
            }

            $sizeMap[$_.Length] += $_.FullName
        }
}

# Lambda Funktion: Key und Value festlegen und Dateien entsprechend mit absteigender Größe ausgeben
foreach ($entry in $sizeMap.GetEnumerator() | Sort-Object name -Descending) {
    $key = $entry.Key
    $files = $entry.Value

    # Neue Map nach Hashwert
    $hashMap = @{}
    
    # nur Dateien mit Duplikat ausgeben
    if ($files.Count -ge 2) {
        Write-Host "Dateien mit $key Byte:"
        
        # Dateien mit gleichen Hashwerten gruppieren
        foreach($file in $files) {
            if(-not $hashMap.ContainsKey((Get-FileHash -Algorithm MD5 -Path $file).Hash)) { #To Do: Funktion in Variable speichern (Get... $file)
                $hashMap[(Get-FileHash -Algorithm MD5 -Path $file)] = @()
            }
            
            $hashMap[(Get-FileHash -Algorithm MD5 -Path $file).Hash] += $file
        }

        $duplicates = $hashMap.Values
        if($duplicates.Count -gt 1) {
            foreach($dfile in $duplicates) {
                Write-Host "$dfile"
            }
        }
        
        write-host "Insgesamt $($files.Count) Dateien.`n"    
    }
}