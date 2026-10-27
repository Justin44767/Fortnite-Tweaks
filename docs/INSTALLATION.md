# Installation und Veröffentlichung

## Fertige Studio-Datei

`dist/NeroChaosParty-Download.zip` herunterladen und entpacken (Windows: Rechtsklick → **Alle extrahieren**). Die darin enthaltene `NeroChaosParty.rbxlx` in Roblox Studio mit **File → Open from File** öffnen. Das ZIP verhindert, dass der Browser die Studio-Datei als Text anzeigt. Die Lobby ist bereits im Workspace sichtbar. Alle Arena-Vorlagen liegen in **ServerStorage → Maps**; Modelle für Pets und Requisiten in **ReplicatedStorage → Assets**.

Mit **Play** startet das Spiel. Der erste Countdown beginnt, sobald ein Spieler samt Charakter und Profil bereit ist. Es folgen 15 Sekunden Pause, 12 Sekunden Abstimmung und das gewählte Spiel. Neue Spieler steigen in der nächsten Runde ein. AFK-Spieler setzen aus. Solo-Tests funktionieren; Hot Potato verwendet allein einen Kühlpunkt am rechten Bumper.

Für einen echten Mehrspielertest **Test → Server & Clients → 2 Clients → Start** verwenden. Für Smartphone-/Gamepad-Tests zusätzlich den Studio-Geräteemulator bzw. einen Controller nutzen. Die Standardsteuerung von Roblox bleibt vorhanden.

## Experience konfigurieren

1. Über **Publish to Roblox** eine Experience unter deinem Konto oder deiner Gruppe erstellen.
2. Maximal **16 Spieler** pro Server setzen; PC, Mobilgeräte und gewünschte Controller-Plattformen freigeben. R15 wird empfohlen; das Ragdoll-System berücksichtigt auch R6-Gelenke.
3. Bei Gruppenbesitz in `ReplicatedStorage/Shared/Config` unter `OwnerUserIds` deine numerische Roblox UserId ergänzen. Anzeigenamen vergeben keine Rechte. Bei persönlichem Besitz hat der Place-Creator automatisch Owner-Rechte.
4. Optional `VipUserIds` für den sozialen Lounge-Zugang pflegen. Es gibt keine Gamepass-Käufe oder Gameplay-Boni. Der VIP-Bereich ist Teil der offenen Party-Lobby, keine Sicherheitszone.
5. Für Freunde dieselbe Experience teilen oder im Spiel **PARTY → ROBLOX-FREUNDE EINLADEN** verwenden. Roblox kann Einladungen in Studio oder aufgrund von Kontoeinstellungen ablehnen; das Spiel zeigt dann eine Erklärung. Private Server funktionieren mit derselben Rundenfolge.
6. Nach der Abnahme Zugriffsrechte/Veröffentlichungsstatus im Creator Dashboard setzen. GitHub-Veröffentlichung lädt keine Experience zu Roblox hoch.

## Speicherung

Live-Server verwenden `DataStoreService` und `NeroChaosParty_v1`. Ein Spielerprofil enthält seine Daten und eine erneuerbare 180-Sekunden-Sitzungssperre. Auto-Saves erfolgen alle 45 Sekunden, zusätzlich nach Runden, Käufen, Tagesbelohnungen und beim Verlassen/Herunterfahren. Temporäre Fehler werden viermal mit Wartezeit versucht. Ein fehlerhaftes oder gesperrtes Profil wird **nicht** durch einen neuen Null-Spielstand überschrieben.

Studio verwendet standardmäßig **flüchtige Testprofile** (`StudioPersistence=false`). Das ist im HUD und Profil sichtbar. Für echte Speicherprüfungen:

1. Experience veröffentlichen.
2. In Studio den API-Zugriff für DataStores aktivieren (Experience-/Security-Einstellungen).
3. `Config.StudioPersistence=true` setzen. Studio nutzt dann ausschließlich `NeroChaosParty_v1_Studio`, getrennt vom Live-Spielstand.
4. Coins erspielen, Server sauber beenden und erneut verbinden. Ausgerüstete Pets, Einstellungen, tägliche Claims und Inventar prüfen.

Ein unerwarteter Serverabbruch kann Änderungen seit dem letzten erfolgreichen Save verlieren. Netzwerk-/Plattformausfälle lassen sich nicht ausschließen. Bei gesperrter Sitzung kurz warten und erneut beitreten; nicht den Store löschen. Bei Schemafehlern zuerst das vorhandene Profil sichern. Globale Ranglisten aktualisieren sich alle zwei Minuten und verwenden erfolgreich gespeicherte Schnappschüsse; in Studio ohne Persistenz zeigen sie ausdrücklich Studio-Sitzungswerte.

## Sounds

Alle zehn WAV-Dateien in `assets/audio` sind im Projekt synthetisiert und dürfen mit dem beigefügten Code verwendet werden. Über den Roblox Asset Manager/Creator Hub unter dem Besitzer der Experience hochladen und für die Experience freigeben. Die jeweiligen `rbxassetid://NUMMER`-Werte in `Config.Audio` einsetzen:

`Bounce`, `Fall`, `Chicken`, `Duck`, `Horn`, `Victory`, `Countdown`, `Explosion`, `LevelUp`, `Music`.

Ohne Upload verwendet das Spiel Roblox-eigene kurze Effekttöne. Musical Platforms hat einen gepulsten Takt als Fallback. Die eigenen WAV-Dateien lassen sich nicht als lokale Dateien in einer veröffentlichten Experience abspielen. Keine erfundenen Audio-IDs sind eingetragen.

## Bedienung

| Aktion | PC | Gamepad | Touch |
|---|---|---|---|
| Bewegen / springen | Roblox-Standard | Roblox-Standard | Standard-Joystick und Sprung |
| Sumo-Schubs | E | X | SCHUBS |
| Lobby-Item | Q | R2 | ITEM |
| Emote-Wheel | B | Y | EMOTES in der Menüleiste |
| Einstellungen | M | Menübuttons auswählen | ⚙ in der Menüleiste |
| Doppelter Sprung | Erneut springen, wenn Event aktiv | Erneut springen | Sprung erneut drücken |

Die untere Menüleiste lässt sich horizontal scrollen. Das Glücksrad kostet nichts und ist einmal pro UTC-Kalendertag verfügbar.

## Quellcode importieren

Am einfachsten die fertige `.rbxlx` verwenden. Alternativ `python3 tools/build.py`, danach mit Rojo `rojo build default.project.json -o NeroChaosParty.rbxlx` oder `rojo serve` und dem Studio-Plugin synchronisieren. Rojo wurde in dieser Cloud-Umgebung nicht ausgeführt; der direkte Python-XML-Build ist das getestete Lieferformat.
