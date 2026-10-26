# Kompatibilität und Pipeline

Ziel: Minecraft Java 26.3, Iris für genau diese Spielversion und dessen passende
Sodium-Abhängigkeit. Als Format-/Implementierungsreferenz wurde der offizielle
[Iris-Zweig 26.3](https://github.com/IrisShaders/Iris/tree/671a5c87747d33983d7ed659461a64f46dfcb1f0)
geprüft. Dieser Stand nennt Iris 1.11.6 und Sodium 0.9.2 für Minecraft 26.3.
Das ist eine Quellcodeprüfung, kein Nachweis eines getesteten installierten Builds.
Für die Installation die tatsächlich veröffentlichte kompatible Kombination wählen.
Der Iris-Quellbuild verwendet Java 25; beim Spielen die passende, vom Launcher
bereitgestellte Java-Laufzeit verwenden.

Die benötigten GBuffer-/Composite-Programmnamen, Pack-Eigenschaften, Feature-Flags
und verwendeten Uniforms wurden gegen diesen Zweig geprüft. Dafür war keine Änderung
der GLSL-Effekte erforderlich. Die Versionsumstellung aktualisiert Paketnamen,
Welt-Datenversion, Datapack-Format und Anleitung; eine Ingame-Abnahme für 26.3
steht weiterhin aus.

Weitere Referenzen: [Iris ShaderDoc](https://github.com/IrisShaders/ShaderDoc),
Iris `ProgramId`, `ShaderProperties`, `FeatureFlags`, die Dokumentation zu
Renderzielen, Uniforms und Vertexattributen. Datenversionswerte der Testwelt:
Minecraft 26.3 / DataVersion 5023 / Datapack 121.0, abgeglichen mit
[mcmeta-Versionsdaten](https://github.com/misode/mcmeta/blob/26.3-summary/version.json).
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
| colortex4 | RGBA16F | persistente TAA-Farbe und lineare Blickraumtiefe |
| colortex5 | RGBA16F | horizontal gefilterter Bloom |
| colortex6 | RGBA16F, 1×1 | persistente Belichtung |
| colortex7 | RGBA16F | opaker Farbschnappschuss; keine transparente Feedback-Schleife |

`deferred` schreibt mit `DRAWBUFFERS:07` das Bild gleichzeitig nach `colortex0`
und `colortex7`. Wasser und Spiegelungen lesen den Schnappschuss aus `colortex7`.
Iris bindet `colortex0` bis `colortex3` ausschließlich in Vollbildpässen
(`IrisSamplers.addRenderTargetSamplers`, Startindex 4 für Geometrie). Die frühere
Nutzung von `colortex3` im Wasserpass war deshalb fehlerhaft, obwohl der GLSL-Code
kompilierte. `colortex3` wird seit 0.2.3 nicht mehr vom Shaderpack verwendet.

Iris übernimmt das Ping-Pong der Composite-/Deferred-Ziele. `colortex4Clear=false`
und `colortex6Clear=false` erhalten die Historien; der Code verwirft uninitialisierte
History und Kamerasprünge. Shadowmaps bleiben Tiefentexturen ohne Hardwarevergleich,
weil die farbige Transmission beide Shadow-Tiefen benötigt.

GLSL 330 mit Compatibility-Semantik; für unabhängiges Blending pro Attachment wird
Iris `PER_BUFFER_BLENDING` verlangt. Außerdem wird `ENTITY_TRANSLUCENT` verwendet.
Für Desktop-GPUs mit OpenGL 4.x ausgelegt. macOS, alternative Dimension-Mods,
Distant Horizons, VR, OptiFine und fremde Rendering-Mods sind nicht validiert.
Es werden keine speziellen DH-/VR-Pässe behauptet.
