# Spiele und Systeme

## 15 Minispiele

Alle Karten sind als Modelle enthalten, mit 16 Spawnpunkten. Die folgenden Regeln sind implementiert; ihre echte Physik-/Multiplayer-Abnahme in Studio ist noch offen.

| Spiel | Mechanik | Ergebnis |
|---|---|---|
| The Floor Is Lava | Steigende Lava, versetzte Kletterplattformen, angekündigtes Verschwinden | Letzter Überlebender bzw. Überlebende am Zeitende |
| Giant Banana Attack | Warnflächen, fallende Bananen, Rückstoß und Ragdoll | Überleben |
| Don't Press the Button | Gemeinsamer Proximity-Knopf mit Entfernung/Cooldown, Zufallsevents | Überleben |
| Escape the Giant Duck | Riesenente verfolgt Spieler mittels Wegsuche durch Mauern | Schnellster Ausgang |
| Slippery Floor | Reibungsarme Fläche, Bewegungsimpulse, Böen und Schneebälle | Überleben |
| Random Disasters | Tornado, Meteorregen und steigende Flut; erhöhte Schutztürme | Überleben |
| Musical Platforms | Musik-/Taktphase, grüne sichere Felder, andere Felder verschwinden | Überleben |
| Crazy Race | Drehbalken, bewegte Plattformen, Sprungfelder, Bananenhindernisse | Schnellstes Ziel |
| Hot Potato | Nähe übergibt Kartoffel; Übergabesperre und 12-Sekunden-Zünder | Überleben; solo Kühlpunkt erreichen |
| Giant Head Mode | Vergrößerter Kopf, schmaler Parcours, reduzierte Laufgeschwindigkeit | Schnellstes Ziel |
| Color Panic | Farbnamen + Farbanzeige, 5 Sekunden zum sicheren Feld | Überleben |
| TNT Run | Boden-Raycasts lösen Felder nach 0,65 Sekunden auf | Überleben |
| Flying Chaos | Niedrige Gravitation, gerichteter Ringmarker, Windimpulse | Höchste Ringpunktzahl, Ziel bei 10 Ringen |
| Sumo Push | Gerichteter Nahbereichsschubs mit 1,5 Sekunden Pause, schrumpfende Scheibe | Überleben |
| The Wrong Door | Vier Türreihen, sichere Route, Ragdoll-/Rückwurf-/Teleportfallen, Checkpoints | Schnellstes korrektes Ziel |

Runden dauern planmäßig 75–120 Sekunden. Letzter Überlebender oder abgeschlossene Rennen können früher enden. Gleichstand bei Punkten oder gleichzeitig erfasster Zielzeit ist möglich. Ohne Ziel-/Ringfortschritt gibt es keinen erfundenen Sieger. Teilnahme gibt 5 Coins, Überleben zusätzlich 15, Sieg zusätzlich 30; XP werden ebenfalls vergeben. Ein abgebrochener Owner-Test wird nicht gewertet.

## 25 Chaos-Events

| Event | Umsetzung |
|---|---|
| Giant Head | Temporärer HeadScale bzw. R6-Kopfgröße |
| Tiny Players | Temporäre Charakterskalierung |
| Low Gravity | Wiederhergestellte Workspace-Schwerkraft |
| Super Speed | Temporäre Laufgeschwindigkeit |
| Banana Rain | Zielwarnungen und fallende Bananen |
| Falling Ducks | Fallende Entenmodelle mit Rückstoß |
| Tornado | Bewegter Wirbel mit Sog, seitlichem und vertikalem Impuls |
| Random Ragdoll | Kurze BallSocket-Ragdolls |
| Slippery Floor | Geringe Reibung und Gleitimpulse |
| Giant Beach Ball | Bewegter Riesenball und Kollisionsradius |
| Reverse Controls | Umgedrehter Bewegungsvektor, auch über PlayerModule-Touch-/Controllersteuerung |
| Bouncing Players | Wiederholte vertikale Impulse |
| Random Teleport | Teilnehmer tauschen Positionen; im Zufalls-Rennen ausgeschlossen |
| Invisible Platforms | Transparente, weiter begehbare Plattformen |
| Rainbow Fog | Animierte Atmosphärenfarbe mit Rücksetzen |
| Giant NPC Attack | Verfolgender Riesenroboter |
| Meteor Shower | Zielwarnungen und Meteorkugeln |
| Everyone Jumps | Synchron angestoßene Sprünge |
| Crazy Camera | Kleine Kamerarollbewegung; mit „Weniger Bewegung“ abschaltbar |
| Flying Furniture | Bewegte Sofas mit Ragdoll-Rückstoß |
| Giant Chicken Invasion | Zwei verfolgende Riesenhühner |
| Color Explosion | Begrenzte bunte Partikel-Bursts |
| Moving Walls | Seitlich bewegte Wand; im Zufalls-Rennen ausgeschlossen |
| Rocket Launch | Einmaliger Aufwärtsimpuls + Effekte |
| Double Jump Madness | Serverseitig begrenzter zusätzlicher Sprung in der Luft |

Ragdolls stehen automatisch wieder auf. Runde und Events besitzen Cleanup-Scopes; Modifikationen, Objekte und Verbindungen werden beim Ende zurückgesetzt. Wasser-/Bananen-/Kartoffel-Effekte sind keine Schadenstransaktionen: Spieler scheiden durch die jeweiligen Spielregeln aus.

## Sammlung und Party

9 Pets folgen kosmetisch; Ausrüstung und Favoriten werden gespeichert. 10 Lobby-Items besitzen Modelle, Vorschau, Cooldown und tatsächliche Effekte. Cosmetics enthalten Trails, Banane/Krone, Flügel, Hühnerkostüm, Aura, Ragdoll-Sterne und Konfetti-Sieg. 10 Emotes werden ohne externe Animation-IDs prozedural abgespielt und stoppen bei Bewegung.

Daily Rewards: 25 / 50 / 75 / 100 / 150 / 200 Coins, dann Krone; bei doppelter Krone 150 Coins. Nach einem ausgelassenen Tag startet die Serie neu. Das kostenlose Glücksrad vergibt 25 Coins (45%), 50 Coins (30%), Rainbow Trail (10%), Spin (8%) oder Duck Pet (7%); doppelte Cosmetics werden durch 75 Coins ersetzt. Quests und Achievements sind einmalige Account-Ziele, keine täglich erneuerten Quests.

Partys organisieren Spieler auf dem laufenden Server. Einladungen laufen nach 30 Sekunden ab. Alle aktiven Spieler desselben Servers spielen gemeinsam; es gibt keine serverübergreifende Party-Teleportwarteschlange. Roblox-Freundeseinladungen und private Server dienen dem gemeinsamen Beitritt.
