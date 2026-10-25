# NERO REALISM ULTRA – ULTIMATE PHOTOREALISTIC MINECRAFT SHADER
## Minecraft 1.21.11 • Iris Shaders • Ultra Realistic Graphics • Cinematic Lighting

# HAUPTAUFGABE

Entwickle einen vollständig funktionsfähigen, extrem realistischen Minecraft-Shader namens:

**NERO REALISM ULTRA**

Der Shader soll Minecraft optisch in eine beeindruckende, nahezu fotorealistische Welt verwandeln.

Orientiere dich an der visuellen Qualität von:

- Complementary Unbound
- Bliss Shaders
- Photon Shaders
- BSL Shaders
- SEUS PTGI

Entwickle dabei einen eigenständigen Shader mit eigenem GLSL-Code.

Das Ergebnis soll deutlich realistischer als Vanilla Minecraft aussehen.

## WICHTIGSTE ANFORDERUNGEN

- Minecraft Java 1.21.11
- Iris Shaders
- Sodium-kompatibel
- Extrem realistische Beleuchtung
- Dynamische Schatten
- Realistisches Wasser
- Spiegelungen
- Volumetrische Wolken
- Volumetrischer Nebel
- Realistische Sonnenstrahlen
- Globale Beleuchtung, soweit technisch umsetzbar
- Realistische Tag-Nacht-Beleuchtung
- PBR-Materialien
- Ambient Occlusion
- Realistische Himmel
- Cinematic Color Grading
- Depth of Field
- Motion Blur optional
- Bloom
- TAA Anti-Aliasing
- Unterschiedliche Grafikprofile
- Fertige Shader-ZIP-Datei

**WICHTIG: Der Shader muss sichtbare grafische Veränderungen bewirken. Keine Vanilla-Grafik mit lediglich veränderten Farben!**

---

# 1. SHADER ENGINE

Entwickle einen echten GLSL-Shaderpack für die Iris-kompatible Minecraft-Shaderpipeline.

Verwende die passenden Shaderpasses, darunter je nach unterstützter Pipeline:

- Shadow Pass
- GBuffer Passes
- Composite Passes
- Deferred Lighting
- Final Pass
- Temporal Processing
- Depth Buffer Processing

Implementiere eine echte Shaderpipeline und nicht nur eine Konfigurationsdatei.

Prüfe die technischen Anforderungen der verwendeten Iris-Version.

Keine leeren Shaderdateien.

Keine reinen Platzhaltereffekte.

---

# 2. ULTRA REALISTIC LIGHTING

Implementiere ein hochwertiges Beleuchtungssystem.

## SUNLIGHT

- Physikalisch inspirierte Sonnenbeleuchtung
- Dynamische Sonnenrichtung
- Realistische Tagesfarben
- Weiche Sonnenschatten
- Sonnenlicht durch Blätter
- Natürlich beleuchtete Landschaften
- Warme Sonnenuntergänge
- Kühle Morgenbeleuchtung

## GLOBAL ILLUMINATION

Implementiere die bestmögliche technisch umsetzbare indirekte Beleuchtung.

Nutze geeignete Verfahren wie:

- Screen Space Global Illumination
- Screen Space Ambient Lighting
- Indirect Diffuse Approximation
- Temporale Lichtakkumulation

Eine echte Path-Tracing-Implementierung nur dann angeben, wenn entsprechende Ray- beziehungsweise Path-Tracing-Verfahren tatsächlich implementiert wurden.

## LIGHT SOURCES

Fackeln, Laternen und andere Lichtquellen sollen eine glaubwürdige Beleuchtung erzeugen.

- Warmes Fackellicht
- Weiche Lichtübergänge
- Lichtreflexionen
- Nachtbeleuchtung
- Individuelle Lichtfarben, soweit technisch unterstützt

---

# 3. REALISTIC SHADOW SYSTEM

Implementiere hochwertige dynamische Schatten.

## FUNKTIONEN

- High Resolution Shadow Maps
- Soft Shadows
- Contact Shadows
- Variable Shadow Softness
- Shadow Filtering
- Shadow Bias Correction
- Sun Shadows
- Moon Shadows, soweit unterstützt
- Transparent Shadow Effects
- Vegetation Shadows

## SHADOW QUALITY

LOW

MEDIUM

HIGH

ULTRA

EXTREME

Unterstütze einstellbare Schattenauflösungen und Schattendistanzen.

Die Schatten sollen sich mit der Tageszeit verändern.

---

# 4. ULTRA REALISTIC WATER

**DAS IST EINE DER WICHTIGSTEN FUNKTIONEN!**

Das Wasser soll optisch stark von Vanilla abweichen.

## WATER FEATURES

- Realistische Wasseroberfläche
- Animierte Wellen
- Sonnenreflexionen
- Spiegelung von Himmel und Landschaft
- Screen Space Reflections
- Fresnel Reflections
- Realistische Lichtbrechung
- Unterwasserverzerrung
- Wassertransparenz
- Wasserfarbe abhängig von Tiefe
- Wasserbewegungen
- Sanfte Wellenanimation
- Reflektierende Wasseroberfläche

## UNDERWATER

- Unterwassernebel
- Lichtstrahlen unter Wasser
- Realistische Lichtabsorption
- Farbveränderung mit Tiefe
- Verbesserte Sicht unter Wasser
- Unterwasser-Caustics

Das Wasser soll beim ersten Aktivieren des Shaderpacks sofort sichtbar anders aussehen.

---

# 5. VOLUMETRIC CLOUDS

Erstelle beeindruckende 3D-Wolken.

## FUNKTIONEN

- Volumetric Clouds
- Raymarched Cloud Rendering
- Realistische Wolkenformen
- Unterschiedliche Wolkenhöhen
- Dynamische Wolkenbewegung
- Sonnenbeleuchtete Wolken
- Wolkenschatten
- Sonnenuntergang in Wolken
- Dunkle Gewitterwolken
- Lichtstreuung in Wolken

## CLOUD SETTINGS

- Cloud Quality
- Cloud Density
- Cloud Height
- Cloud Speed
- Cloud Lighting
- Cloud Shadows

Erstelle unterschiedliche Wetterstimmungen.

Die Wolken sollen nicht einfach wie normale Minecraft-Blockwolken aussehen.

---

# 6. REALISTIC SKY & ATMOSPHERE

Implementiere einen realistischen Himmel.

## DAY SKY

- Atmosphärische Lichtstreuung
- Blauer Himmel
- Natürliches Sonnenlicht
- Horizontdunst
- Realistische Wolken
- Sichtbare Sonnenstreuung

## SUNSET

- Orange-roter Himmel
- Goldene Sonnenstrahlen
- Violette Wolken
- Warme Landschaftsbeleuchtung
- Atmosphärischer Horizont

## NIGHT SKY

- Realistische Sterne
- Milchstraßen-Effekt optional
- Mondbeleuchtung
- Leichte atmosphärische Streuung
- Dunkle Landschaft
- Realistische Nachtfarben

Der Himmel soll sich flüssig mit der Minecraft-Tageszeit verändern.

---

# 7. VOLUMETRIC FOG & GOD RAYS

Erstelle volumetrische Lichteffekte.

## FUNKTIONEN

- Volumetric Fog
- Atmospheric Fog
- Distance Fog
- Morning Mist
- Forest Fog
- Light Shafts
- God Rays
- Sunlight Through Trees
- Fog Density Settings

Besonders in Wäldern sollen Sonnenstrahlen zwischen Bäumen sichtbar sein.

---

# 8. PBR MATERIALS

Unterstütze hochwertige Materialdarstellung.

## MATERIAL FEATURES

- Normal Mapping
- Specular Mapping
- Roughness
- Metallic Reflections
- Material Response
- Parallax Occlusion Mapping, soweit unterstützt
- PBR Resource Pack Compatibility

## MATERIALIEN

- Stein
- Holz
- Glas
- Metall
- Erde
- Sand
- Schnee
- Wasser
- Blätter

Ohne passende PBR-Texturen soll der Shader sinnvolle Fallback-Materialeigenschaften verwenden.

Er darf keine zusätzlichen Texturen voraussetzen, die nicht im Paket enthalten sind.

---

# 9. SCREEN SPACE REFLECTIONS

Implementiere Spiegelungseffekte.

## FUNKTIONEN

- Water Reflections
- Wet Surface Reflections
- Metallic Reflections
- Reflection Quality Settings
- Reflection Distance
- Reflection Roughness

Verwende technisch geeignete Screen-Space-Verfahren und sinnvolle Fallbacks für nicht sichtbare Bildbereiche.

Keine vollständigen Ray-Tracing-Reflexionen behaupten, wenn sie nicht implementiert wurden.

---

# 10. REALISTIC WEATHER

Erstelle dynamische Wettereinflüsse.

## RAIN

- Dunklere Umgebung
- Nasse Oberflächen
- Reflektierender Boden
- Regeneffekte
- Gewitterstimmung
- Niedrigere Wolkendecke
- Regennebel

## SNOW

- Kalte Beleuchtung
- Natürliches Schneelicht
- Leichte Schneereflexionen
- Winterliche Atmosphäre

## THUNDERSTORM

- Blitzbeleuchtung
- Dunkle Wolken
- Volumetrischer Nebel
- Dramatisches Licht

---

# 11. REALISTIC VEGETATION

Bäume und Pflanzen sollen lebendiger aussehen.

## FUNKTIONEN

- Waving Leaves
- Waving Grass
- Waving Flowers
- Wind Animation
- Soft Vegetation Shadows
- Realistic Leaf Lighting

Die Bewegung soll dezent und natürlich sein.

Keine übertriebene Animation.

---

# 12. CINEMATIC POST PROCESSING

Erstelle professionelle Post-Processing-Effekte.

## FUNKTIONEN

- Cinematic Bloom
- Tonemapping
- Color Grading
- Auto Exposure
- Contrast Control
- Saturation Control
- Depth of Field
- Motion Blur optional
- Filmic Highlights
- Temporal Anti-Aliasing
- Sharpening

## COLOR PROFILES

REALISTIC

CINEMATIC

VIBRANT

NATURAL

DARK FANTASY

CUSTOM

Alle Effekte müssen konfigurierbar sein.

---

# 13. NETHER & END GRAPHICS

Der Shader soll auch in anderen Dimensionen funktionieren.

## NETHER

- Atmosphärischer roter Nebel
- Glühende Lava
- Verbesserte Lava-Beleuchtung
- Vulkanische Stimmung
- Angepasste Schatten
- Dimension-spezifisches Color Grading

## END

- Kosmischer Himmel
- Mystische Beleuchtung
- Violette Atmosphäre
- Verbesserte Partikeleffekte
- Dunkle Schatten
- Eigenständige End-Farbpalette

Implementiere dimensionsabhängige Effekte, ohne die Lesbarkeit des Spiels zu zerstören.

---

# 14. GRAPHICS PRESETS

Erstelle ein Shader-Einstellungsmenü mit mindestens fünf Profilen.

## LOW

Für schwächere Hardware.

## MEDIUM

Ausgewogene Leistung.

## HIGH

Hohe Grafikqualität.

## ULTRA

Sehr realistische Beleuchtung, Wasser und Schatten.

## CINEMATIC EXTREME

Maximale visuelle Qualität.

- Hochwertige Schatten
- Volumetrische Wolken
- SSR
- SSGI, soweit implementiert
- Hochwertiger Bloom
- Realistisches Wasser
- Detaillierter Nebel
- Verbesserte Materialeffekte

Performance darf abhängig von der Grafikkarte variieren.

---

# 15. WICHTIG – NICHT WIE VANILLA

Ich möchte ausdrücklich keine Shader-Version, die fast genauso wie normales Minecraft aussieht.

Der Unterschied muss sofort sichtbar sein.

Beim Aktivieren müssen besonders folgende Effekte deutlich erkennbar sein:

1. Dynamische Sonnenschatten
2. Vollständig anderes Wasser
3. Realistische Wolken
4. Sonnenstrahlen
5. Verbesserte Beleuchtung
6. Atmosphärischer Himmel
7. Reflexionen
8. Realistische Nachtbeleuchtung
9. Volumetrischer Nebel
10. Neue Licht- und Farbwirkung

Erstelle eine Testwelt mit Wasser, Bäumen, Bergen, Fackeln und Glas.

Vergleiche Vanilla Minecraft und NERO REALISM ULTRA anhand identischer Kameraansichten.

Wenn kein deutlicher Unterschied sichtbar ist, untersuche den Shader-Ladeprozess und die Renderpasses.

Ein kompilierender Shader gilt nicht automatisch als visuell funktionierend.

---

# 16. SHADERPACK DATEISTRUKTUR

Erstelle einen vollständigen Iris-kompatiblen Shaderpack.

Dateiname:

**NeroRealismUltra-1.21.11.zip**

Beispielhafte Struktur:

NeroRealismUltra/

  shaders/

    shaders.properties

    lib/

      lighting/

      shadows/

      water/

      clouds/

      atmosphere/

      reflections/

      materials/

      postprocessing/

    world0/

    world-1/

    world1/

    gbuffers_*.vsh

    gbuffers_*.fsh

    composite*.vsh

    composite*.fsh

    final.vsh

    final.fsh

    shadow.vsh

    shadow.fsh

    weitere notwendige Shaderdateien

Verwende nur tatsächlich durch die gewählte Iris-Shaderpipeline unterstützte Shaderprogramme, Dateien und Konventionen.

Sämtliche GLSL-Dateien müssen echten Shadercode enthalten.

Die ZIP-Datei soll die erforderliche Struktur besitzen, damit Iris sie direkt als Shaderpack erkennt.

---

# 17. PERFORMANCE OPTIMIZATION

Optimiere den Shader, ohne die Grafikqualität unnötig zu verschlechtern.

## FUNKTIONEN

- Adaptive Quality Settings
- Temporal Reprojection
- Reduced Raymarch Steps
- Shadow Distance Settings
- Reflection Quality Settings
- Cloud Quality Settings
- Optimized GLSL
- Performance Presets

Erstelle keine unnötigen Renderpasses.

Vermeide:

- Shader Compilation Errors
- Schwarze Bildschirme
- Unsichtbares Wasser
- Kaputte Schatten
- Extreme Bildfehler
- Flackernde Beleuchtung
- Ghosting durch temporale Effekte

---

# 18. TESTING & DEBUGGING

Teste den Shader mit Minecraft Java 1.21.11 und einer dazu kompatiblen Iris-Version.

## TESTS

- Shader wird von Iris erkannt
- Shader lässt sich auswählen
- Shader wird erfolgreich geladen
- Hauptwelt wird korrekt dargestellt
- Wasser ist sichtbar verändert
- Schatten funktionieren
- Wolken funktionieren
- Sonnenstrahlen funktionieren
- Nether funktioniert
- End funktioniert
- Nachtbeleuchtung funktioniert
- Regen funktioniert
- Shader-Einstellungen funktionieren
- Keine kritischen GLSL-Fehler
- Kein unbeabsichtigter Vanilla-Fallback

Prüfe die Shader-Logs.

Wenn ein Effekt nicht funktioniert, behebe die Ursache im Shadercode.

Keine Shaderfunktionen als getestet bezeichnen, wenn kein echter Minecraft-Test durchgeführt wurde.

---

# 19. BUILD & RELEASE

**ICH MÖCHTE EIN FERTIGES SHADERPACK ALS ZIP-DATEI.**

Liefere:

1. NeroRealismUltra-1.21.11.zip
2. Vollständige GLSL-Shaderdateien
3. Shader-Konfiguration
4. Qualitätsprofile
5. Installationsanleitung
6. README
7. Changelog
8. Dokumentation aller Grafikeffekte

Der Shader soll kein Java-Mod sein und benötigt keine eigene JAR-Datei.

## INSTALLATION

1. Minecraft Java 1.21.11 installieren.
2. Iris Shaders und die benötigten kompatiblen Abhängigkeiten installieren.
3. Shader-ZIP in `.minecraft/shaderpacks` kopieren.
4. Minecraft starten.
5. Video Settings öffnen.
6. Shader Packs öffnen.
7. NERO REALISM ULTRA auswählen.
8. Shader aktivieren.
9. Grafikeinstellungen anpassen.

---

# 20. ABSCHLIESSENDER ENTWICKLUNGSAUFTRAG

Entwickle jetzt:

**NERO REALISM ULTRA – ULTIMATE PHOTOREALISTIC MINECRAFT SHADER**

Priorisiere:

1. Funktionierendes Iris-Shaderpack
2. Deutlich veränderte Beleuchtung
3. Dynamische Schatten
4. Realistisches Wasser
5. Atmosphärischer Himmel
6. Volumetrische Wolken
7. Sonnenstrahlen
8. Volumetrischer Nebel
9. Reflexionen
10. Indirekte Beleuchtung
11. PBR-Unterstützung
12. Wettereffekte
13. Nether und End
14. Cinematic Color Grading
15. Shader-Menü
16. Performance-Profile
17. Fehlerbehebung
18. Fertige ZIP-Datei

## ENTWICKLUNGSREGELN

- Keine Fake-Effekte
- Keine leeren Shaderdateien
- Keine bloß umbenannten Vanilla-Shader
- Keine kopierten Complementary-Unbound-Dateien
- Keine erfundenen Ray-Tracing-Funktionen
- Keine kaputten Renderpasses
- Keine ungetesteten Funktionen als fertig ausgeben
- Kein bloßer Farbfilter als Ersatz für echte Beleuchtung
- Keine Kompilierungsfehler ignorieren

Erstelle die echte Shaderpipeline mit vollständigem GLSL-Code.

Teste besonders, dass Wasser, Schatten, Wolken und Licht sichtbar funktionieren.

Wenn einzelne fortgeschrittene Verfahren nicht verfügbar sind, verwende hochwertige kompatible Alternativen und dokumentiere die Unterschiede.

## ENDZIEL

Ein Minecraft Shader, der sich visuell an hochwertigen Shaderpacks wie Complementary Unbound orientiert und Minecraft eine beeindruckende, realistische Atmosphäre verleiht.

Die Landschaft soll mit realistischen Sonnenstrahlen, Schatten, weichem Licht, reflektierendem Wasser, volumetrischen Wolken und einer cineastischen Farbgebung dargestellt werden.

Der Shader soll beim Aktivieren sofort erkennbar sein und Minecraft optisch deutlich verändern.

Erstelle eine vollständig installierbare ZIP-Datei:

**NeroRealismUltra-1.21.11.zip**

**NERO REALISM ULTRA**

**BEYOND VANILLA. BEYOND REALISM.**