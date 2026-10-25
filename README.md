# NERO REALISM ULTRA

**Beyond Vanilla. Beyond Realism.**

Eigenständiges GLSL-Shaderpack für **Minecraft Java 26.3 mit Iris und Sodium**.
Es ersetzt das bisherige Fortnite-Tweaks-Projekt in diesem Repository.
Die aktuelle Zielversion ist 26.3; der unveränderte ursprüngliche Entwicklungsauftrag
in `docs/BRIEF.md` beschreibt noch die frühere Zielversion 1.21.11.

Das Paket implementiert dynamische gefilterte Schatten, animiertes Wasser mit
Brechung und Screen-Space-Spiegelungen, volumetrische Wolken, beleuchteten Nebel,
Tag/Nacht-Himmel, Normal-/Specular-Mapping, SSAO und eine begrenzte indirekte
Screen-Space-Beleuchtung. TAA, Bloom, Belichtungsanpassung, Farbprofile und optional
Tiefenunschärfe sowie Kamerabewegungsunschärfe ergänzen die Pipeline.

**Status: technische Testversion (0.2.0).** Die Shader werden in einem echten
OpenGL-Kontext kompiliert und mit synthetischen Eingaben gerendert. Ein Lauf mit
Minecraft/Iris, die Abnahme der sichtbaren Qualität und reale Leistungsmessungen
stehen noch aus. Das ist kein Nachweis der visuellen Qualität von Complementary,
Bliss, Photon, BSL oder SEUS. Es wurde kein Code dieser Shaderpacks übernommen.

## Downloads und Installation

- [NeroRealismUltra-26.3.zip](dist/NeroRealismUltra-26.3.zip)
- [Neue Testwelt](dist/Nero-Test-World-26.3.zip)
- [Testszene als Datapack](dist/Nero-Test-Scene-26.3.zip)

Das Shader-ZIP unverändert in `.minecraft/shaderpacks` legen und in Iris auswählen.
Es enthält `shaders/` direkt auf ZIP-Ebene. Eine eigene Mod-JAR ist nicht nötig.
Iris, Sodium und Minecraft werden nicht mitgeliefert.
Die vollständige [Installationsanleitung](docs/INSTALLATION.md) nennt die Schritte.

## Profile

| Profil | Schatten | Distanz | Wolkenschritte | SSR | Indirektes Screen-Space-Licht |
|---|---:|---:|---:|---|---|
| LOW | 512 | 48 | 8 | aus, Himmel als Reflexionsersatz | aus |
| MEDIUM | 1024 | 80 | 12 | 12 Schritte | aus |
| HIGH | 2048 | 128 | 16 | 16 Schritte | an |
| ULTRA (Standard) | 2048 | 128 | 24 | 24 Schritte | an |
| CINEMATIC EXTREME | 4096 | 192 | 40 | 48 Schritte | an |

Alle Profile behalten Schatten, eigenes Wasser, Wolken und atmosphärische
Beleuchtung. EXTREME aktiviert zusätzlich Tiefenunschärfe. Für den ersten Start
empfiehlt sich HIGH; es gibt keine gemessene FPS-Zusage. Schattenauflösung,
Distanz, Filterung, Wasser, Wolken, Nebel und Nachbearbeitung sind einzeln einstellbar.

## Entwicklung

Python 3.10+ genügt zum reproduzierbaren Paketbau. Für die technischen Rendertests
werden PyOpenGL und ein EGL/OpenGL-Treiber mit Compatibility-Profil benötigt.

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
python3 tools/generate_programs.py
.venv/bin/python tools/validate.py
python3 tools/build.py
python3 -m unittest discover -s tests -v
```

Die Cloud-Werkzeuge liegen außerhalb des Repositorys; siehe die gespeicherten
Umgebungsanweisungen. Der bisherige PowerShell-Workflow wird nicht mehr benötigt.
Die erzeugten ZIPs und SHA256-Dateien liegen in `dist/`.

## Dokumentation

- [Effekte, Verfahren und Grenzen](docs/EFFECTS.md)
- [Kompatibilität und Pipeline](docs/COMPATIBILITY.md)
- [Testwelt, Vergleichsansichten und Teststatus](docs/TESTING.md)
- [Änderungen](CHANGELOG.md)
- [Unveränderter Entwicklungsauftrag](docs/BRIEF.md)
