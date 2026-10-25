# Kompatibilität und Pipeline

Ziel: Minecraft Java 1.21.11, Iris für genau diese Spielversion und dessen passende
Sodium-Abhängigkeit. Als Format-/Implementierungsreferenz wurde der offizielle
[Iris-Zweig 1.21.11](https://github.com/IrisShaders/Iris/tree/0a1fcaae55099356bf53410b4f5302753edb0ffc)
geprüft. Dieser Stand nennt Iris 1.10.8 und Sodium 0.8.14 für Minecraft 1.21.11.
Das ist eine Quellcodeprüfung, kein Nachweis eines getesteten installierten Builds.
Für die Installation die tatsächlich veröffentlichte kompatible Kombination wählen.

Weitere Referenzen: [Iris ShaderDoc](https://github.com/IrisShaders/ShaderDoc),
Iris `ProgramId`, `ShaderProperties`, `FeatureFlags`, die Dokumentation zu
Renderzielen, Uniforms und Vertexattributen. Datenversionswerte der Testwelt:
Minecraft 1.21.11 / DataVersion 4671 / Datapack 94.1, abgeglichen mit
[mcmeta-Versionsdaten](https://github.com/misode/mcmeta/tree/summary/versions).
Keine GLSL-Dateien anderer Shaderpacks wurden kopiert.

## Reihenfolge

1. `shadow`: Geometrie, identischer Pflanzen-/Wasserwind, Tiefe und Transparenzfarbe.
2. `gbuffers_*`: Vorwärtsbeleuchtung mit Schatten und PBR; HDR-Farbe, Normale und Material.
3. `deferred`: AO/indirekte Screen-Space-Näherung, Himmel/Wolken, unveränderlicher
   Farbschnappschuss für die folgende transparente Geometrie.
4. `gbuffers_water` und transparente Programme: Wasserbrechung/-spiegelung liest
   den Schnappschuss, schreibt aber andere Anhänge. Keine Feedback-Schleife auf
   derselben Textur im selben Pass.
5. `composite`: Materialspiegelungen, Unterwasserabsorption, räumlicher Nebel.
6. `composite1`: zeitliche Auflösung; Farb-/Tiefenhistory für das nächste Bild.
7. `composite2`: horizontale Bloom-Extraktion/-Filterung.
8. `composite3`: auf 1×1 reduzierte Belichtungsanpassung mit eigener History.
9. `final`: optionale DOF/Kameraunschärfe, vertikaler Bloom, Tonemapping und Farbe.

## Renderziele

| Ziel | Format | Inhalt |
|---|---|---|
| colortex0 | RGBA16F | lineares HDR-Bild |
| colortex1 | RGBA16F | Weltnormale, Roughness |
| colortex2 | RGBA8 | lineare Albedo und Materialkennung |
| colortex3 | RGBA16F | opaker Farbschnappschuss; keine transparente Feedback-Schleife |
| colortex4 | RGBA16F | persistente TAA-Farbe und lineare Blickraumtiefe |
| colortex5 | RGBA16F | horizontal gefilterter Bloom |
| colortex6 | RGBA16F, 1×1 | persistente Belichtung |

Iris übernimmt das Ping-Pong der Composite-/Deferred-Ziele. `colortex4Clear=false`
und `colortex6Clear=false` erhalten die Historien; der Code verwirft uninitialisierte
History und Kamerasprünge. Shadowmaps bleiben Tiefentexturen ohne Hardwarevergleich,
weil die farbige Transmission beide Shadow-Tiefen benötigt.

GLSL 330 mit Compatibility-Semantik; für unabhängiges Blending pro Attachment wird
Iris `PER_BUFFER_BLENDING` verlangt. Außerdem wird `ENTITY_TRANSLUCENT` verwendet.
Für Desktop-GPUs mit OpenGL 4.x ausgelegt. macOS, alternative Dimension-Mods,
Distant Horizons, VR, OptiFine und fremde Rendering-Mods sind nicht validiert.
Es werden keine speziellen DH-/VR-Pässe behauptet.
