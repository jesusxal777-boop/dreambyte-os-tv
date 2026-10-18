# DreamByte OS TV

Sistema operativo multimedia experimental para televisores, monitores, mini‑PC y máquinas virtuales, basado en Linux. Por **DreamByte Studios**.

**Versión:** 0.1 Experimental · **Fase actual:** 2 (sistema arrancable, en progreso)

> **Estado honesto:** la ISO solo existe si el flujo de [Actions](../../actions) termina en verde y publica el artefacto. Nada de lo que aparece como «pendiente de validación» en la matriz de funciones está probado.

| Documento | Contenido |
|---|---|
| [docs/00-fase0-viabilidad.md](docs/00-fase0-viabilidad.md) | Análisis, arquitectura, matriz de funciones, repo, build, riesgos |
| [docs/guia-vm-utm.md](docs/guia-vm-utm.md) | Cómo configurar una VM en UTM |
| [help/conectar-accesorios.html](help/conectar-accesorios.html) | Guía de ayuda: cómo conectar accesorios (DreamByte Link, concepto) |

## Qué contiene la imagen 0.1

Debian estable (trixie) mínima con kernel Linux de Debian, NetworkManager, PipeWire, **Cage** (compositor Wayland en modo kiosco) y **Firefox ESR** como navegador, con una página de inicio propia. Idioma por defecto: español (México).

Aún no incluye: interfaz Qt/QML de TV, instalador, perfiles, Store, emuladores ni TV en directo.

## Compilar la ISO

En GitHub: pestaña **Actions → build-iso → Run workflow** (arm64 siempre; marca *amd64* para la versión experimental). La ISO sale como artefacto descargable.

En una máquina Debian trixie como root:

```bash
build/build.sh arm64   # o amd64
```

## Licencia

Código y documentación: **MIT** (`LICENSE`). Nombre, logotipos, mascota DreamBot y diseños de marca: **todos los derechos reservados** (`BRAND.md`).
