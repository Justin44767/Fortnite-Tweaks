# Changelog

## 0.2.3 — 2026-10-26

- Szenenschnappschuss von `colortex3` nach `colortex7` verschoben. Iris bindet
  `colortex0` bis `colortex3` nur in Vollbildpässen; der Wasserpass las deshalb
  über den ungebundenen Sampler die Blocktextur statt des Hintergrundbildes.
- Deferred-Ausgabe, Wasserbrechung und Screen-Space-Spiegelungen gemeinsam auf
  den neuen HDR-Puffer umgestellt. Er bleibt getrennt von den Schreibzielen des
  Wasserpasses; die Qualitätsprofile und Effekte bleiben erhalten.
- GPU-Regression reproduziert die falsche Pink-/Grünfärbung vor der Änderung und
  bestätigt danach die Unabhängigkeit der Wasserfarbe von der Blocktextur sowie
  ihre Abhängigkeit vom Szenenhintergrund.
- Validierung prüft aktive Sampler gegen die Iris-Geometrieeinschränkung, verlangt
  explizite Texturbindungen und verbindet Deferred-Ausgaben anhand von DRAWBUFFERS.
- ZIP neu gebaut. Ob sämtliche gemeldeten Grafikfehler damit verschwinden, bleibt
  durch einen Spieltest zu bestätigen; Voxy wurde nicht als Ursache nachgewiesen.

## 0.2.2 — 2026-10-25

- Reproduzierten Ladeabsturz in Iris `DispatchingDirectiveHolder` behoben:
  `colortex2ClearColor=vec4(0.0)` verwendet jetzt vier explizite Nullwerte.
  Der Iris-Direktivenparser unterstützt die gültige GLSL-Kurzform an dieser Stelle
  nicht und brach das Laden mit `ArrayIndexOutOfBoundsException` ab; danach lief
  Minecraft laut Nutzerlog ohne Shader weiter.
- Regressionstest für explizite numerische ClearColor-Komponenten ergänzt. Der
  originale Iris-Parser reproduziert den Fehler vor der Änderung und verarbeitet
  die korrigierte Direktive mit unverändertem Farbwert erfolgreich.
- Shader-ZIP neu gebaut. Der vollständige Lauf im Minecraft-Client bleibt offen.

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
