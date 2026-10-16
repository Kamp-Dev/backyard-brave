extends Node
## Real purchases require native billing, an HTTPS verifier, and signed entitlements.
## No development grants or simulated payment buttons exist in player builds.
const CONFIG = preload("res://commerce_config.json")
const CATALOG = preload("res://cosmetic_catalog.json")
const CACHE = "user://store-entitlements.json"
var config: Dictionary = CONFIG.data
var products: Dictionary = {}
var owned_products: Array = []
var prices: Dictionary = {}
var notice = "Preview outfits now. Shop opens at launch."
var busy = false
var host: Node2D
var provider: Node
var expires_at = 0

func setup(game: Node2D) -> void:
 host=game
 for product in CATALOG.data.products: products[product.id]=product
 if FileAccess.file_exists(CACHE):
  var cached=JSON.parse_string(FileAccess.get_file_as_string(CACHE))
  if cached is Dictionary: accept_envelope(cached,false)
 if not config.enabled or not OS.has_feature("android"): return
 if not config.verification_url.begins_with("https://") or config.public_key_pem.is_empty():
  notice="Shop unavailable. Your game is ready to play."
  return
 provider=load("res://google_play_store.gd").new()
 add_child(provider)
 provider.setup(self)

func owns(product: String) -> bool:
 return owned_products.has(product) and Time.get_unix_time_from_system()<expires_at

func can_purchase(product: String) -> bool:
 return provider!=null and not busy and prices.has(product) and not owns(product)

func price_label(product: String) -> String:
 if busy: return "CHECKING STORE..."
 if prices.has(product): return "BUY / "+str(prices[product])
 return "PREVIEW / NOT ON SALE"

func purchase(product: String) -> void:
 if not can_purchase(product):
  notice="Already owned." if owns(product) else "Purchases are not available in this build."
  return
 busy=true
 notice="Complete your purchase in Google Play."
 provider.purchase(product)

func restore() -> void:
 if busy: return
 if provider==null:
  notice="Restore is available in the Google Play release."
  return
 busy=true
 notice="Checking your Google Play purchases..."
 provider.restore()

func fail(message: String) -> void:
 busy=false
 notice=message

func accept_envelope(envelope: Dictionary, persist: bool = true) -> bool:
 if not envelope.get("payload") is String or not envelope.get("signature") is String: return false
 if config.public_key_pem.is_empty(): return false
 var key=CryptoKey.new()
 if key.load_from_string(config.public_key_pem,true)!=OK: return false
 var payload: String=envelope.payload
 var signature=Marshalls.base64_to_raw(envelope.signature)
 if not Crypto.new().verify(HashingContext.HASH_SHA256,payload.sha256_buffer(),signature,key): return false
 var claims=JSON.parse_string(payload)
 if not claims is Dictionary or claims.get("package")!=config.package: return false
 var now=int(Time.get_unix_time_from_system())
 if not claims.get("products") is Array or int(claims.get("expires_at",0))<=now: return false
 if int(claims.get("issued_at",0))>now+300: return false
 if int(claims.expires_at)-int(claims.get("issued_at",0))>90*24*3600: return false
 var accepted: Array=[]
 for id in claims.products:
  if not id is String or not products.has(id): return false
  if not accepted.has(id): accepted.append(id)
 if persist:
  var file=FileAccess.open(CACHE+".tmp",FileAccess.WRITE)
  if file==null: return false
  file.store_string(JSON.stringify(envelope))
  file.flush()
  var error=file.get_error()
  file.close()
  if error!=OK or DirAccess.rename_absolute(CACHE+".tmp",CACHE)!=OK: return false
 owned_products=accepted
 expires_at=int(claims.expires_at)
 busy=false
 notice="Purchases restored." if not accepted.is_empty() else "No active purchases found."
 if host!=null and host.wardrobe.host!=null: host.wardrobe.refresh()
 return true

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_IN and provider!=null and not busy:
  restore()
