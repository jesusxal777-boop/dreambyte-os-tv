# DreamByte OS TV — Fase 0: Viabilidad

Estado: **borrador 0.1** · Autor: DreamByte Studios · Fecha: 2026-10-17

> Esta fase es análisis y decisiones. **No existe todavía ninguna ISO, imagen ni código de interfaz.** Todo lo marcado como "pendiente de validación" debe probarse en la Fase 1/2 antes de afirmarse.

## 1. Resumen ejecutivo

Es viable construir DreamByte OS TV como un sistema **arrancable y real**, pero con una condición: **no compilar el kernel ni el userland desde cero**. La ruta realista y gratuita es una base **Debian estable mínima** (kernel Linux real de Debian), generada con `live-build` en CI gratuito de GitHub, sin escritorio tradicional: arranca directo a un compositor Wayland en modo kiosco que ejecuta la interfaz de TV.

Lo más difícil no es el SO, es el **contenido protegido** (Netflix/DRM) y la **aceleración gráfica en UTM**. Ambos quedan como *pendiente de validación*.

## 2. Decisiones técnicas

| Área | Decisión | Por qué | Alternativa descartada |
|---|---|---|---|
| Kernel | Kernel Linux de Debian (paquete `linux-image`) | Real, mantenido, con drivers Wi‑Fi/GPU; sin compilar kernel | Kernel propio: horas de compilación, sin ventaja en 0.1 |
| Base | Debian estable (trixie) mínima vía `debootstrap`/`live-build` | Repositorios enormes (Mesa, GStreamer, NetworkManager, emuladores), builds reproducibles, ISO híbrida | Buildroot (sin navegador/emuladores listos), Yocto (curva alta, builds muy largos) |
| Init | systemd | Estándar en Debian, sesiones y servicios maduros | runit/OpenRC: más ligero pero más trabajo |
| Gráficos | DRM/KMS + Mesa + Wayland | Camino moderno, sin X11 | X11: legado |
| Compositor | **Cage** (wlroots, kiosco de una sola app); `labwc` como plan B | Una app a pantalla completa = comportamiento de TV | GNOME/KDE: escritorio pesado (prohibido por el prompt) |
| Interfaz | **Qt 6 / QML** (Qt Wayland) | Animaciones por GPU, foco por teclado/mando nativo, ARM64 y x86_64, LGPL | Flutter Linux: viable, pero más piezas de integración; se reevalúa tras el prototipo |
| Red | NetworkManager | Estándar real, Ethernet/Wi‑Fi/proxy/DNS | wpa_supplicant directo: más trabajo |
| Audio | PipeWire | Estándar actual con WirePlumber | PulseAudio |
| Multimedia | GStreamer (reproductor propio en Qt) y `mpv` como respaldo | Licencias claras, aceleración VA-API cuando exista | FFmpeg directo: más código propio |
| Navegador | Motor real: Firefox ESR o Chromium de Debian (a decidir en pruebas) | No se construye un motor | Motor propio: descartado por el prompt |
| Paquetes (Store) | Repositorio `.deb`/APT firmado propio y/o `pkg` de [DreamByte-Package-Repository] | Verificación criptográfica ya resuelta por APT | Scripts arbitrarios: prohibido |
| Build/CI | GitHub Actions (repo público) | Gratis y editable desde un dispositivo modesto | PC propio potente: no se asume |

## 3. Arquitectura propuesta

```
┌────────────────────────── DreamByte OS TV ──────────────────────────┐
│  Interfaz de TV (Qt/QML)  ← única experiencia visible               │
│   Inicio · Apps · Películas · TV · YouTube · Navegador · Juegos ·   │
│   Biblioteca · Archivos · Store · Perfiles · Ajustes · Info          │
├─────────────────────────────────────────────────────────────────────┤
│ Servicios DreamByte (D-Bus, usuario sin privilegios)                │
│  dbtv-profiles · dbtv-library · dbtv-files · dbtv-apps · dbtv-emu   │
├─────────────────────────────────────────────────────────────────────┤
│ Gestor de sesión: greetd/autologin → Cage (Wayland kiosco)          │
├─────────────────────────────────────────────────────────────────────┤
│ NetworkManager · PipeWire · udev/libinput · UPower · PackageKit/APT │
├─────────────────────────────────────────────────────────────────────┤
│ systemd · kernel Linux (Debian) · DRM/KMS · Mesa · GRUB/UEFI        │
└─────────────────────────────────────────────────────────────────────┘
```

Reglas: la UI **no corre como root**; la lógica de sistema vive en servicios con D‑Bus y polkit; la UI solo los llama. Contraseñas de perfiles/Wi‑Fi: almacén del sistema (NetworkManager/secret service), nunca en texto plano. Actualizaciones: APT firmado + snapshot/rollback (A/B o `grub` con entrada de recuperación; diseño en Fase 2).

## 4. Arquitectura objetivo inicial

| Arquitectura | Rol | Notas UTM |
|---|---|---|
| **ARM64 (aarch64)** | **Objetivo inicial de desarrollo** | En Mac con Apple Silicon UTM puede *virtualizar* (rápido). En iPad/iPhone UTM solo *emula* (lento): útil para probar arranque, no rendimiento. |
| **x86_64 (amd64)** | Objetivo paralelo (necesario para mini‑PC y PC reutilizados) | En UTM sobre Apple Silicon se *emula* con QEMU (muy lento para vídeo/animaciones). En PC x86 real o UTM en Mac Intel sí es nativo. |

**Decisión (confirmada por el usuario, 2026-10-17): se publican las dos versiones, `arm64` y `amd64`**, construidas desde el mismo repo (live-build soporta ambas). Se empieza por `arm64`; el usuario prueba desde un iPad (UTM solo emula). El rendimiento de la UI se mide primero en ARM64 virtualizado y en hardware x86_64 real.

Consecuencia: cada función de la matriz se valida **por arquitectura**; algo que funcione en `amd64` (p. ej. Widevine) puede no funcionar en `arm64`.

## 5. Matriz de funciones (estado a 0.1)

| Función | Estado | Notas |
|---|---|---|
| Arranque ISO / disco virtual (UEFI) | **Viable** | Estándar con live-build + GRUB EFI |
| Interfaz Qt/QML con foco teclado/mando | **Viable** | Prototipo en Fase 1 |
| Cage + Wayland kiosco | **Viable** | Pendiente de probar con virtio-gpu en UTM |
| 1080p/60 FPS en UTM | **Pendiente de validación** | Depende de GPU virtual y de virtualización vs emulación |
| Aceleración 3D en la VM (virtio-gpu/Virgl) | **Experimental** | Depende de la versión de UTM y backend |
| Decodificación de vídeo por hardware en VM | **Bloqueada/improbable** en VM | Solo software; HW real puede usar VA‑API |
| Red (Ethernet virtual, NAT/puente) | **Viable** | NetworkManager |
| Wi‑Fi en hardware real | **Pendiente de validación** | Depende de chipset, driver y firmware; en VM se usa red virtual del anfitrión |
| Wi‑Fi físico dentro de UTM | **Bloqueada** (salvo passthrough) | No asumir |
| Perfiles locales | **Viable** | Datos locales, sin reconocimiento facial |
| Gestor de archivos limitado (`dbtv-files`) | **Viable** | Solo explorar, copiar, mover, renombrar y borrar (con confirmación) dentro de ubicaciones permitidas: carpeta del perfil, medios USB y carpetas compartidas. Sin terminal, sin root, sin editar archivos del sistema |
| Carpetas compartidas con la VM (UTM) | **Pendiente de validación** | Con backend QEMU: VirtFS (9p). Con Apple Virtualization: VirtioFS. El kernel de Debian incluye los módulos; hay que probar permisos/propietarios y el montaje automático. En iPad/iPhone puede no estar disponible |
| Portapapeles/arrastre con el anfitrión | **Pendiente de validación** | Requiere agentes SPICE; en kiosco Wayland puede no funcionar |
| Reproductor local (GStreamer) | **Viable** | Códecs según licencias de Debian |
| Navegador | **Viable** | Motor existente; UI de TV con foco: trabajo propio |
| YouTube (web/PWA) | **Pendiente de validación** | Se prueba login, reproducción y subtítulos; sin app oficial para Linux TV |
| **Netflix / Widevine** | **Pendiente de validación (riesgo alto)** | Requiere navegador y CDM Widevine compatibles con la plataforma; calidad en Linux suele estar limitada; en ARM64 y en VM puede no funcionar. No se elude DRM. Alternativa: navegador admitido o dispositivo externo |
| TV en directo | **Pendiente de validación** | Solo fuentes legales (señales públicas oficiales, FAST legítimos, IPTV autorizado, sintonizadores compatibles). Sin lista de canales inventada |
| Películas y series (catálogo) | **Experimental** | Requiere proveedor autorizado de metadatos (p. ej. API con clave propia); sin clave no hay catálogo real |
| Emuladores (RetroArch, PPSSPP, Dolphin) | **Experimental** | RetroArch es el más viable; Dolphin/PPSSPP exigen GPU; en UTM emulado casi inviable. Sin ROM/BIOS incluidas |
| Detección de mandos | **Viable** (HW real) / limitada en VM | libinput/evdev/SDL |
| DreamByte TV Store | **Experimental** | Repositorio APT firmado; no instalar "tarjetas" falsas |
| Instalador en disco | **Viable** | Con confirmación explícita antes de formatear |
| Actualizaciones con rollback | **Pendiente de diseño** | Fase 2 |
| **DreamByte Link (conector)** | **Concepto** | Solo existen planos de concepto; no hay especificación eléctrica, hardware ni driver. Ver guía de ayuda |

## 6. Alcance realista de la versión 0.1

Prioridad del proyecto: **sistema y navegador primero**; streaming en beta; el resto por etapas.

Dentro: ISO arrancable en UTM (ARM64), arranque a la UI en Cage, navegación con teclado/ratón/mando, red por NAT, pantalla de bienvenida con DreamBot, ajustes básicos, navegador y reproductor local, perfiles simples, instalación a disco virtual.
Fuera (0.2+): Netflix, TV en directo, catálogo de películas, emuladores, Store completa, DreamByte Link.

## 7. Estructura del repositorio

```
dreambyte-os-tv/
├─ README.md
├─ assets/
│  ├─ brand/                  logo, nube, DreamBot, wordmark Studios (originales)
│  └─ link/                   planos de concepto DreamByte Link
├─ docs/
│  ├─ 00-fase0-viabilidad.md  (este archivo)
│  ├─ 01-decisiones.md        registro de decisiones técnicas (ADR) — se crea en Fase 1
│  └─ guia-vm-utm.md
├─ help/
│  └─ conectar-accesorios.html   guía de ayuda (DreamByte Link)
├─ ui/                        (Fase 1) app Qt/QML + prototipo navegable
├─ services/                  (Fase 2/3) servicios D-Bus dbtv-*
├─ image/                     (Fase 2) config de live-build
│  ├─ config/package-lists/
│  ├─ config/includes.chroot/
│  └─ config/hooks/
├─ build/                     scripts: build.sh, test-qemu.sh
├─ packaging/                 .deb y repositorio APT firmado (Store)
└─ .github/workflows/         CI: build de ISO amd64 y arm64
```

## 8. Plan de compilación y pruebas

1. **CI** (GitHub Actions, repo público): job `build-iso` con `live-build` para `amd64` y `arm64` (límites de minutos/almacenamiento y disponibilidad de runners ARM: *verificar vigentes antes de depender de ello*).
2. Artefacto: ISO híbrida + SHA256 + firma.
3. **Prueba automática** mínima: arrancar la ISO con QEMU sin pantalla y verificar que el servicio de la UI llega a `active` (captura de pantalla como evidencia).
4. **Prueba manual** en UTM siguiendo `docs/guia-vm-utm.md`.
5. Una fase se declara terminada solo con evidencia: log de CI, captura de pantalla, hash de la ISO.

## 9. Preparar el entorno de desarrollo (comandos)

En una máquina Debian/Ubuntu (o un entorno Linux en la nube):

```bash
sudo apt update
sudo apt install -y git live-build debootstrap squashfs-tools xorriso \
  grub-efi-amd64-bin grub-efi-arm64-bin mtools dosfstools qemu-system-x86 \
  qemu-system-arm qemu-utils ovmf qemu-efi-aarch64 shellcheck
git clone https://github.com/jesusxal777-boop/dreambyte-os-tv.git
cd dreambyte-os-tv
```

Para la UI (Fase 1), en el mismo entorno: `sudo apt install -y qt6-base-dev qt6-declarative-dev qml6-module-* qt6-wayland cage`.

> Estos son los paquetes reales previstos; los nombres exactos se confirman en el primer build de Fase 2.

## 10. Riesgos y alternativas

| Riesgo | Impacto | Alternativa |
|---|---|---|
| Sin aceleración 3D en UTM, la UI no llega a 60 FPS | Alto | UI con animaciones simples (transform/opacity), modo "animaciones reducidas", medir en HW real |
| Netflix no reproduce (Widevine/arquitectura/VM) | Alto | Abrir en navegador admitido o dispositivo externo; documentar límites |
| iPad/iPhone solo emulan | Medio | Usar CI + capturas, o probar en un Mac/PC prestado |
| Compilar en un dispositivo modesto | Medio | Todo en CI gratuito; editar desde GitHub |
| Wi‑Fi no soportado en HW real | Medio | Ethernet, adaptadores USB con driver en kernel, lista de compatibilidad |
| Licencias de códecs/emuladores | Medio | Paquetes de Debian, sin ROM/BIOS, aviso al usuario |
| DreamByte Link sin hardware | Medio | Mantenerlo como concepto; mientras tanto accesorios por USB/Bluetooth/HDMI estándar |

## 11. Siguiente paso

Fase 2 reducida: imagen `arm64` con `live-build`, compilada en GitHub Actions, que arranque al navegador. Después, Fase 1 (prototipo visual) con datos de demostración **etiquetados como demo**.

[DreamByte-Package-Repository]: https://github.com/jesusxal777-boop/DreamByte-Package-Repository
