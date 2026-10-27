# Teststatus — 27. Oktober 2026

## Cloud-Prüfungen

`python3 tools/test.py --luau /path/to/luau --compiler /path/to/luau-compile [--api-dump /path/to/API-Dump.json]`

Die Prüfungen verwenden den offiziellen Luau-Compiler/Interpreter und Python. Sie ersetzen keinen Roblox-Studio-Test.

- Syntax-/Bytecode-Kompilierung aller 16 Luau-Dateien.
- 19 ausgeführte Regeltests: Profilstruktur, ungültige Zahlen, Käufe, Tagesfolgen, Glücksradverteilung, doppelte Belohnungen, XP-Schwellen, Meilensteine, Quests, Abstimmungen, Race-/Score-/Survival-Sieger, begrenzte Belege und längere Wirtschaftssimulation.
- 9 ausgeführte Tests mit Dienst-Doubles: Profil speichern/laden, konkurrierende Sitzungssperre, abgelaufene Sperre, verlorene Sperre, beschädigtes Profil, Load-/Save-Ausfälle und Wiederholversuche sowie Scope-Aufräumen/Abbruch verzögerter Callbacks.
- 8 Python-Prüfungen: vollständige Arenen/Spawns, eingebettete Original-Sources, Katalog-/Handler-/Asset-Verweise, interaktive Lobby, gültige Geometriezahlen, eindeutige XML-Eigenschaften/Referenzen, Audio und ZIP-Prüfsummen.
- Optionaler Abgleich aller serialisierten Studio-Eigenschaften und Enum-Werte gegen den Roblox-API-Dump.
- Reproduzierbarkeit: zwei Builds müssen dieselben SHA-256-Prüfsummen ergeben.

Der Speicher-Test verwendet einen kontrollierten DataStore-Ersatz. Er bestätigt Codepfade für Sperren/Fehler, **keine** Verbindung zum Roblox-Backend. XML-Prüfungen bestätigen die Lieferstruktur, **keinen** erfolgreichen Studio-Import. Die Cloud-Umgebung hat keine Roblox-Laufzeit.

## Noch nicht durchgeführt: verbindliche Studio-Abnahme

Diese Liste ist bewusst **offen**, keine vorgetäuschte Testbestätigung.

- [ ] `.rbxlx` in aktuellem Roblox Studio öffnen; Output auf Fehler prüfen.
- [ ] Play: Lobby sichtbar, HUD geladen, Eingaben funktionieren, Countdown startet.
- [ ] Server mit zwei echten Studio-Testclients: drei Optionen, getrennte Stimmen, Änderung einer Stimme, Entscheidung, beide werden teleportiert.
- [ ] Jedes der 15 Minispiele über das Owner-Panel auswählen und mit zwei Clients bis zum korrekten Ergebnis spielen.
- [ ] Plattformabstände, Ente-/Roboter-Wegsuche, Sumo-Rückstoß, Türen-Checkpoints und Ring-Erreichbarkeit in echter Physik prüfen.
- [ ] Alle 25 Events auslösen; nach Event-/Rundenende Gravitation, Größe, Geschwindigkeit, Kamera, Steuerung und Sichtbarkeit prüfen.
- [ ] Tod, Respawn, Disconnect, Beitritt mitten in einer Runde, AFK, Rundenabbruch und gleichzeitig erreichte Ziele prüfen.
- [ ] R6/R15-Ragdoll: automatisches Aufstehen, kein hängenbleibender Charakter, normale Steuerung nach Ende.
- [ ] Coins/XP/Wins korrekt; Siege, Quests und Tagesclaims mehrfach anfordern und auf doppelte Belohnungen prüfen.
- [ ] Studio-Persistenz aktivieren: kaufen, ausrüsten, verlassen, Server neu starten, Coins/Inventar/Settings/Claims wiederhergestellt.
- [ ] Zwei getrennte Server mit gleicher Test-UserId: aktive Sperre verhindert parallelen Profilbesitz; alte Daten nicht überschrieben.
- [ ] Globale Leaderboards nach erfolgreichem Save und Update-Intervall prüfen.
- [ ] Shop, Vorschau, alle 9 Pets/Favoriten, alle Cosmetics und 10 Emotes auf beiden Clients sichtbar.
- [ ] Alle 10 Lobby-Items verwenden; Minispiele erlauben keine Lobby-Items.
- [ ] Touch-Emulator in Hoch-/Querformat: Menü scrollen, Shop bedienen, springen, Item und Schubs; anschließend echtes Smartphone testen.
- [ ] Gamepad-Navigation und Standardbewegung testen.
- [ ] Freunde einladen, Gruppen beitreten/verlassen, privaten Server starten.
- [ ] Normaler Spieler kann keine Owner-Aktionen ausführen; ungültige Remote-Namen/IDs/Beträge und schnelle Requests verwerfen.
- [ ] Eigene Audio-Dateien hochladen, Berechtigungen setzen und jeden Sound im veröffentlichten Spiel prüfen.
- [ ] 16 Spieler bzw. entsprechender Studio-Lasttest: Frametimes, Speicher, Netzwerk, wiederholte Runden und Cleanup messen.

Bei Fehlern: Minispiel/Event, Anzahl Clients, Avatar-Typ und vollständigen Studio-Output notieren. Es gibt keine garantierte Framerate oder Garantie gegen Plattformausfälle.
