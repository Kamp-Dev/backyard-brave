# Backyard Brave project rules

Follow ART_STYLE.md for all playable-character art and animation. The user explicitly requires Scout, Poppy and future characters to share Poppy's soft painted garden style and the common character_art.gd animation system. Do not introduce a separate rendering or animation style for a new character.

Keep character skill pools exclusive and compatibility requirements visible. Skill effects must remain bounded on mobile, pause with the simulation and avoid recursive damage chains. Run behavior checks and full-stage calibration for mechanical changes; inspect actual Godot renders for visual changes. Preserve saved progression and the established signing key when publishing.

Publish browser updates only during development. Android/APK builds are deferred until the user is ready to package the completed game. Preserve the existing signing identity and released APK.
