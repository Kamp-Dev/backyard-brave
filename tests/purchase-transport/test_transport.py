"""Loopback-only test of real adapter HTTP requests with fake receipts/store."""
import argparse, json, subprocess, tempfile, threading, shutil
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument("godot");parser.add_argument("adapter");parser.add_argument("evidence")
args=parser.parse_args()
calls=[]
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_POST(self):
        data=json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        calls.append((self.path,data))
        if self.path=="/redirect":
            self.send_response(307);self.send_header("Location",f"http://127.0.0.1:{self.server.server_port}/leak");self.end_headers();return
        body=b'{"payload":"fixture","signature":"fixture"}'
        self.send_response(200);self.send_header("Content-Length",str(len(body)));self.end_headers();self.wfile.write(body)
server=ThreadingHTTPServer(("127.0.0.1",0),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
    with tempfile.TemporaryDirectory() as name:
        root=Path(name)
        (root/"project.godot").write_text('[application]\nconfig/name="BackyardFamiliesFlowFixture"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir="'+(root/'userdata').as_posix()+'"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        script=Path(__file__).with_name("run.gd").read_text().replace("127.0.0.1:8787",f"127.0.0.1:{server.server_port}")
        (root/"run.gd").write_text(script)
        shutil.copy2(args.adapter,root/"adapter.gd")
        result=subprocess.run([args.godot,"--headless","--path",str(root),"--script","res://run.gd"],capture_output=True,text=True,timeout=45)
        print(result.stdout);print(result.stderr)
        assert result.returncode==0 and "PURCHASE TRANSPORT FIXTURES PASSED" in result.stdout
        assert "SCRIPT ERROR" not in result.stderr
        assert len(calls)==5 and not any(path=="/leak" for path,_ in calls)
        for path,data in calls:
            assert set(data)=={"receipts"}
            for receipt in data["receipts"]: assert set(receipt)=={"product_id","token"}
        assert calls[2][1]["receipts"]==[] and calls[3][1]["receipts"]==[]
        Path(args.evidence).write_text(json.dumps({"result":"passed","requests":len(calls),"redirect_followed":False,"outbound_fields":["product_id","token"],"pending_tokens_sent":False,"scope":"Synthetic loopback only; not Google Play or device certification."},indent=2))
finally:
    server.shutdown();server.server_close()
