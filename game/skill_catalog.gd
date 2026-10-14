extends RefCounted
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://character_skills.json"))
const ICONS = preload("res://assets/ui/character-skill-icons.png")
var icon_regions: Array[Rect2]=[]
func _init():
	# The painted rows are not perfectly uniform. Explicit source bounds prevent
	# a neighboring icon from entering a card when it crosses a nominal grid line.
	icon_regions.assign([
		Rect2(84,20,246,244),Rect2(386,18,235,246),Rect2(690,38,275,226),
		Rect2(72,264,246,240),Rect2(386,269,240,235),Rect2(704,272,253,232),
		Rect2(74,505,240,250),Rect2(396,518,220,237),Rect2(697,506,251,250),
		Rect2(76,761,240,235),Rect2(409,760,210,236),Rect2(731,762,206,234),
		Rect2(76,997,237,214),Rect2(358,997,292,235),Rect2(688,1002,287,240),
		Rect2(75,1219,246,270),Rect2(369,1255,269,234),Rect2(687,1256,289,234)])
func draw_icon(g,character:int,kind:int,rect:Rect2,tint:Color=Color.WHITE):
	var region=icon_regions[kind+(9 if character==0 else 0)]
	var size=region.size*minf(rect.size.x/region.size.x,rect.size.y/region.size.y)
	g.draw_texture_rect_region(ICONS,Rect2(rect.get_center()-size/2,size),region,tint)
const PAIRS = [[0,3],[1,4],[2,5],[6,7],[3,8]]
func kit(g) -> Dictionary: return data["Poppy" if g.run_character==1 else "Scout"]
func name_for(g,kind:int) -> String: return kit(g).skills[kind][0]
func tag(g,kind:int) -> String: return kit(g).skills[kind][1]
func description(g,kind:int) -> String: return kit(g).skills[kind][2+mini(2,g.upgrade_ranks[kind])]
func combo(g,index:int) -> bool:
	var p=PAIRS[index]
	# Scout's fifth pair is Snapline / Forager, rather than Dew Step / Roots.
	if g.run_character==0 and index==4: p=[2,8]
	return g.upgrade_ranks[p[0]]>=2 and g.upgrade_ranks[p[1]]>=2
func partners(g,kind:int) -> Array:
	var result=[]
	for c in kit(g).combos:
		if c[0]==kind: result.append(int(c[1]))
		if c[1]==kind: result.append(int(c[0]))
	return result
func combo_index(g,kind:int) -> int:
	var options=kit(g).combos
	for i in range(options.size()):
		var c=options[i]
		if kind!=int(c[0]) and kind!=int(c[1]): continue
		if combo(g,i): return i
	for i in range(options.size()):
		var c=options[i]
		if kind==int(c[0]) or kind==int(c[1]):
			var other=int(c[1] if kind==int(c[0]) else c[0])
			if g.upgrade_ranks[other]>0: return i
	for i in range(options.size()):
		if kind==int(options[i][0]) or kind==int(options[i][1]): return i
	return 0
func status(g,kind:int) -> String:
	var index=combo_index(g,kind)
	var c=kit(g).combos[index]
	if combo(g,index): return c[2]+" / ACTIVE"
	var other=int(c[1] if kind==int(c[0]) else c[0])
	return "%s R2 + this R2" % name_for(g,other)
func benefit(g,kind:int) -> String:
	var labels=["Watered seeds become petal turrets", "Bee links up to three marked bugs", "Return gust carries the slowing scent", "Catch petals; fire them on the next throw", "Watered roots spread a slowing barrier"] if g.run_character==1 else ["Ricochets link another marked bug", "Scatter bursts decoys into eight seeds", "Quickdraw turns a line into a seed sweep", "A block fires your readied Counterseed", "Foraging refreshes a line trigger once"]
	return labels[combo_index(g,kind)]
func offers(g) -> Array[int]:
	var eligible: Array[int]=[]
	var owned: Array[int]=[]
	var missing: Array[int]=[]
	for i in range(9):
		if not g.skill_available(i): continue
		eligible.append(i)
		if g.upgrade_ranks[i]>0: owned.append(i)
	for i in range(9):
		if g.upgrade_ranks[i]<=0: continue
		for partner in partners(g,i):
			if eligible.has(partner) and g.upgrade_ranks[partner]==0 and not missing.has(partner): missing.append(partner)
	var result: Array[int]=[]
	if not owned.is_empty(): result.append(owned[g.rng.randi_range(0,owned.size()-1)])
	if not missing.is_empty() and g.rng.randf()<0.75: result.append(missing[g.rng.randi_range(0,missing.size()-1)])
	if g.learned_skill_ranks()==0:
		var starters: Array[int]=[0,1,4]
		result.append(starters[g.rng.randi_range(0,2)])
	for chosen in result: eligible.erase(chosen)
	while result.size()<3 and not eligible.is_empty():
		var pick: int=g.rng.randi_range(0,eligible.size()-1)
		result.append(eligible[pick])
		eligible.remove_at(pick)
	return result
