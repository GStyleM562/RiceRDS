# assets/audio/

Suelta aquí los archivos `.mp3` con el **nombre EXACTO** de abajo. Si un archivo
falta, el juego corre igual (se ignora en silencio) hasta que aparezca. El catálogo
canónico vive en `lib/audio/audio_service.dart` (enums `Music` y `Sfx`).

> En el **apk debug**, el menú tiene un enlace **«▤ RUTAS (debug)»** que lista
> todas estas rutas dentro de la app (no aparece en producción).

## Música (loops)
| Archivo | Cuándo suena |
|---|---|
| `music_menu.mp3` | Menú, intro, reglas, núcleo, mazos (lista). |
| `music_deckbuild.mp3` | Armando mazo (constructor). |
| `music_combat.mp3` | Combate normal (CPU, online y tutoriales). |
| `music_combat_danger.mp3` | Combate con **1-2 de integridad** (peligro). Vuelve a la normal si te curas. |
| `music_victory.mp3` | Pantalla de victoria. |
| `music_defeat.mp3` | Pantalla de derrota. |

## SFX — EN USO (ya cableados)
| Archivo | Cuándo suena |
|---|---|
| `sfx_ui_tap.mp3` | Presionar un botón del menú. |
| `sfx_card_zoom.mp3` | Abrir una carta en zoom (clic). |
| `sfx_card_pick.mp3` | Empezar a arrastrar una carta. |
| `sfx_card_place.mp3` | Soltar la carta en el campo. |
| `sfx_compile.mp3` | COMPILAR. |
| `sfx_exec_focus.mp3` | Highlight de una **Subrutina** en EJECUCIÓN (tick sutil). |
| `sfx_reveal_firewall.mp3` | Highlight de una Rutina **CORTAFUEGOS** (cian) en EJECUCIÓN. |
| `sfx_reveal_exploit.mp3` | Highlight de una Rutina **EXPLOIT** (rojo) en EJECUCIÓN. |
| `sfx_reveal_signal.mp3` | Highlight de una Rutina **PULSO** (verde) en EJECUCIÓN. |
| `sfx_reveal_null.mp3` | Highlight de una Rutina **NULL** (púrpura) en EJECUCIÓN. |
| `sfx_damage_dealt.mp3` | Rayo + impacto: el **rival** recibe daño. |
| `sfx_damage_taken.mp3` | Rayo + impacto: **tú** recibes daño (distorsión). |
| `sfx_low_warning.mp3` | Aviso, **1 sola vez por partida**, al caer a **1** de integridad. |
| `sfx_enemy_lose_static.mp3` | Estática lejana: el enemigo pierde (se desconecta). |
| `sfx_player_lose_static.mp3` | Estática/distorsión fuerte: **tú** pierdes. |

## SFX — OPCIONALES / FUTUROS (definidos, sin cablear aún)
`sfx_card_return.mp3` (devolver carta), `sfx_acquire.mp3` (robar), `sfx_blocked.mp3` (BLINDAJE).

> Para cablear uno nuevo: añade el slot al enum `Sfx` y llama
> `AudioService.instance.playSfx(Sfx.tuSlot)` donde corresponda.
