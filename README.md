# Fortnite-Tweaks

Ein eigenes Windows-Tool mit einem Competitive-Grafikprofil, Hardwareanzeige, Vorschau und Wiederherstellung. Ausgangspunkt ist ein PC mit Ryzen 7 5800X, NVIDIA RTX A4000, 32 GB DDR4 und Windows 11. Das Tool arbeitet mit der vorhandenen `GameUserSettings.ini` deines Windows-Benutzers. Administratorrechte und zusätzliche Pakete sind nicht erforderlich.

## Launcher als EXE starten

1. [Fortnite-Tweaks-Launcher.exe herunterladen](https://github.com/Justin44767/Fortnite-Tweaks/raw/refs/heads/main/dist/Fortnite-Tweaks-Launcher.exe).
2. Fortnite schließen.
3. Die EXE doppelt anklicken.

Die einzelne EXE enthält alle sieben benötigten Launcher-Dateien. Sie entpackt diese für die Laufzeit in einen eigenen temporären Ordner und entfernt ihn nach dem Beenden. Deine Fortnite-Einstellungen und Sicherungen bleiben an ihren bisherigen Speicherorten. Der Launcher benötigt die in Windows 11 enthaltenen Komponenten .NET Framework 4.8 und Windows PowerShell 5.1. Administratorrechte sind nicht erforderlich.

Die EXE ist **nicht mit einem Herausgeberzertifikat signiert**. Windows kann deshalb einen Hinweis zum unbekannten Herausgeber anzeigen. Die [SHA256-Prüfsumme](dist/Fortnite-Tweaks-Launcher.exe.sha256) ermöglicht den Vergleich mit der veröffentlichten Datei:

```powershell
Get-FileHash .\Fortnite-Tweaks-Launcher.exe -Algorithm SHA256
```

Bei einem Startfehler zeigt die EXE die Fehlermeldung und gegebenenfalls den Pfad eines Protokolls unter `%LOCALAPPDATA%\Fortnite-Tweaks\Logs` an.

## Controller und Tastatur

Über **Controller / Tastatur** links springst du zu den neuen Eingabebereichen. Beim Öffnen des Launchers werden keine Eingabeeinstellungen geändert.

### Victrix PRO BFG

**Sticks prüfen** liest eine Momentaufnahme angeschlossener Xbox-kompatibler XInput-Controller: Auslenkung des linken und rechten Sticks sowie der Trigger. Lege den Controller dafür ruhig ab und wiederhole die Prüfung. Die Anzeige ist **keine Messung der Eingabelatenz oder Pollingrate**. Ein nicht über XInput erfasstes Gerät kann trotzdem in Windows und Fortnite funktionieren; **Windows-Controller öffnen** öffnet dafür die Windows-Geräteprüfung (`joy.cpl`). Der Launcher installiert weder Treiber noch Eingabe-Emulation.

Für deinen Victrix PRO BFG:

- Den laut Handbuch passenden Windows-/PC-Modus deiner Variante wählen. USB direkt am PC mit dem Original-Funk-Dongle im gleichen Spielszenario vergleichen; nicht jede Verbindung ist bei jedem Gerät gleich schnell.
- Die passende offizielle Victrix-Software für Firmware und gegebenenfalls Kalibrierung verwenden. **Victrix Control Hub suchen** öffnet nur eine Suche im Microsoft Store. Prüfe dort den offiziellen Herausgeber und die Kompatibilität deiner Variante. Die App wird nicht automatisch installiert.
- Trigger-Stops auf einen kürzeren Weg testen und die Auslösung im Spiel prüfen. Das verändert den Betätigungsweg, nicht die USB-Übertragungszeit.
- In Fortnite die Stick-Totzonen schrittweise reduzieren, solange keine ungewollte Bewegung entsteht. Beim ersten Drift den betroffenen Wert wieder erhöhen. Eine kleinere Totzone erkennt kleinere Bewegungen früher; sie verändert keine Hardware-Pollingrate.
- Die Blickdämpfungszeit für direktere Kamerabewegungen reduzieren, gegebenenfalls bis 0,00 s, wenn diese Option angeboten wird. Das verändert das Zielgefühl. Wenn du zum Bearbeiten eine Taste halten musst, zusätzlich die Bearbeitungshaltezeit im Spiel testen.

Diese Fortnite-Controllerwerte stellst du im Spiel ein. Der Launcher enthält eine Einstellhilfe und eine Geräteprüfung; er schreibt hierfür keine ungeprüften Schlüssel in die Fortnite-Datei. Sensitivität, Totzonen und Dämpfung sind persönliche Steuerungseinstellungen und kein Nachweis einer geringeren Gesamtlatenz.

### Kemove-Tastatur

Der Launcher zeigt den Zustand der Windows-**Filtertasten** und deren Annahmeverzögerung. Diese Bedienungshilfe kann Anschläge verzögern oder unterdrücken. Wenn du sie nicht benötigst, deaktiviert **Filtertasten deaktivieren** ausschließlich deren Aktivierungsbit über die dokumentierte Windows-API. Shortcut-Flags und alle gespeicherten Zeitwerte bleiben erhalten. Bei bereits deaktivierten Filtertasten erfolgt keine Änderung und es wird kein zusätzlicher Geschwindigkeitsvorteil behauptet.

Vor einer tatsächlichen Änderung wird der vollständige vorherige Filtertasten-Zustand unter `%LOCALAPPDATA%\Fortnite-Tweaks\State\keyboard.json` gespeichert. **Tastaturzustand zurücksetzen** stellt ihn auch nach einem Neustart des Launchers wieder her. Hat eine andere Anwendung oder Windows diese Werte inzwischen geändert, überschreibt der Launcher sie nicht automatisch. Das Zurücksetzen der Fortnite-INI wirkt nicht auf diese separate Windows-Sicherung.

**Windows-Tastatureinstellungen** öffnet die zugehörige Windows-Seite. Wenn du Filtertasten als Bedienungshilfe benötigst, behalte sie bei. Tastaturwiederholung, Anschlagspunkt, Debounce und Firmware sind unterschiedliche Funktionen. Für deine Kemove ist zuerst die genaue Modellnummer auf Unterseite oder Verpackung nötig, bevor passende Herstelleroptionen gewählt werden können. Es wird keine Pollingrate oder Firmware automatisch umgestellt.

Technische Referenzen: Microsoft dokumentiert [FILTERKEYS](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-filterkeys), [SystemParametersInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) und [XInputGetState](https://learn.microsoft.com/en-us/windows/win32/api/xinput/nf-xinput-xinputgetstate). Der Quellcode der offiziellen FILTERKEYS-Dokumentation wurde bei der Implementierung geprüft.

## Optimierungen manuell auswählen

Im Bereich **Deine Auswahl** sind anfangs alle Häkchen abgewählt. Wähle die gewünschten Optionen und klicke auf **Auswahl mit Sicherung anwenden**. Ein Häkchen bestimmt die nächste Anwendung; es ändert allein noch keinen Wert und zeigt nicht den derzeitigen Aktivierungszustand an. Dieser steht unter der jeweiligen Option. Abwählen setzt bereits angewendete Änderungen nicht zurück: Dafür nutzt du die Dateisicherungen unter **Komplettes Profil und Dateisicherungen**.

| Option | Wirkung und Abwägung |
| --- | --- |
| Schatten und Beleuchtung | Niedrige Schatten, globale Beleuchtung und Reflexionen können die GPU entlasten; die Darstellung verändert sich. |
| Effekte reduzieren | Niedrige Effekte, Nachbearbeitung, Vegetation und Shading können bei grafikintensiven Szenen helfen. |
| Texturen und Kantenglättung | Mittlere Texturen und niedrige Kantenglättung; der Nutzen hängt von Rendering-Modus und Last ab. |
| VSync deaktivieren | Kann die Eingabeverzögerung reduzieren, aber Bildrisse verursachen. Bei G-SYNC/VRR hängt die passende Einstellung vom gesamten Setup ab. |
| Bewegungsunschärfe deaktivieren | Klareres Bild bei Bewegung; kein garantierter FPS-Gewinn. |
| Eigenes FPS-Limit | Übernimmt ausschließlich bei ausgewählter Option eine ganze Zahl zwischen 30 und 1000. Ein stabiles Limit kann Frametimes und GPU-Warteschlangen verbessern; es erhöht nicht die maximalen FPS. |

Ohne die FPS-Option bleibt das vorhandene FPS-Limit erhalten. Unausgewählte Grafikwerte bleiben ebenfalls erhalten. Jede tatsächliche Änderung erstellt eine Sicherung. Teste möglichst eine Option nach der anderen im selben Szenario und vergleiche FPS und Frametimes. Die Optionen betreffen Rendering und Bilddarstellung; eine Verbesserung des Netzwerk-Pings wird nicht versprochen.

**Energieplan testen** aktiviert auf Wunsch den bereits vorhandenen Windows-Plan **Hohe Leistung**. Der zuvor aktive Plan wird unter `%LOCALAPPDATA%\Fortnite-Tweaks\State\power-plan.json` gespeichert und lässt sich über **Vorherigen Plan wiederherstellen** zurückholen, auch nach dem Schließen des Launchers. Auf deinem Ryzen 5800X kann Ausbalanciert gleich gut oder besser laufen. Hohe Leistung kann Stromverbrauch und Wärme erhöhen; teste den Unterschied. Bietet Windows diesen Plan nicht an, bleibt die Schaltfläche deaktiviert. Es werden keine Energiepläne erzeugt oder Richtlinien umgangen. Ein außerhalb des Launchers ausgewählter anderer Energieplan wird bei der Wiederherstellung nicht überschrieben.

Über **Spielmodus öffnen** und **Spielaufnahmen** erreichst du die Windows-Einstellungen. Dort kannst du Spielmodus beziehungsweise Hintergrundaufnahme selbst ändern. Diese Schaltflächen ändern keine Windows-Einstellungen. **NVIDIA Reflex** stellst du direkt in Fortnite ein, sofern der gewählte Rendering-Modus es anbietet; starte für deinen PC mit **Ein** und vergleiche das Ergebnis.

Das bisherige vollständige Competitive-Profil und alle Dateisicherungen befinden sich im aufklappbaren Bereich **Komplettes Profil und Dateisicherungen**. Die Wiederherstellung einer Datei setzt die gesamte Datei auf diesen Stand zurück, einschließlich des FPS-Limits und späterer Einstellungen.

## Grafischen Launcher aus dem Quellcode starten

1. Den **gesamten Projektordner** auf deinen Windows-PC herunterladen und gegebenenfalls entpacken.
2. Fortnite schließen.
3. **`Start.cmd` doppelt anklicken.**

Der Launcher zeigt deine Hardware, die wählbaren Optimierungen, die Profilvorschau und deine Sicherungen. Zur Wiederherstellung wählst du einen Sicherungszeitpunkt aus; der Launcher fragt vor dem Zurücksetzen der gesamten Datei nach. Über **Datei auswählen** kannst du eine abweichende `GameUserSettings.ini` öffnen. Nach Änderungen im Spiel oder dem Beenden von Fortnite klickst du auf **Aktualisieren**.

Windows PowerShell 5.1 und die Windows-Oberfläche WPF sind bereits in Windows 11 enthalten. Der Launcher lädt nichts nach. `Start.cmd` verwendet `RemoteSigned` ausschließlich für den gestarteten PowerShell-Prozess und verändert keine dauerhaft gespeicherte Ausführungsrichtlinie. Signaturanforderungen für heruntergeladene Skripte bleiben bestehen; eine durch deine Organisation vorgegebene Richtlinie hat Vorrang.

Wird ein heruntergeladenes ZIP blockiert, prüfe die Herkunft und den Inhalt. Bei vertrauenswürdiger Herkunft kannst du in den Dateieigenschaften des ZIPs **Zulassen** wählen und es erneut entpacken. Für bereits entpackte, geprüfte Dateien steht dieselbe Option gegebenenfalls in ihren Eigenschaften zur Verfügung. Bei einem Startfehler bleibt das Konsolenfenster mit der Fehlermeldung offen.

Alternativ aus Windows PowerShell starten:

```powershell
powershell.exe -NoProfile -STA -File .\Launcher.ps1
```

Der Launcher benötigt Windows und einen STA-PowerShell-Prozess. In PowerShell 7 lautet der Startbefehl `pwsh -NoProfile -STA -File .\Launcher.ps1`. Mit `-ConfigPath` und `-BackupRoot` kannst du auch hier eigene Pfade angeben.

## Konsolenmenü starten

1. Fortnite einmal starten und danach vollständig beenden, damit die Einstellungsdatei vorhanden ist.
2. Den Projektordner in Windows PowerShell öffnen (Windows PowerShell 5.1 oder PowerShell 7).
3. Das Menü starten:

```powershell
.\Fortnite-Tweaks.ps1
```

Falls Windows die heruntergeladenen Skripte blockiert, prüfe zuerst ihren Inhalt und ihre Herkunft. Beachte die Skriptrichtlinie deines PCs; das Tool ändert sie nicht.

## Was das Profil ändert

| Einstellung | Profilwert |
| --- | --- |
| Kantenglättung, Schatten, globale Beleuchtung, Reflexionen | Qualitätsstufe 0 |
| Nachbearbeitung, Effekte, Vegetation, Shading | Qualitätsstufe 0 |
| Texturen | Qualitätsstufe 1 (mittel) |
| VSync | Aus |
| Bewegungsunschärfe | Aus |

Auflösung, Auflösungsskalierung, Sichtweite, FPS-Limit, Tastenbelegung und Rendering-Modus bleiben erhalten. VSync aus kann Bildrisse verursachen; niedrigere Grafikdetails verändern die Darstellung. Fortnite kann abhängig von Version und Rendering-Modus einzelne Werte ignorieren oder beim Start überschreiben. Prüfe sie deshalb anschließend im Spiel.

Für deinen PC: Vergleiche den Performance-Modus mit DX12 nach einer Aufwärmphase im selben Szenario. NVIDIA Reflex kannst du, sofern im gewählten Modus angeboten, zunächst auf **Ein** testen. Das Tool verändert diese Optionen nicht automatisch.

Das Profil ist ein Ausgangspunkt. Ob es FPS oder Frametimes verbessert, hängt von deinem PC und den bisherigen Einstellungen ab. Es gibt keine gemessene Leistungszusage.

## Vorschau, Anwenden und Wiederherstellen

```powershell
# Zielpfad und Profilwerte anzeigen (keine Auswertung der aktuellen Grafikwerte).
.\Fortnite-Tweaks.ps1 -Action Status

# CPU, GPU, Treiberversion, RAM und Windows-Version anzeigen.
.\Fortnite-Tweaks.ps1 -Action System

# Geplante Dateioperation anzeigen; verändert weder Einstellungen noch Sicherungen.
.\Fortnite-Tweaks.ps1 -Action Apply -WhatIf

# Sicherung erstellen und Profil eintragen.
.\Fortnite-Tweaks.ps1 -Action Apply

# Sicherungen auflisten.
.\Fortnite-Tweaks.ps1 -Action Backups

# Neueste Sicherung von einer Profilanwendung wiederherstellen.
.\Fortnite-Tweaks.ps1 -Action Restore

# Bestimmte Sicherung anhand ihres vollständigen Namens aus der Liste wählen.
.\Fortnite-Tweaks.ps1 -Action Restore -BackupName 'apply-<Zeitstempel>-<ID>.ini'
```

Standarddatei: `%LOCALAPPDATA%\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini`. Bei einer abweichenden Installation kannst du `-ConfigPath 'C:\vollständiger\Pfad\GameUserSettings.ini'` angeben.

Sicherungen liegen unter `%LOCALAPPDATA%\Fortnite-Tweaks\Backups`, getrennt nach dem vollständigen Pfad der Einstellungsdatei. `-BackupRoot` erlaubt ein anderes Verzeichnis; nutze bei der Wiederherstellung denselben Wert. Vor jeder tatsächlichen Profiländerung wird der vorherige Dateiinhalt unverändert mit SHA256-Prüfsumme gesichert. Wiederholtes Anwenden eines bereits eingetragenen Profils erzeugt keine zusätzliche Sicherung.

Eine Wiederherstellung prüft die Prüfsumme und sichert vorher den aktuellen Zustand als `before-restore-*.ini`. Diese zusätzlichen Sicherungen beeinflussen die Auswahl der neuesten `apply-*.ini` nicht. Bei mehreren Anwendungen enthält die älteste `apply`-Sicherung den ursprünglichen Zustand. Die Wiederherstellung setzt die **gesamte Datei** zurück, einschließlich später im Spiel geänderter Einstellungen. Schreibe Sicherungen nicht um und bewahre sie bei einem PC-Wechsel auf.

Das Tool verweigert Änderungen bei laufendem Fortnite, einer schreibgeschützten Datei oder nicht erkannten Einstellungen. Es erhält UTF-8/UTF-16-Kodierung und ersetzt die Datei erst, nachdem die Sicherung geschrieben wurde.

## Auf deinem PC vergleichen

Nutze vor und nach der Änderung dieselbe Fortnite-Version, Auflösung, FPS-Grenze und Rendering-Einstellung. Spiele dieselbe Szene oder Wiederholung nach einer Aufwärmphase mehrfach ab. Vergleiche Durchschnitts-FPS und Ruckler beziehungsweise Frametimes. Ein einzelnes Match ist wegen wechselnder Last kein verlässlicher Vergleich. Bei schlechterem Ergebnis kannst du die Sicherung wiederherstellen.

## Entwicklung und Prüfungen

```powershell
# EXE unter Windows mit dem vorhandenen .NET-Framework-Compiler erstellen.
powershell.exe -NoProfile -File .\build\Build-Launcher.ps1

# Dateiverarbeitung, Vorschau, Paketinhalt und auf Windows die Oberfläche prüfen.
pwsh -NoProfile -File .\tests\Run-Tests.ps1
```

Der EXE-Quellcode steht in `build/Bootstrap.cs`, das Build-Skript in `build/Build-Launcher.ps1`. Nach Änderungen an den eingebetteten Launcher-Dateien muss die EXE neu gebaut werden; die Tests erkennen ein veraltetes Paket. GitHub Actions baut und prüft zusätzlich auf Windows und stellt EXE und Prüfsumme als Build-Artefakt bereit.

Für einen Build unter Linux benötigt das Skript PowerShell 7 mit Roslyn und `-ReferenceDirectory <absoluter-Pfad>` zu den .NET-Framework-4.8-Referenzassemblies. Der hier verwendete Referenzsatz ist das offizielle NuGet-Paket `Microsoft.NETFramework.ReferenceAssemblies.net48` in Version `1.0.3`. Der Paketdownload wurde gegen den SHA512-Wert des NuGet-Katalogs geprüft. Referenzassemblies werden nicht mit der EXE ausgeliefert.

Die Tests benötigen keine weiteren Pakete. Sie bearbeiten ausschließlich temporäre Beispieldateien und prüfen Profilanwendung, unveränderte andere Einstellungen, Sicherungen, Wiederherstellung, Wiederholbarkeit, Vorschau und Fehlerfälle. Sie laufen auch unter PowerShell 7 auf Linux. Das Hauptprogramm benötigt Windows.

Die Tests bestätigen die Dateiverarbeitung, die Vorschau, den Inhalt der EXE sowie die Sicherungs- und Rücksetzlogik für Filtertasten mit einem simulierten Windows-Adapter. Der native C#-Teil wird kompiliert; seine Win32-Strukturlayouts und Stick-Normalisierung werden geprüft. Die Windows-Tests prüfen zusätzlich die Oberfläche, die lesende Filtertasten-Abfrage und starten die EXE mit `--verify-payload`. Die automatischen Tests verändern keine echten Tastatureinstellungen. Unter Linux werden Windows-Prüfungen ausdrücklich übersprungen. Die Wirkung auf Fortnite, reale Geräte und die visuelle Darstellung müssen auf einem Windows-PC geprüft werden.
