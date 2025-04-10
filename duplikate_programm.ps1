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

write-host "Welche Laufwerke wollen Sie untersuchen?"

# Usereingabe der gewünschten Laufwerke
read-host

# mit der restlichen Sammlung von Laufwerken (Schleife)