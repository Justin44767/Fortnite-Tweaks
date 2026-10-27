# Architektur

`tools/build.py` erzeugt ohne fremde Modelle die sichtbare Lobby, 15 vollständige Arena-Vorlagen, 18 Requisiten-/Pet-Modelle und 10 Audio-Dateien. Es bettet die Luau-Sources unverändert in ein Roblox-XML-Place ein. Beim Rundenwechsel wird nur eine Arena in den Workspace geklont. Streaming bleibt für die kleinen getrennten Arenen bewusst aus.

## Laufzeit

| Modul | Verantwortung |
|---|---|
| `shared/Config` | Timing, Store-Namen, Owner-IDs, Audio, Version |
| `shared/Catalog` | Spiel-/Event-Definitionen, Shops, Pets, Items, Quests |
| `shared/Rules` | Reine Wirtschaft, Tagesclaims, XP, Abstimmung und Gewinner |
| `shared/Scope` | Verbindungen, Objekte, Rücksetzfunktionen und verzögerte Callbacks |
| `server/Main` | Dienste, Remote-Validierung, Lobby-Interaktionen, Owner-Panel, Leaderboards |
| `server/RoundManager` | Waiting → Intermission → Voting → Playing → Results |
| `server/Context` | Teilnehmer, Ausscheiden, Ziele, Grenzen, Schubser und Rundenobjekte |
| `server/Minigames` | 15 unterschiedliche Spielmechaniken |
| `server/ChaosEvents` | 25 Effekte; ein normales Chaos-Event zur Zeit, 8 Sekunden Standarddauer |
| `server/Ragdoll` | Temporäre Motor6D-/BallSocket-Umstellung und Wiederherstellung |
| `server/DataService` | Profile, UpdateAsync-Sperren, Retry, Save, Shutdown |
| `server/Items` | Kostenlose Lobby-Items mit serverseitigen Reichweiten/Cooldowns |
| `server/Cosmetics` | Ausrüstung, verschweißte Modelle, Trails und Aura |
| `server/Party` | Serverinterne Einladungen und Gruppen |
| `client/Main` | Responsive Menüs, Touch-/Gamepad-Aktionen, Vorschauen, HUD |
| `client/InterfaceRoot` | Oberfläche früh starten, alte Ladebildschirme auch bei später Replikation/Respawn entfernen |
| `client/Effects` | Lokale Partikel, Sounds, Pet-Folgen, Posen und Kameraeffekte |

Ein Spieler ist erst nach erfolgreichem Profil-Load für Runden zugelassen. Späte Beitritte warten bis zur nächsten Runde; Disconnects entfernen Teilnehmer. Die Runde besitzt alle temporären Maps und Verbindungen über einen Scope. Cleanup läuft in umgekehrter Reihenfolge, sodass Event-Modifikationen vor den ursprünglichen Charakterwerten zurückgesetzt werden. Abgebrochene oder fehlgeschlagene Runden vergeben keine Siegbelohnungen.

## Vertrauensgrenzen

Clients senden ausschließlich Absichten an ein einziges, begrenztes Request-Remote. Preise, Inventar, tägliche Claims, Stimmoptionen, Nähe, Item-/Schubs-Cooldowns und Owner-Rechte prüft der Server. Es gibt keine Remote-Aktion zum direkten Setzen eines Spielerprofils. Test-Coins/Wins erfordern einen serverseitig geprüften Owner und begrenzte ganze Beträge. Normale Spieler dürfen keine Admin-Aktion ausführen.

Roblox-Charaktere verwenden die übliche replizierte Bewegung mit Client-Netzwerkbesitz. Das ist keine vollständige Anti-Cheat-Lösung. Das Spiel begrenzt Arenen serverseitig und prüft Türen-Checkpoints; umfassende Bewegungserkennung ist nicht Bestandteil dieser Version.

Rundenbelohnungen verwenden zufällige serverseitige Beleg-IDs, die letzten 64 bleiben im Profil. Tagesclaims verwenden UTC-Kalendertage. Profile mit unbekanntem Schema oder nicht erreichbarem Store werden nicht durch Ersatzdaten gespeichert. Globalboards werden aus erfolgreich gespeicherten Profilständen abgeleitet.

## Erweitern

Ein neues Spiel braucht einen Katalogeintrag, eine gebaute Map mit `Spawns`, einen Handler in `Minigames` und passende Siegerregeln. Ein Event braucht einen Katalogeintrag und einen Handler in `ChaosEvents`. Temporäre Ressourcen über den Scope registrieren; verzögerte Aufgaben mit `Scope:Delay` an die Rundenlebenszeit binden. Effekte auf schmalen Rennstrecken gegebenenfalls aus der Zufallsauswahl ausschließen.

Neue Produkte erhalten einen stabilen Identifier. Vorhandene DataStore-Schlüssel oder IDs nicht unbedacht umbenennen: sie gehören zu gespeicherten Inventaren. Der Shop ist Coin-basiert; keine Developer Products, Echtgeld-Wetten oder Robux-Käufe sind eingebaut.
