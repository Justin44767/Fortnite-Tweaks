# NERO CHAOS PARTY

**ALLES GEHT SCHIEF! — RUN. FALL. LAUGH. REPEAT.**

Roblox-Partyspiel für 2–16 Spieler, mit Solo-Unterstützung. Dieses Repository enthält jetzt das Roblox-Projekt; es ersetzt NERO REALISM ULTRA vollständig.

**[Spiel herunterladen – ZIP mit Studio-Datei](https://github.com/Justin44767/Fortnite-Tweaks/raw/refs/heads/main/dist/NeroChaosParty-Download.zip)** · **[Quellcode + Modelle + Audio als ZIP](https://github.com/Justin44767/Fortnite-Tweaks/raw/refs/heads/main/dist/NeroChaosParty-Source.zip)**

## Starten

1. `NeroChaosParty-Download.zip` über den Link oben herunterladen und entpacken. Die enthaltene `NeroChaosParty.rbxlx` in **Roblox Studio → File → Open from File** öffnen.
2. **Play** startet die Lobby und die automatische Rundenfolge. Bei Studio-Tests sind Daten standardmäßig nur für die Sitzung gültig; das HUD zeigt `STUDIO`.
3. Für Multiplayer unter **Test → Server & Clients** mindestens **2 Clients** starten. Ein einzelner Spieler kann ebenfalls spielen.
4. Zum Veröffentlichen **File → Publish to Roblox** verwenden. In den Experience-Einstellungen 16 Spieler pro Server und vorzugsweise R15 einstellen. Die Veröffentlichung auf Roblox muss über dein Roblox-Konto erfolgen.
5. Optional Owner-UserIds, VIP-Gäste und eigene Audio-Asset-IDs in `ReplicatedStorage → Shared → Config` eintragen. Bei einer persönlich erstellten Experience wird deren Creator automatisch als Owner erkannt; bei Gruppen-Experiences die Owner-UserIds explizit eintragen.

Die Datei enthält eine gebaute Lobby, alle 15 Arena-Modelle, 18 eigene Requisiten-/Pet-Modelle und sämtliche Scripts. Maps liegen in `ServerStorage/Maps` und werden für Runden geklont. Die dynamische Oberfläche wird beim Spielen erstellt.

## Enthalten

- Automatische Runden, Abstimmung über drei Minispiele, Timer, Gewinnerauswertung und Rückkehr in die Lobby.
- **15 unterschiedliche Spiele**: Lava, Bananenregen, roter Knopf, Entenflucht, Eisfläche, Katastrophen, Musical Platforms, Hindernisrennen, Hot Potato, Riesenkopf-Parcours, Color Panic, TNT Run, Flugringe, Sumo und falsche Türen.
- **25 zeitlich begrenzte Chaos-Events**, Ragdolls mit Wiederaufstehen, serverseitig geprüfte Schubser.
- Farbige Party-Lobby mit Shops, Brunnen, Tanzfläche, Trampolinen, Rutsche, Fotowand, Glücksrad und Ranglisten.
- Chaos Coins, Wins, XP/Level, einmalige Quests, Achievements, tägliche Geschenke, kostenloses Glücksrad und Meilenstein-Belohnungen.
- 9 kosmetische Pets mit Vorschau, Favoriten und Folgen; Trails, Hüte, Flügel, Kostüm, Aura, Ragdoll-/Sieger-Effekte und 10 prozedural animierte Emotes.
- 10 kostenlose Lobby-Items mit eigenen Modellen und Cooldowns. Gewertete Minispiele verwenden ihre eigenen Regeln.
- Maus-, Touch- und Gamepad-Bedienung, Party-Gruppen auf demselben Server, Roblox-Freundeseinladungen und Unterstützung für private Server.
- Servergeprüftes Owner-Panel, DataStore-Profile mit Sitzungssperren, Wiederholversuchen, automatischem Speichern und Schutz vor doppelten Runden-/Tagesbelohnungen.

## Prüfstatus und Grenzen

Version **1.0.0**, 27. Oktober 2026. Luau-Kompilierung, isolierte Spiel-/Wirtschaftsregeln, Speicherfehler mit Test-Doubles und die XML-/Paketstruktur werden mit `tools/test.py` geprüft. Der genaue Stand steht in [docs/TESTING.md](docs/TESTING.md).

**Roblox Studio ist in der Cloud-Umgebung nicht verfügbar. Das Öffnen in Studio, echte Roblox-Physik, zwei echte Testclients, mobile Geräte und Live-DataStores wurden hier nicht getestet.** Das Projekt ist eine vollständige importierbare Implementierung, noch keine in Roblox abgenommene Veröffentlichung. Fehler aus dem Studio-Output sind für die letzte Integrationsprüfung maßgeblich.

Audio funktioniert zunächst über mit Roblox ausgelieferte kurze Effekttöne. Zehn selbst erzeugte WAV-Dateien liegen unter `assets/audio`; für eigene Duck-/Chicken-/Musikklänge müssen sie in Roblox hochgeladen und ihre Asset-IDs in `Config.Audio` eingetragen werden. Es werden keine fremden Spiele, Audio-Samples oder Animation-IDs kopiert. Emotes, Pet-Bewegungen und Requisitenanimationen entstehen im Code.

## Entwicklung

- [Installation, Veröffentlichung, Audio und Speicherung](docs/INSTALLATION.md)
- [Alle Spiele, Events und Systeme](docs/FEATURES.md)
- [Architektur und Erweiterungen](docs/ARCHITECTURE.md)
- [Testprotokoll und Studio-Abnahme](docs/TESTING.md)
- [Originalauftrag](docs/BRIEF.md)

```sh
python3 tools/build.py
python3 tools/test.py --luau /path/to/luau --compiler /path/to/luau-compile
```

Der Builder verwendet nur die Python-Standardbibliothek. Er erzeugt die `.rbxlx`, einzelne `.rbxmx`-Modelle, originale Audio-Dateien, das Quellcode-ZIP und SHA-256-Prüfsummen reproduzierbar. Alternativ unterstützt `default.project.json` einen Rojo-Workflow; die generierten Modelle müssen vorher vorhanden sein.
