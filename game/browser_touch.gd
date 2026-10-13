extends RefCounted
## Read browser touch coordinates directly, independently of engine touch delivery.
var enabled = false
var delivering = false

func setup() -> void:
	if not OS.has_feature("web"): return
	JavaScriptBridge.eval("""
(() => {
 const canvas = document.getElementById('canvas');
 if (!canvas) return;
 window.backyardTouchQueue = [];
 window.backyardTouchUntil = 0;
 const fingers = new Map();
 let nextFinger = 0;
 const record = (event, kind) => {
  const rect = canvas.getBoundingClientRect();
  if (!rect.width || !rect.height) return;
  for (const touch of event.changedTouches) {
   if (kind === "down") fingers.set(touch.identifier, nextFinger++);
   if (!fingers.has(touch.identifier)) continue;
   window.backyardTouchQueue.push([kind, fingers.get(touch.identifier),
    (touch.clientX-rect.left)/rect.width, (touch.clientY-rect.top)/rect.height]);
   if (kind === "up") fingers.delete(touch.identifier);
  }
  window.backyardTouchUntil = performance.now()+800;
  if (event.cancelable) event.preventDefault();
 };
 canvas.style.touchAction = 'none';
 canvas.addEventListener('touchstart', e => record(e, 'down'), {passive:false});
 canvas.addEventListener('touchmove', e => record(e, 'move'), {passive:false});
 canvas.addEventListener('touchend', e => record(e, 'up'), {passive:false});
 canvas.addEventListener('touchcancel', e => record(e, 'up'), {passive:false});
 window.addEventListener('blur', () => { fingers.clear(); window.backyardTouchQueue.push(['cancel',0,0,0]); });
 window.backyardReadTouches = () => JSON.stringify(window.backyardTouchQueue.splice(0));
})();
""", true)
	enabled = true

func drain(host: Node2D) -> void:
	if not enabled: return
	var rows = JSON.parse_string(JavaScriptBridge.eval("window.backyardReadTouches()", true))
	if not rows is Array: return
	delivering = true
	for row in rows:
		if row[0] == "cancel":
			host.clear_touch()
			continue
		var event: InputEvent
		if row[0] == "move":
			event = InputEventScreenDrag.new()
		else:
			event = InputEventScreenTouch.new()
			event.pressed = row[0] == "down"
		event.index = int(row[1])
		event.position = Vector2(float(row[2]),float(row[3])) * host.get_viewport_rect().size
		host._unhandled_input(event)
	delivering = false

func suppress(event: InputEvent) -> bool:
	if not enabled or delivering: return false
	if event is InputEventScreenTouch or event is InputEventScreenDrag: return true
	if event is InputEventMouse:
		return bool(JavaScriptBridge.eval("performance.now() < window.backyardTouchUntil", true))
	return false
