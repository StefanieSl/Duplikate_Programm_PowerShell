# Bildschirm loeschen
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
        $drive = Get-PSDrive -Name $letter
        write-host "Add $($drive.Root)"
        $selectedDrives += $drive
    }
    $drivesToCheck = $selectedDrives
}

# falsche Angabe

foreach($drive in $drivesToCheck) {
    Write-Host "Untersuche $($drive.Root) `n"
}