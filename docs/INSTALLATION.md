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

Bei zu geringer Leistung zuerst HIGH/MEDIUM, kürzere Schattendistanz, weniger
Wolken-/Nebel-/Reflexionsschritte und deaktivierte Tiefenunschärfe wählen.
Nach Auflösungswechseln oder Shader-Neuladen kann die zeitliche Historie kurz neu
aufgebaut werden. Die visuelle Ingame-Abnahme dieser ersten Version steht noch aus.
