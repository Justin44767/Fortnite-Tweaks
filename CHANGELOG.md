# Changelog

## 0.2.1 — 2026-10-25

- Sichtbaren, abschaltbaren NERO-Funktionstest ergänzt: türkis-pinker Rahmen für
  den finalen Pass und ungefilterte Oberflächennormalen zur Prüfung der Geometriedaten.
- Deutsche und englische Menütexte sowie Anleitung zur Diagnose eines unveränderten
  Vanilla-Bildes ergänzt. Normale Darstellung und Qualitätsprofile bleiben erhalten.
- Zusätzliche Pixelprüfungen für beide Diagnosemodi in allen drei Dimensionen.
- Iris-Vorverarbeitung/Transformation des 26.3-Quellstands separat geprüft;
  Minecraft-Laufzeit bleibt ungetestet. Die gemeldete Vanilla-Darstellung ist ohne
  Ingame-Diagnose oder Iris-Log noch nicht als behoben bestätigt.

## 0.2.0 — 2026-10-25

- Zielversion von Minecraft Java 1.21.11 auf 26.3 umgestellt.
- Iris-Vertrag gegen den offiziellen 26.3-Zweig geprüft (Iris 1.11.6 / Sodium 0.9.2).
- Testwelt auf DataVersion 5023 und Datapack-Format 121.0 aktualisiert.
- Shader, Testszene und Testwelt als `*-26.3.zip` neu gebaut; frühere Artefakte
  bleiben über den Git-Verlauf erreichbar.
- GLSL-Effekte unverändert; Minecraft-/Iris-Laufzeittest für 26.3 bleibt ausstehend.

## 0.1.0 — 2026-10-25

- Fortnite-Tweaks durch das eigenständige Shaderprojekt NERO REALISM ULTRA ersetzt.
- Gemeinsame GLSL-Bibliotheken und Iris-Einstiegspunkte für Hauptwelt, Nether, End.
- Gefilterte farbige Schatten, Pflanzenbewegung und animierte Wassernormalen.
- Wasserabsorption, Brechung, Fresnel und Screen-Space-Spiegelungen mit Himmel-Fallback.
- Prozeduraler Himmel, Tag/Nacht-Wechsel und raymarchende volumetrische Wolken.
- Räumlich abgetasteter, durch Schatten beeinflusster Nebel und Unterwasserabsorption.
- PBR-Normalen/Glanz, GGX-Materialbeleuchtung, SSAO und diffuse Screen-Space-Näherung.
- TAA mit Reprojektion/History-Clipping, Bloom, adaptive Belichtung und Farbprofile.
- Optionale Tiefenunschärfe und Kamerabewegungsunschärfe, fünf Qualitätsprofile.
- Reproduzierbare Shader-ZIP, neue Testwelt und Testszene-Datapack.
- Technische GLSL-/Renderprüfungen und Paketprüfungen. Minecraft-Abnahme ausstehend.
