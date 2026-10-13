extends RefCounted
const CUES = {
 "seed-release":preload("res://assets/audio/seed-release.wav"),
 "shell-hit":preload("res://assets/audio/shell-hit.wav"),
 "soft-hit":preload("res://assets/audio/soft-hit.wav"),
 "bug-defeat":preload("res://assets/audio/bug-defeat.wav"),
 "roll-rustle":preload("res://assets/audio/roll-rustle.wav"),
 "scout-hurt":preload("res://assets/audio/scout-hurt.wav"),
 "bug-spit":preload("res://assets/audio/bug-spit.wav"),
 "charge-warning":preload("res://assets/audio/charge-warning.wav"),
 "seed-pickup":preload("res://assets/audio/seed-pickup.wav"),
 "berry-heal":preload("res://assets/audio/berry-heal.wav"),
 "guard-block":preload("res://assets/audio/guard-block.wav"),
 "upgrade":preload("res://assets/audio/upgrade.wav"),
 "boss-arrival":preload("res://assets/audio/boss-arrival.wav"),
}
var played: Dictionary = {}
var variation=0
func play(host: Node2D, name: String) -> void:
 if host.mute or "--smoke-test" in OS.get_cmdline_user_args() or "--balance-test" in OS.get_cmdline_user_args(): return
 var now=Time.get_ticks_msec()
 var gap=220 if name=="seed-release" else 65
 if now-int(played.get(name,-1000))<gap: return
 played[name]=now
 var voice=host.audio_players[host.audio_cursor%host.audio_players.size()]
 host.audio_cursor+=1
 voice.stop()
 voice.stream=CUES[name]
 voice.volume_db=-15 if name in ["seed-release","seed-pickup","soft-hit","shell-hit","bug-defeat"] else -10
 if name=="seed-release": voice.volume_db=-25
 voice.pitch_scale=1.0+([-0.025,0.0,0.025][variation%3] if name in ["seed-release","soft-hit","shell-hit","bug-defeat"] else 0.0)
 variation+=1
 voice.play()
