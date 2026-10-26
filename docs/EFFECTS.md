# Effekte und technische Grenzen

| Bereich | Tatsächliche Implementierung | Grenzen |
|---|---|---|
| Direktlicht | Lineare Beleuchtung, Sonnen-/Mondrichtung, GGX-Spekularanteil, Schlick-Fresnel | Physikalisch inspiriert, keine vollständige atmosphärische Simulation |
| Schatten | Verzerrte Shadowmap, 4–24 PCF-Taps, Normaloffset/Bias, farbige transparente Transmission | PCF-Weichzeichnung; keine entfernungsabhängige PCSS-Penumbra |
| Kontakt/AO | Normal-/tiefenbasiertes Screen-Space-Occlusion-Sampling | Nur sichtbare Geometrie; keine separate Contact-Shadow-Raytracing-Stufe |
| Indirektes Licht | Diffuse Nachbarschaftsabtastung mit Empfänger-/Sendernormalen, Distanzgewicht und Albedo | Begrenzte Screen-Space-Näherung; kein Path Tracing, keine Voxel-GI, kein mehrfacher Lichttransport |
| Lichtquellen | Warme Beleuchtung über Minecraft-Blocklicht, Emission markierter Blöcke | Keine individuelle Farbe jeder Fackel; Vanilla-Blocklicht liefert keine separaten farbigen Lichtquellen |
| Wasser | Weltverankerte Wellen, veränderte Geometrie/Normalen, Fresnel, Tiefenabsorption, versetzte Brechung | Keine Simulation von Strömung, Brandung oder objektabhängigen Wasserwellen |
| Spiegelung | Projektion eines Strahls durch die Tiefenkarte, Binärverfeinerung und Rand-Fade | Unsichtbare Bereiche verwenden analytischen Himmel; keine vollständigen Raytracing-Spiegelungen |
| Unterwasser | Wellenverzerrung, farbabhängige Absorption, beleuchteter Nebel, prozedurale Caustics | Caustics sind eine animierte Näherung, kein physikalisches Photonen-Tracing |
| Wolken | 3D-fBm-Dichte in einer Höhenschicht, Raymarching, Transmission und Lichtabtastung | Eine Wolkenschicht; keine volumetrische Wettersimulation. Vollauflösung kann teuer sein |
| Wolkenschatten | Dichteprojektion entlang der Lichtrichtung | Näherung der Wolkenoptik, keine zweite volumetrische Schattenkarte |
| Himmel | Analytischer Himmelsverlauf, Streufunktionen, Sonnen-/Mondscheibe, Sterne | Kein astronomisch korrekter Sternkatalog, keine integrierte Mehrfachstreuung |
| Nebel/Lichtstrahlen | Raymarch entlang des Blickstrahls; Shadowmap/Wolkenschatten modulieren Streulicht | Begrenzte Reichweite und Schrittzahl. In Innenräumen sind Lichtlecks möglich |
| PBR | Tangentenbasis aus Ableitungen, Normal-XY, Roughness aus Smoothness, Metallic-Klassifizierung | Vereinfachte labPBR-Auswertung; keine exakten metallabhängigen IOR-Tabellen, kein POM, kein vollständiger labPBR-Standard |
| Regen/Schnee | Regen verdichtet Wolken/Nebel, vermindert Sonne, macht Oberflächen nasser; Schnee behält helle Materialfarbe | Keine Schneeakkumulation; keine Tropfensimulation. Kühle Schnee-/Wetterschattierung ohne eigene saisonale Simulation |
| Gewitter | Iris-Blitzuniform beleuchtet sichtbare Materialien, dichtere Regenatmosphäre | Keine Vorhersage/Erzeugung eigener Blitze |
| Vegetation | Gleiche Windbewegung im GBuffer- und Shadowpass, Rücklichtnäherung | Kein eigener SSS-Volumenrenderer; bewegte Pflanzen besitzen keine separaten Bewegungsvektoren |
| Nether/End | Eigene Umgebungsfarben, Nebel, Emission; prozeduraler End-Himmel | Keine Sonne/Mond-Direktbeleuchtung in diesen Dimensionen |
| TAA | 8-Punkt-Jitter, Kamerareprojektion, Tiefenprüfung, 3×3-History-Clipping und Reset bei Sprüngen | Keine Objektbewegungsvektoren; Ghosting ist insbesondere bei Pflanzen/Wasser noch ingame zu prüfen |
| Bloom | Helle Bereiche separieren, horizontal/vertikal filtern, HDR-additiv zusammensetzen | Ein Filterradius, keine mehrstufige Bloom-Pyramide |
| Belichtung | Globale Luminanz aus Mipmaps, 1×1-History mit zeitlicher Anpassung | Keine lokale Belichtungsanpassung |
| Tiefenunschärfe | Fokus aus Bildmitte, tiefengeprüfte Disk-Abtastung | Vereinfachter Bokeh-Filter; Konturfehler möglich, standardmäßig aus |
| Motion Blur | Reprojektion anhand der Kamerabewegung | Keine individuelle Objektbewegungsunschärfe; standardmäßig aus |
| Farbe | Filmic-Tonemapping, Kontrastkurve um Mittelgrau mit erhaltenem Schwarzpunkt, Realistic/Cinematic/Vibrant/Natural/Dark Fantasy/Custom | Standard: Sättigung 0,90 / Kontrast 0,95. Custom entspricht eigenen Kontrast-/Sättigungs-/Belichtungswerten |

Die Verfahren sind in GLSL implementiert. Die technischen GPU-Prüfungen erfassen
ausgewählte Eigenschaften; keine Zeile dieser Tabelle behauptet einen bestandenen
Minecraft-Lauf oder garantiert fotorealistische Bildqualität. Adaptive Qualität
bedeutet hier manuelle Presets/Schrittzahlen; eine automatische FPS-Regelung gibt
es nicht. Die Sichtbarkeit und Qualität aller Effekte müssen in der Testwelt
zusammen mit Iris geprüft werden.
