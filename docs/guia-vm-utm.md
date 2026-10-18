# Guía: configurar una máquina virtual de DreamByte OS TV en UTM

> **Estado honesto:** a fecha 2026-10-17 **todavía no existe una ISO de DreamByte OS TV** (el build llega en la Fase 2). Esta guía es el procedimiento que se usará; el nombre de archivo `dreambyte-os-tv-0.1-<arch>.iso` es el previsto. Mientras tanto, la Parte A sirve para validar tu UTM con un Linux real.

## Qué equipo tienes (cambia todo)

| Tu equipo | Qué hace UTM | Arquitectura de la ISO |
|---|---|---|
| Mac con Apple Silicon (M1+) | **Virtualiza** ARM64 (rápido) | `arm64` |
| Mac con Apple Silicon, ISO x86_64 | **Emula** (muy lento) | `amd64` (solo para probar arranque) |
| Mac Intel | Virtualiza x86_64 | `amd64` |
| iPad / iPhone | Solo **emula** (sin Hypervisor); más lento aún | `arm64` para probar arranque |
| PC con Windows/Linux | Usa QEMU/VirtualBox; UTM no aplica | `amd64` |

Regla: elige la ISO con la **misma** arquitectura que tu equipo siempre que puedas.

## Parte A — Validar UTM hoy (con un Linux real)

1. Instala UTM (utmapp.com / App Store según tu dispositivo).
2. Descarga una ISO oficial de **Debian estable** para tu arquitectura (netinst) desde debian.org.
3. Crea la VM siguiendo la Parte B usando esa ISO. Si arranca e instala, tu UTM está listo.

## Parte B — Crear la VM (cuando exista la ISO)

1. **Crear nueva máquina virtual → Virtualizar** (si la arquitectura coincide con tu equipo) o **Emular** (si no).
2. **Sistema operativo: Linux.** Marca *Use Apple Virtualization* solo si no necesitas GPU 3D; para pruebas gráficas es preferible el backend **QEMU**.
3. **Hardware:**
   - Memoria: **4096 MB** (mínimo 2048).
   - CPU: **4 núcleos** (mínimo 2).
   - Marca **Enable hardware OpenGL acceleration** si aparece.
4. **Arranque:** selecciona **Boot ISO image** y elige `dreambyte-os-tv-0.1-<arch>.iso`.
5. **Almacenamiento:** **16 GB** (mínimo para instalar; el disco es dinámico y no ocupa todo de golpe).
6. **Carpeta compartida:** omítela.
7. Resumen → **Guardar** con el nombre `DreamByte OS TV`.

### Ajustes recomendados antes de arrancar (editar VM)

| Sección | Ajuste |
|---|---|
| QEMU | **UEFI Boot** activado |
| Display | Tarjeta `virtio-gpu-gl-pci` (con aceleración) o `virtio-gpu-pci`; resolución 1920×1080 si tu pantalla lo permite |
| Network | **Shared Network** (NAT): lo normal. **Bridged** solo si necesitas que la VM tenga IP en tu red |
| Sound | `intel-hda` o `virtio-snd` |
| Input | Teclado y ratón por defecto; para mando USB, usa *USB Sharing* si tu plataforma lo permite |

## Parte C — Primer arranque

1. Inicia la VM. Deberías ver el gestor de arranque y, después, la pantalla de bienvenida de DreamByte OS TV.
2. Elige **Probar sin instalar** o **Instalar**.
3. Para instalar: el instalador mostrará el **disco de destino** (tu disco virtual de 16 GB) y pedirá **confirmación explícita** antes de formatear. Comprueba el tamaño: debe ser el virtual.
4. Al terminar, **apaga la VM**, entra a la configuración y **quita la ISO** (Drive CD/DVD → *Clear*), luego arranca de nuevo para comprobar que el arranque persiste.

## Parte D — Carpeta compartida con tu equipo (pendiente de validación)

Sirve para pasar archivos entre tu equipo y la VM. Dentro de DreamByte OS TV solo se podrán **explorar, copiar, mover, renombrar y borrar** archivos desde la app **Archivos**; no hay terminal ni edición del sistema.

1. Apaga la VM → **Editar → Sharing**.
2. Elige el modo según el backend:
   - **QEMU:** *VirtFS* (9p) → selecciona la carpeta de tu equipo.
   - **Apple Virtualization (solo Mac):** *VirtioFS* → selecciona la carpeta.
3. Arranca la VM. DreamByte OS TV montará la carpeta compartida y aparecerá como **«Compartida»** en la app Archivos.
4. Prueba: crea un archivo de texto en la carpeta de tu equipo y comprueba que aparece en la VM; luego renómbralo desde la app Archivos y comprueba el cambio en tu equipo.

Para el desarrollo (Fase 2) el montaje previsto en el sistema es, según el modo:

```bash
# VirtFS (9p), backend QEMU
mount -t 9p -o trans=virtio,version=9p2000.L share /media/compartida
# VirtioFS, backend Apple Virtualization
mount -t virtiofs share /media/compartida
```

(`share` es la etiqueta que UTM asigna; se confirmará al probar.) Limitaciones esperadas: los permisos y propietarios pueden aparecer distintos a los de tu equipo, y en iPad/iPhone la opción puede no existir.

## Versiones de la ISO

| Archivo previsto | Para |
|---|---|
| `dreambyte-os-tv-0.1-arm64.iso` | Mac con Apple Silicon (virtualizado), ARM |
| `dreambyte-os-tv-0.1-amd64.iso` | PC / mini-PC / Mac Intel, o emulado en otros equipos |

## Notas y límites reales

- **Wi‑Fi:** UTM no pasa tu tarjeta Wi‑Fi a la VM; el sistema verá una Ethernet virtual con la conexión del anfitrión.
- **Rendimiento:** 1080p/60 FPS es un objetivo, no una garantía. Con emulación (arquitectura distinta) espera ir muy lento.
- **Vídeo:** sin decodificación por hardware en VM; será por software.
- **Netflix:** sin validar; no esperes que funcione en la VM.
- **DreamByte Link:** el conector es un concepto; en la VM no hay forma de probarlo.

## Si algo falla

| Síntoma | Qué probar |
|---|---|
| Pantalla negra al arrancar | Activar UEFI Boot; probar `virtio-gpu-pci` (sin GL) |
| No arranca la ISO | Comprobar que la ISO coincide con la arquitectura de la VM |
| Muy lento | Dar más RAM/CPU; usar ISO de la arquitectura nativa |
| No arranca tras instalar | Quitar la ISO y arrancar desde el disco |
