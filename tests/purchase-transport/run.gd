extends SceneTree
class FakeStore extends Node:
 var products={"com.kampdev.backyardbrave.raincoat":{}}
 var config={"verification_url":"http://127.0.0.1:8787/verify"}
 var notice=""
 var busy=false
 var accepted=0
 func fail(message): busy=false; notice=message
 func accept_envelope(_envelope): accepted+=1; busy=false; return true
var store: FakeStore
var adapter: Node
func _initialize(): call_deferred("run")
func response(state=1):
 return {"response_code":0,"purchases":[{"purchase_state":state,"product_ids":["com.kampdev.backyardbrave.raincoat"],"purchase_token":"fixture-token","account_email":"must-not-send","order_id":"must-not-send"}]}
func wait_done():
 for i in range(500):
  await create_timer(0.01).timeout
  if not adapter.verifying: return
 assert(false,"HTTP request stuck")
func run():
 store=FakeStore.new();root.add_child(store)
 adapter=load("res://adapter.gd").new();root.add_child(adapter)
 adapter.store=store;adapter.create_verification_request()
 assert(adapter.request.max_redirects==0)
 adapter._purchases(response(),true)
 await wait_done()
 assert(store.accepted==1)
 assert(adapter.receipts.size()==1)
 adapter._purchases(response(),false)
 await wait_done()
 assert(adapter.receipts.size()==1)
 adapter._purchases(response(2),true)
 await wait_done()
 assert(adapter.receipts.is_empty() and adapter.payment_pending)
 adapter._purchases({"response_code":0,"purchases":[]},true)
 await wait_done()
 var accepted=store.accepted
 store.config.verification_url="http://127.0.0.1:8787/redirect"
 adapter._purchases(response(),true)
 await wait_done()
 assert(store.accepted==accepted,"Redirect must not grant")
 adapter._purchases({"response_code":2},true)
 assert(adapter.receipts.size()==1,"Failed query must preserve receipts")
 adapter.verify_again=true
 adapter._verified(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),JSON.stringify({"payload":"stale","signature":"fixture"}).to_utf8_buffer())
 assert(store.accepted==accepted,"Ignore in-flight superseded snapshot")
 print("PURCHASE TRANSPORT FIXTURES PASSED")
 quit()
