# Teststatus und Testwelt

## Bereits ausgeführt

In der Linux-Cloud: GLSL-Kompilierung und Programmlinking in einem echten Mesa
OpenGL-4.5-Compatibility-Kontext (llvmpipe). Fünf Qualitätsprofile in drei Dimensionen
und zusätzliche Schaltervarianten werden geprüft. `tools/validate.py` prüft
außerdem gerenderte Pixel für Tag/Nacht, Wetter, Dimensionen, Wasseranimation,
Schatten einschließlich Farbe, Wolken, SSR-Treffer/Ausfall, GBuffer-Beleuchtung,
PBR, Unterwasserabsorption, TAA-Initialisierung/Reset, Bloom, Belichtung und Ausgabe.
Seit 0.2.1 werden außerdem der sichtbare Diagnoserahmen und das direkte Auslesen
der Oberflächennormalen in allen drei Dimensionen gerendert und geprüft.

Der aktuelle maschinenlesbare Bericht entsteht in `build/validation/validation.json`.
`synthetic-pipeline.png` dort ist ein kleiner technischer Test mit künstlichen
Tiefen-/Farbtexturen, **kein Minecraft-Screenshot** und kein Qualitätsvergleich.
Die Pakettests prüfen ZIP-Struktur, Quellgleichheit, Prüfsummen, Profile, Referenzen,
Reproduzierbarkeit und das gespeicherte Testweltformat.

Zusätzlicher einmaliger Cloud-Check für 0.2.1: Die originale JCPP-Vorverarbeitung
und GLSL-Transformation aus Iris-Commit
`671a5c87747d33983d7ed659461a64f46dfcb1f0` (26.3) wurden in einem separaten
Java-Testtreiber ausgeführt. Die Includes wurden zuvor mit `tools/validate.py`
aufgelöst. Minecraft-Geräte-/Konfigurationszugriffe und Vertexformat-Metadaten
wurden durch kontrollierte Testwerte ersetzt; die Transformationsmethoden selbst
blieben unverändert. Verwendet wurden JCPP 1.4.14 und glsl-transformer 3.0.0-pre3.

Geprüft wurden das Standardprofil in allen drei Dimensionen, Geometrie über den
Vanilla-Transformationspfad, Terrain/Wasser/Schatten zusätzlich über den Sodium-Pfad,
alle Nachbearbeitungspässe sowie beide Diagnosemodi. Für beide Clip-Tiefenbereiche
wurden die erzeugten Programme anschließend mit Mesa kompiliert und verknüpft.
Dieser Check prüft **weder den vollständigen Iris-Paketlader noch eine laufende
Minecraft-Renderpipeline** und ist nicht Teil des Python-CI-Workflows.

Für 0.2.2 wurde zusätzlich der separate Direktivenpfad geprüft: Die unveränderten
Iris-Klassen `ConstDirectiveParser` und `DispatchingDirectiveHolder` desselben
Quellstands reproduzieren mit der alten `colortex2ClearColor=vec4(0.0)`-Direktive
exakt den gemeldeten `ArrayIndexOutOfBoundsException` an Zeile 232. Mit vier
expliziten Nullwerten werden die ClearColor-Direktiven erfolgreich eingelesen;
der resultierende RGBA-Wert bleibt `(0, 0, 0, 0)`. Der neue Python-Pakettest schlägt
ebenfalls mit der alten Fassung fehl und schützt diesen Vertrag im CI-Workflow.
Dieser Ladefehler lag außerhalb der früheren GLSL-/Transformationsprüfungen.
Nach der Korrektur wurden 420 Fragmentquellen (alle Profile, Dimensionen und
Wurzel-Einstiegspunkte) mit insgesamt 560 ClearColor-Direktiven erfolgreich
vorverarbeitet und durch den originalen Iris-Direktivenparser verarbeitet.

## Noch nicht ausgeführt

Minecraft Java 26.3 mit Iris/Sodium wurde hier nicht gestartet. Es gibt keine
fertige Spielinstallation in dieser Umgebung; Mojang-/Modrinth-Downloadversuche
lieferten HTTP 403. Ein Nutzerlog bestätigt den oben beschriebenen Ladeabbruch
und Iris' Rückfall auf normales Rendering. Ein erfolgreicher Spielstart mit der
korrigierten Fassung, ein Bildvergleich mit Vanilla, eine echte GPU-FPS-Messung
und ein Test der erzeugten Welt im Spiel sind noch nicht bestätigt.
Erfolgreiche technische Tests ersetzen diese Abnahme nicht.

## Neue Testwelt

1. `Nero-Test-World-26.3.zip` entpacken, sodass der Ordner `Nero-Test-World` direkt
   unter `saves/` der Minecraft-26.3-Instanz liegt.
2. Diese **neue** kreative Testwelt öffnen. Sie enthält `level.dat` und ein Datapack;
   Minecraft erzeugt die Landschaft beim ersten Öffnen. Der Seed ist `2026012111`.
3. Das Datapack lädt die benötigten Chunks und baut nach zwei Sekunden ein Becken
   mit verschiedenen Wassertiefen, Bäume, Gras, einen Steinberg mit Schnee,
   Fackeln/Laternen, farbiges Glas sowie Metallproben. Es versetzt Spieler an den
   ersten Kamerapunkt. Der Bereich um X/Z 0 wird dabei absichtlich neu gebaut.
4. Falls die Szene noch nicht aufgebaut ist, `/reload` und danach bei geladenen
   Chunks `/function nero_test:build` verwenden. Fehlermeldungen protokollieren.

Das separat beigelegte Datapack `Nero-Test-Scene-26.3.zip` ist eine Alternative
für eine **frisch erstellte Testwelt**. Es darf nicht ungeprüft in eine bestehende
Spielwelt eingesetzt werden: Es ersetzt Blöcke von X/Z −40 bis 40, ungefähr Y 61–104.
Die Testwelt wurde strukturell geprüft, aber noch nicht mit Minecraft geöffnet.

## Vergleich mit identischer Kamera

Für beide Aufnahmen dieselbe Auflösung, FOV (z. B. 70), Sichtweite, Ressourcenpakete
und Kamera verwenden. Kamera nicht bewegen; erst ohne Shader, dann mit NERO HIGH
aufnehmen. Nach Umschalten etwa fünf Sekunden für die Belichtungs-/TAA-History warten.
Die Tageszeit vor beiden Bildern mit derselben Funktion setzen.

| Prüfung | Befehl / Vorgehen | Erwartete sichtbare Änderung |
|---|---|---|
| Wasser | `/function nero_test:camera_water`, `nero_test:noon` | Wellen, Fresnel, Spiegelung, tiefenabhängige Absorption |
| Wald | `/function nero_test:camera_forest`, `nero_test:sunset` | bewegte Blätter und Schatten, warmer Himmel, Lichtstrahlen |
| Materialien | `/function nero_test:camera_materials` | verschieden raue/metallische Oberflächen, Glastransmission |
| Nacht | `/function nero_test:night` | dunklerer Himmel, Sterne, Mondlicht und warmes Blocklicht |
| Regen/Gewitter | `/function nero_test:rain` / `nero_test:storm` | dichtere Wolken, nasse Flächen, Regennebel |
| Unterwasser | ins Becken fliegen | Wasserabsorption, Caustics-Näherung, leichte Verzerrung |
| Nether | `/function nero_test:nether` | rote Atmosphäre, Lava/Emission; sicher im Kreativmodus fliegen |
| End | `/function nero_test:end` | eigener kosmischer Himmel und violette Atmosphäre |
| Rückkehr | `/function nero_test:overworld` | Ausgangsszene wieder sichtbar |

Jeder Kurzname in der Tabelle ist eine Funktion und wird mit `/function` aufgerufen.
Zusätzlich alle fünf Profile laden, TAA bei Bewegung prüfen, DOF/Motion Blur
einschalten, Menütexte kontrollieren und bei Wasser sowie farbigem Glas auf
Sortierfehler achten. Helle/schwarze Flächen, Ghosting, verschwindendes Wasser und
Shaderfehler gelten als Fehler, nicht als bestandene Tests.

`logs/latest.log`, GPU/Treiber, Iris-/Sodium-Version, Profil und Screenshotpaare
aufbewahren. Die Version erst nach dieser Abnahme als ingame getestet bezeichnen.
