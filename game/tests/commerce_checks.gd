extends SceneTree
var failures=0
func check(condition: bool, message: String) -> void:
 if not condition:
  failures+=1
  push_error(message)
func _initialize(): call_deferred("run")
func envelope(key: CryptoKey, products: Array, package: String = "com.xevapps.backyardbrave", expires: int = 0) -> Dictionary:
 var now=int(Time.get_unix_time_from_system())
 var payload=JSON.stringify({"package":package,"products":products,"issued_at":now,"expires_at":now+3600 if expires==0 else expires})
 return {"payload":payload,"signature":Marshalls.raw_to_base64(Crypto.new().sign(HashingContext.HASH_SHA256,payload.sha256_buffer(),key))}
func run():
 var game=load("res://main.tscn").instantiate()
 game.screenshot_mode=true
 root.add_child(game)
 game.set_process(false)
 var shop=game.commerce
 var product="com.xevapps.backyardbrave.raincoat"
 check(not shop.config.enabled,"Production billing must remain off before launch certification")
 shop.purchase(product)
 check(not shop.owns(product),"Unavailable purchase must not grant")
 check(not shop.accept_envelope({"payload":"{}","signature":"fake"},false),"Reject forged entitlement")
 var key=Crypto.new().generate_rsa(2048)
 shop.config=shop.config.duplicate(true)
 shop.config.public_key_pem=key.save_to_string(true)
 check(shop.accept_envelope(envelope(key,[product]),false),"Accept trusted signed entitlement")
 check(shop.owns(product),"Purchased outfit available")
 check(not shop.accept_envelope(envelope(key,[product],"other.app"),false),"Reject wrong package")
 check(not shop.accept_envelope(envelope(key,[product],"com.xevapps.backyardbrave",1),false),"Reject expired entitlement")
 check(not shop.accept_envelope(envelope(key,["power.cheat"]),false),"Reject unknown product")
 var altered=envelope(key,[product]); altered.payload=altered.payload.replace("raincoat","acorn")
 check(not shop.accept_envelope(altered,false),"Reject altered claim")
 check(shop.owns(product),"Invalid response preserves previous valid ownership")
 game.wardrobe.equipped[0]="raincoat"
 game.wardrobe.refresh()
 check(game.character_art[0].art.resource_path.ends_with("raincoat.png"),"Owned skin renders")
 check(shop.accept_envelope(envelope(key,[]),false),"Accept authoritative refund")
 check(not shop.owns(product),"Refund removes ownership")
 check(game.character_art[0].art.resource_path.ends_with("scout-storybook.png"),"Refund safely restores base outfit")
 var guardian=game.wardrobe.skin("guardian_scout")
 game.mastery.records={}
 check(not game.wardrobe.owned(guardian),"Mastery skin locked initially")
 game.mastery.records={"0":{"clears":[1,2,5],"bugs":750,"signature":150,"combos":[0,1,2],"chapter":true}}
 check(game.wardrobe.owned(guardian),"Mastery unlocks earned cosmetic")
 game.stage_records={}
 check(not game.lifetime.character_unlocked(1,game.stage_records,game.scout_experience.level),"Cosmetics never unlock Poppy")
 for entry in game.wardrobe.catalog.skins:
  var rig=game.wardrobe.rig(entry.id)
  check(rig.art.get_size()==Vector2(1254,1254),"Atlas dimensions: "+entry.id)
  check(rig.regions.size()==4,"All four animation frames: "+entry.id)
 var save=ConfigFile.new()
 game.wardrobe.write_config(save)
 check(save.get_value("wardrobe","0")=="raincoat","Keep outfit preference without forging ownership")
 check(not save.has_section("commerce"),"Progress file never grants store products")
 if failures==0: print("COMMERCE CHECKS PASSED")
 quit(1 if failures else 0)
