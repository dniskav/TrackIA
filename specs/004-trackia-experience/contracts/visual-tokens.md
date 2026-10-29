# Contrato: tokens visuales y componentes

Colores muestreados de `assets/branding/trackia-icon-master.png` (anillo `#027D92`, flecha
`#FE6101` → `#F52C1F` → `#DC0148`). Contrastes calculados con la fórmula WCAG 2.x
(luminancia relativa). Los valores son **fijos**: no elegir otros sin actualizar este contrato.

## Paleta de marca

| Token | Hex | Uso |
|---|---|---|
| `brandTeal` | `#027D92` | Marca, botón Iniciar, primario en claro |
| `brandTealLight` | `#35B5CB` | Primario en oscuro (texto, iconos, contornos) |
| `brandOrange` | `#FE6101` | Inicio del degradado; nunca relleno de botón |
| `brandRed` | `#F52C1F` | Punto medio del degradado |
| `brandCrimson` | `#DC0148` | Fin del degradado y botón Parar |
| `brandGradient` | `#DC0148 → #F52C1F → #FE6101` | Arco de progreso, flecha del logo, anillos de metas |

## Tema oscuro (`gymTheme` en `lib/ui/theme.dart`)

| Rol | Hex | Contraste medido |
|---|---|---|
| `background` (scaffold, AppBar) | `#0A1A20` | — |
| `surface` (tarjetas, paneles) | `#12303A` | — |
| `onSurface` / texto principal | `#E6EEF0` | 15,11 sobre fondo; 11,83 sobre superficie |
| `onSurfaceVariant` / secundario | `#9DB8BE` | 8,49 sobre fondo; 6,65 sobre superficie |
| `primary` | `#35B5CB` | 7,30 sobre fondo; 5,71 sobre superficie |
| `onPrimary` | `#0A1A20` | sobre `#35B5CB`: 7,30 |
| `outlineVariant` (bordes decorativos) | `#1F4A55` | decorativo |
| `error` | `#FF8FA3` | 6,43 sobre superficie |
| `inputFill` | `#0A1A20` | — |
| Pista del anillo | `#1E5A68` | decorativo |
| Texto «en curso» | `#FF8A4D` | 5,96 sobre superficie |

## Tema claro (`gymLightTheme`)

| Rol | Hex | Contraste medido |
|---|---|---|
| `background` | `#F6FAFA` | — |
| `surface` | `#FFFFFF` | — |
| `onSurface` | `#0A1A20` | 16,90 sobre fondo |
| `onSurfaceVariant` | `#4B6670` | 5,82 sobre fondo; 6,12 sobre blanco |
| `primary` | `#027D92` | 4,59 sobre fondo; 4,83 sobre blanco |
| `onPrimary` | `#FFFFFF` | 4,83 |
| `outlineVariant` | `#BCD3D8` | decorativo |
| `error` | `#B0003A` | 7,22 sobre blanco |
| `inputFill` | `#E9F3F4` | — |
| Pista del anillo | `#BFDCE2` | decorativo |
| Texto «en curso» | `#C2410C` | 5,18 sobre blanco |

## Botones

| Rol | Relleno | Texto | Contraste | Notas |
|---|---|---|---|---|
| Iniciar (`FilledButton`, acción de empezar) | `#027D92` en ambos temas | `#FFFFFF`, `FontWeight.w700` | 4,83 | Icono `Icons.play_arrow` |
| Parar (acción de detener un tramo) | `#DC0148` en ambos temas | `#FFFFFF`, `FontWeight.w700` | 5,07 | Icono `Icons.stop` |
| Secundario (Terminar, Dictar, Editar…) | transparente | `primary` del tema | 5,71 oscuro / 4,83 claro | Borde 1,5 px del color `primary` (no `outlineVariant`) |
| Destructivo (Borrar, Eliminar configuración) | transparente | `error` del tema | ≥ 6,4 | Separado del primario por al menos 24 px |

Prohibido: texto negro sobre naranja; texto blanco sobre `#FE6101` (3,03). Altura mínima 54 px para
el botón principal del panel (como el tema actual), radio 16. Un solo botón con relleno por vista.

## Componentes

**`TimerRing`** (`lib/ui/timer_ring.dart`): tamaño 132 × 132 px lógicos en el panel expandido;
trazo 9 px; pista con el color «Pista del anillo» del tema; arco con `brandGradient` (barrido desde
las 12 en sentido horario, extremos redondeados); cuatro marcas de 6 × 3 px a las 12, 3, 6 y 9 con
`primary`; texto del tiempo centrado, 26 px, `FontWeight.w500`, `onSurface`, con
`fontFeatures: [FontFeature.tabularFigures()]`. Progreso = transcurrido / `activitySeconds` (cuenta
atrás) o, si no hay duración, el arco no se dibuja y solo se muestran pista, marcas y cronómetro.
`Semantics(label: 'Tiempo: mm:ss')`. El anillo es complementario; el texto es la información.

**`TrackiaMark`** (`lib/ui/trackia_mark.dart`): `CustomPainter` del logo: anillo abierto arriba a la
derecha con `brandTeal` (claro) o `brandTealLight` (oscuro), cuatro marcas y flecha con `brandGradient`
desde el centro hacia arriba a la derecha. Tamaños de uso: 96 px (bienvenida) y 32 px (Ajustes).
Sustituye a `Image.asset('assets/branding/trackia-logo.png')` en pantallas con fondo oscuro.

**Barra compacta del panel** (sin actividad): altura 64 px, superficie, texto «Sin actividad» 15 px
`w500` y subtítulo «Registra una cuando quieras» 12 px secundario; a la derecha botón secundario
«Nueva actividad» con `Icons.add`.

**Panel expandido**: borde superior 3 px `brandOrange` solo cuando un tramo está en marcha; nombre
15 px `w500`; a la derecha «{Segmento} {n} de {total}» 11 px secundario; `TimerRing`; contadores
rápidos (si hay campos `number`); botón principal; fila de secundarios.

## Iconos de acompañante (IDs → `Icons`)

`barbell` → `fitness_center` · `hourglass` → `hourglass_top` · `leaf` → `spa` · `notebook` →
`menu_book` · `sparkles` → `auto_awesome` · `book` → `auto_stories` · `water` → `water_drop` ·
`run` → `directions_run` · `bike` → `directions_bike` · `ball` → `sports_soccer` · `music` →
`music_note` · `brush` → `brush` · `work` → `work_outline` · `pill` → `medication` · `heart` →
`favorite_border` · `school` → `school`.

## Colores de acompañante (ID → oscuro / claro)

Se usan para el icono y su fondo circular (el mismo color al 20 % de opacidad sobre la superficie).

| ID | Oscuro | Contraste sobre `#12303A` | Claro | Contraste sobre `#FFFFFF` |
|---|---|---|---|---|
| `teal` | `#35B5CB` | 5,71 | `#027D92` | 4,83 |
| `orange` | `#FF8A4D` | 5,96 | `#C2410C` | 5,18 |
| `green` | `#7FD6A4` | 7,99 | `#2E7D4F` | 5,05 |
| `amber` | `#F2C46D` | 8,54 | `#8A5A00` | 5,93 |
| `crimson` | `#FF6B8E` | 5,13 | `#B0003A` | 7,22 |
| `violet` | `#B4A2F0` | 6,20 | `#5B44B3` | 7,19 |

## Iconos de logro (IDs → `Icons`)

`first` → `rocket_launch` · `streak` → `local_fire_department` · `record` → `military_tech` ·
`time` → `schedule` · `count` → `task_alt` · `variety` → `explore` · `trophy` → `emoji_events`.
Logro bloqueado: icono `lock_outline` y anillo de progreso en `primary`; desbloqueado: anillo
completo con `brandGradient`.

## Otros

- Notificaciones: `brandTeal` (`Color.rgb(2,125,146)`) en `RestNotifications.kt:40` en lugar de `rgb(0,109,126)`.
- Sin sombras nuevas ni degradados de fondo; el degradado solo en arcos, anillos y logo.
- Claro, oscuro y automático deben verse con estos valores (constitución VII).
