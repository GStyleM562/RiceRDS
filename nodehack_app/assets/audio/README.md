# assets/audio/

Suelta aquí los archivos de audio (`.mp3`). Si un archivo falta, el juego corre
igual (se ignora en silencio) hasta que aparezca. Los nombres deben coincidir
EXACTO con el catálogo de `lib/audio/audio_service.dart`.

## Música (lo de ahora) — 2 pistas, en loop
- `music_menu.mp3`   → suena en el menú y fuera de partida.
- `music_combat.mp3` → suena durante la partida (CPU y online).

## SFX (para después — la estructura ya está lista)
Convención `sfx_<categoria>_<nombre>.mp3`. Ya cableados: `sfx_card_place.mp3`,
`sfx_compile.mp3`. El resto queda definido en el enum `Sfx` para ir agregándolos:

- `sfx_ui_tap.mp3`, `sfx_card_pick.mp3`, `sfx_card_place.mp3`, `sfx_card_return.mp3`, `sfx_compile.mp3`
- Revelado (cuando el revelado sea ordenado/audible):
  `sfx_reveal_firewall.mp3`, `sfx_reveal_exploit.mp3`, `sfx_reveal_signal.mp3`, `sfx_reveal_null.mp3`
- Resolución: `sfx_damage_dealt.mp3`, `sfx_damage_taken.mp3`, `sfx_blocked.mp3`, `sfx_acquire.mp3`
- Cierre: `sfx_round_win.mp3`, `sfx_round_lose.mp3`, `sfx_round_draw.mp3`, `sfx_match_win.mp3`, `sfx_match_lose.mp3`

> Para agregar un SFX nuevo: añade el slot al enum `Sfx` (con su nombre de archivo)
> y llama `AudioService.instance.playSfx(Sfx.tuSlot)` donde corresponda.
