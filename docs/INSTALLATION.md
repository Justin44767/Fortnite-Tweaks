# Installation

1. Minecraft **Java Edition 26.3** einmal mit dem eigenen Launcher starten.
2. Eine ausdrücklich für 26.3 veröffentlichte Iris-Version und deren passende
   Sodium-/Loader-Abhängigkeiten installieren. Der offizielle Iris-Installer oder
   ein Launcher mit Abhängigkeitsauflösung hilft dabei. Nicht einfach die neueste
   Iris-Version für eine andere Minecraft-Version wählen.
3. `NeroRealismUltra-26.3.zip` in den `shaderpacks`-Ordner dieser Spielinstanz
   kopieren. Unter Windows liegt dieser bei einer Standardinstallation unter
   `%APPDATA%\.minecraft\shaderpacks`. Andere Launcher verwenden eigene Instanzordner.
4. Minecraft mit dem Iris-Profil starten. Unter Video Settings → Shader Packs
   **NERO REALISM ULTRA** auswählen und Shader aktivieren.
5. Zunächst HIGH wählen. Im Shader-Einstellungsmenü Wasser, Wolken und Schatten
   prüfen. Ein PBR-Ressourcenpaket ist optional; ohne eines gelten die eingebauten
   Standardmaterialien.

Die ZIP nicht zusätzlich in einen äußeren `NeroRealismUltra/`-Ordner verpacken.
Das Paket ist ein Shaderpack, keine Mod-JAR. Es benötigt keine herunterzuladenden
Noise-Texturen; Wolken, Wellen, Sterne und Caustics werden im GLSL erzeugt.

Bei Fehlern `logs/latest.log` derselben Spielinstanz auf Iris-, GLSL-, Shader- und
Framebuffer-Meldungen prüfen. Versionen von Spiel, Iris, Sodium und GPU-Treiber
zusammen mit dem betroffenen Programm und der vollständigen Fehlermeldung notieren.
Eine erfolgreiche Auswahl allein beweist nicht, dass alle Renderpasses laufen.

## Funktionstest bei unverändertem Bild

1. Die aktuelle `NeroRealismUltra-26.3.zip` herunterladen und die bisherige Datei
   im `shaderpacks`-Ordner der verwendeten Instanz ersetzen. Anschließend Minecraft
   neu starten und genau dieses Paket auswählen.
2. In den Shader-Einstellungen **NERO-Funktionstest → Rahmen** wählen, anwenden und
   das Menü schließen. Links muss ein türkiser, rechts ein pinker Bildrand erscheinen.
   Fehlt schon die Einstellung, ist nicht die Ausgabe 0.2.1 oder neuer geladen.
3. **NERO-Funktionstest → Oberflächen** zeigt Blockseiten je nach Ausrichtung in
   verschiedenen Farben und den Himmel dunkel. Hier werden die Geometriedaten direkt
   angezeigt; Belichtung und Farbprofil beeinflussen diese Ansicht nicht.
4. Zum Spielen den Funktionstest wieder auf **Aus** stellen und anwenden.

Ein sichtbarer Rahmen bestätigt den finalen NERO-Pass, aber noch nicht die korrekte
Beleuchtung aller Flächen. Fehlt der Rahmen nach dem Anwenden, zuerst das ausgewählte
Paket und das Iris-Protokoll prüfen. Ist der Rahmen sichtbar, aber die Oberflächenansicht
zeigt trotz sichtbarer Blöcke nur eine gleichmäßige Fläche, die Geometriepässe und
Renderziele anhand des Logs prüfen. Bei einer Meldung bitte das Ergebnis beider Modi,
die Iris-/Sodium-Versionen und die Zeilen aus `logs/latest.log` direkt nach dem Laden
mitsenden. Diese Prüfung grenzt die Ursache ein; eine automatische Reparatur ist sie nicht.

Bei zu geringer Leistung zuerst HIGH/MEDIUM, kürzere Schattendistanz, weniger
Wolken-/Nebel-/Reflexionsschritte und deaktivierte Tiefenunschärfe wählen.
Nach Auflösungswechseln oder Shader-Neuladen kann die zeitliche Historie kurz neu
aufgebaut werden. Die visuelle Ingame-Abnahme dieser ersten Version steht noch aus.
