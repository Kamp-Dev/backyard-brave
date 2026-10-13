extends RefCounted

# Each stage owns a separately illustrated composition. No mirroring or recropping.
const NAMES = ["The First Clearing","Pebble Crossing","Clover Corner","Potting Patch","Daisy Patch","Quiet Clearing","Leafy Passage","Stone Gate","Fence Gap","Clover Circle","Pebble Terrace","Twin Boulders","Broken Rim","Pebble Slope","Garden Steps","Split Stones","Pot and Pebbles","Stone Shelf","Pebble Bend","Pebble Court","Root Clearing","Daisy Meadow","Fallen Branch","Sunny Patch","Root Arch","Old Pot Garden","Fence Meadow","Stump Hollow","Garden Fork","Grand Clearing"]
const RECT = Rect2(94,410,532,532)
var texture: Texture2D
var loaded_stage = 0

func image_for(stage: int) -> Texture2D:
	if loaded_stage != stage:
		var path = "res://assets/ui/stages/stage-%02d.png" % stage
		texture = load(path) as Texture2D
		loaded_stage = stage
	return texture
