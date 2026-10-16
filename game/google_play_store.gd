extends Node
## Adapter for the official GodotGooglePlayBilling plugin. Web never loads it.
## Tokens go only to the configured verifier, never into logs or analytics.
var store: Node
var billing: Object
var request: HTTPRequest
var receipts: Array = []
var options: Dictionary = {}
var verifying=false
var verify_again=false
var payment_pending=false
const RECEIPTS = "user://store-receipts.json"

func setup(owner_store: Node) -> void:
 store=owner_store
 if not Engine.has_singleton("GodotGooglePlayBilling"):
  store.fail("Google Play billing is unavailable on this device.")
  return
 billing=Engine.get_singleton("GodotGooglePlayBilling")
 billing.initPlugin()
 billing.connect("connected",_connected)
 billing.connect("disconnected",func(): store.fail("Store disconnected. Please try Restore."))
 billing.connect("connect_error",func(_code,_message): store.fail("Cannot connect to Google Play."))
 billing.connect("query_product_details_response",_products)
 billing.connect("query_purchases_response",func(result): _purchases(result,true))
 billing.connect("on_purchase_updated",_updated)
 request=HTTPRequest.new()
 request.timeout=20
 request.body_size_limit=65536
 request.max_redirects=0 # A receipt must never follow a redirect to another host.
 add_child(request)
 request.request_completed.connect(_verified)
 if FileAccess.file_exists(RECEIPTS):
  var saved=JSON.parse_string(FileAccess.get_file_as_string(RECEIPTS))
  if saved is Array: receipts=saved
 billing.startConnection()

func _connected() -> void:
 billing.queryProductDetails(PackedStringArray(store.products.keys()),"inapp")
 restore()

func _products(result: Dictionary) -> void:
 if int(result.get("response_code",-1))!=0: return
 store.prices.clear()
 for product in result.get("product_details",[]):
  var id=str(product.get("product_id",""))
  var offers=product.get("one_time_purchase_offer_details_list",[])
  if not offers is Array: continue
  for offer in offers:
   # Launch products use a permanent 'buy' option, never rental offers.
   if not offer is Dictionary or offer.get("purchase_option_id")!="buy" or offer.get("offer_id")!=null: continue
   if not store.products.has(id): continue
   var price=str(offer.get("formatted_price",""))
   if not price.is_empty():
    store.prices[id]=price
    options[id]="buy"

func purchase(product: String) -> void:
 if billing==null or not billing.isReady():
  store.fail("Store unavailable. Please try again.")
  return
 var result=billing.purchase(product,options.get(product,"buy"),"",false)
 if int(result.get("response_code",-1))!=0: store.fail("Purchase did not start. You were not charged here.")

func restore() -> void:
 if billing==null or not billing.isReady():
  store.fail("Connect to Google Play to restore purchases.")
  return
 billing.queryPurchases("inapp",false)

func _updated(result: Dictionary) -> void:
 var code=int(result.get("response_code",-1))
 if code==1:
  store.fail("Purchase canceled. Nothing changed.")
  return
 if code!=0:
  store.fail("Purchase could not complete. Try Restore.")
  return
 _purchases(result)

func _purchases(result: Dictionary, complete_snapshot: bool = false) -> void:
 if int(result.get("response_code",-1))!=0:
  store.fail("Could not check purchases. Your saved outfits are unchanged.")
  return
 if complete_snapshot: receipts=[]
 var pending=false
 for purchase in result.get("purchases",[]):
  if int(purchase.get("purchase_state",0))==2:
   pending=true
   continue
  if int(purchase.get("purchase_state",0))!=1: continue
  for product in purchase.get("product_ids",[]):
   if not store.products.has(product): continue
   var row={"product_id":product,"token":str(purchase.get("purchase_token",""))}
   if not row.token.is_empty():
    receipts=receipts.filter(func(old): return old.get("product_id")!=product)
    receipts.append(row)
 # A successful full Play query replaces ownership for the current account.
 # Incremental purchase callbacks merge; failed queries never clear receipts.
 var file=FileAccess.open(RECEIPTS+".tmp",FileAccess.WRITE)
 if file==null:
  store.fail("Could not save purchase receipt. Please try Restore.")
  return
 file.store_string(JSON.stringify(receipts))
 file.flush()
 var saved=file.get_error()==OK
 file.close()
 if not saved or DirAccess.rename_absolute(RECEIPTS+".tmp",RECEIPTS)!=OK:
  store.fail("Could not save receipt. Please try Restore.")
  return
 payment_pending=pending
 store.notice="Payment pending in Google Play." if pending else "Verifying your purchases..."
 store.busy=true
 if verifying:
  verify_again=true
  return
 verifying=true
 var error=request.request(store.config.verification_url,["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify({"receipts":receipts}))
 if error!=OK:
  verifying=false
  store.fail("Verification unavailable. Please try Restore.")

func _verified(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
 verifying=false
 if verify_again:
  verify_again=false
  restore.call_deferred()
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
  store.fail("Verification unavailable. Your outfits are unchanged; try Restore.")
  return
 var envelope=JSON.parse_string(body.get_string_from_utf8())
 if not envelope is Dictionary or not store.accept_envelope(envelope):
  store.fail("Could not verify or save purchases. Please try Restore.")
 elif payment_pending:
  store.notice="Payment pending in Google Play. No outfit granted yet."

func _exit_tree() -> void:
 if billing!=null: billing.endConnection()
