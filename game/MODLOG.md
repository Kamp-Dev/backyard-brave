# Poppy asset integration

Existing scout-draw PNG uses an alpha 4x2 directional atlas; the draw code trims each cell and fixes the feet at player +16, drawing 56-pixel-tall figures with brown contours and painted colors. Existing scout-release uses the same format. Poppy uses a 1280x1280 RGBA PNG, four 640x640 cells in a 2x2 layout: front ready, front step/release, rear ready, rear step/release. Each cell is trimmed at load. Mirroring covers left-facing directions. Soft alpha and generated mipmaps preserve small-screen edges. No source image editing or recoloring is performed.

Generated with built-in imagegen from the approved left-hand Poppy concept. Prompt: game sprite sheet derived only from Poppy the gardener; transparent background; exactly two columns and two rows, four full-body sprites, same scale, centered; auburn short braids, floppy straw hat with green ribbon, sage overalls, ivory shirt, terracotta boots, canvas seed pouch; clean brown outlines and simplified matte painted detail; three-quarter front/right ready with wooden crescent boomerang, front/right walking with open throwing hand, rear/right ready, rear/right walking with open throwing hand; no labels, shadows, other characters or background. Feet share a baseline within each cell.

Real Godot captures of selection and combat inspected. Mipmaps enabled after the initial render showed aliasing. Poppy balance and behavior tests live in tests/poppy_checks.gd and tests/poppy_balance.gd.


Poppy walking correction / v0.9.1-test, Android code 21
Walk no longer swaps between standing and throwing full-body poses. Existing art is rendered as two six-vertex leg strips and a separate torso, with a stable scale and hip/foot reference. Alternating knee/boot movement follows actual travel distance; idle or blocked movement plants both feet. Retreat reverses the stride. Attack release changes only the upper-body region. Three small textured draws; no new textures, particles, or simulation work. Front/rear ready/throw render inspected. Regression tests cover attack independence, opposite steps, backpedaling, and blocked movement. Skill-pool redesign remains a proposal in this release.
