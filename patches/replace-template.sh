#!/bin/bash
# 替换 DERP Web UI 模板
# 用法: bash replace-template.sh <tailscale源码目录>

TARGET="${1:-build_src/tailscale}/cmd/derper/derper.go"

cat > /tmp/derper_template.go << 'GOEOF'
// homePageTemplate renders the home page using [templateData].
var homePageTemplate = template.Must(template.New("home").Parse(`<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>DERP</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:linear-gradient(135deg,#0f172a,#1e293b);color:#e2e8f0;min-height:100vh;display:flex;align-items:center;justify-content:center}
.card{max-width:440px;width:90%;padding:44px 36px;background:rgba(30,41,59,.85);border:1px solid rgba(148,163,184,.1);border-radius:14px;box-shadow:0 20px 40px rgba(0,0,0,.4)}
h1{font-size:28px;font-weight:700;color:#38bdf8;margin-bottom:6px}
.tag{display:inline-block;padding:3px 8px;background:rgba(56,189,248,.12);color:#38bdf8;border:1px solid rgba(56,189,248,.25);border-radius:5px;font-size:11px;font-weight:500;margin-bottom:20px}
p{color:#94a3b8;font-size:13px;line-height:1.7;margin-bottom:28px}
ul{list-style:none}
li{margin-bottom:10px}
a{color:#38bdf8;text-decoration:none;font-size:13px;display:flex;align-items:center;gap:7px;transition:color .2s}
a:hover{color:#7dd3fc}
a::before{content:"";width:5px;height:5px;background:#38bdf8;border-radius:50%}
.foot{margin-top:28px;padding-top:16px;border-top:1px solid rgba(148,163,184,.1);color:#64748b;font-size:11px}
.ok{color:#22c55e;font-weight:500}
.dbg a{color:#64748b;font-size:11px}
</style>
</head><body>
<div class="card">
<h1>DERP</h1>
<div class="tag">自用 · 不对外开放</div>
<p>为 Tailscale 客户端提供 STUN / ICE 协商与端到端加密流量中继。仅限授权设备。</p>
<ul>
<li><a href="https://tailscale.com/kb/1232/derp-servers">DERP 说明</a></li>
<li><a href="https://pkg.go.dev/tailscale.com/derp">Protocol & Go docs</a></li>
<li><a href="https://github.com/tailscale/tailscale/tree/main/cmd/derper#derp">部署指南</a></li>
</ul>
<div class="foot">
<p>状态: <span class="ok">运行中</span></p>
{{if .AllowDebug}}<p class="dbg"><a href="/debug/">调试 →</a></p>{{end}}
</div>
</div>
</body></html>`))
GOEOF

# 替换: 从 homePageTemplate 注释开始到下一个变量定义或函数定义
python3 << 'PYEOF'
import re

with open("$TARGET", "r") as f:
    content = f.read()

# 找到 homePageTemplate 块的起始和结束
start_marker = "// homePageTemplate renders the home page"
end_marker_next_var = re.search(r'\n// [A-Z]', content[content.index(start_marker)+10:])

if end_marker_next_var:
    end_pos = content.index(start_marker) + 10 + end_marker_next_var.start()
else:
    end_pos = len(content)

with open("/tmp/derper_template.go", "r") as f:
    new_template = f.read().strip()

new_content = content[:content.index(start_marker)] + new_template + "\n" + content[end_pos:]

with open("$TARGET", "w") as f:
    f.write(new_content)

print("OK: template replaced")
PYEOF
