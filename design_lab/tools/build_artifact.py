#!/usr/bin/env python3
# Builds a self-contained comparison lookbook for the 10 Memory Pager designs.
# Reads the workflow report JSON + the 30 phone screenshots, embeds images as
# data URIs, and writes a single HTML file for the Artifact tool.

import json, base64, io, os, html
from PIL import Image

BASE = "/private/tmp/claude-501/-Users-siheom-yong-programming-ssome2/56afd6da-a746-4c81-a0ae-6123d66da686"
REPORT = f"{BASE}/tasks/w1g0tj5wk.output"
SHOTS = f"{BASE}/scratchpad/shots"
OUT = f"{BASE}/scratchpad/memory_pager_designs.html"

SCREENS = [("drawSend", "Draw & Send"), ("petHome", "Pet Home"), ("memoryAlbum", "Album")]

META = {
 '01': dict(acc='#45E06B', fam='Brutalist Terminal', cost='Low',       bright='dark'),
 '02': dict(acc='#E6A9C6', fam='Glassmorphism',       cost='High',      bright='light'),
 '03': dict(acc='#FF5A7A', fam='3D Claymorphism',     cost='Very High', bright='light'),
 '04': dict(acc='#FF48B0', fam='Risograph Print',     cost='Low',       bright='light'),
 '05': dict(acc='#C98B84', fam='Paper Collage',       cost='High',      bright='light'),
 '06': dict(acc='#F1948A', fam='Craft / Felt',        cost='High',      bright='light'),
 '07': dict(acc='#B98A6E', fam='Calm Minimal',        cost='Low',       bright='light'),
 '08': dict(acc='#E1A23E', fam='Bento Grid',          cost='Medium',    bright='light'),
 '09': dict(acc='#CE7B3A', fam='Skeuomorphic',        cost='High',      bright='dark'),
 '10': dict(acc='#E5473C', fam='Cinematic Film',      cost='Medium',    bright='dark'),
}
STANDOUTS = {'07', '05', '10'}

def img_data_uri(path, width=440, q=82):
    im = Image.open(path).convert("RGB")
    if im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    buf = io.BytesIO(); im.save(buf, "JPEG", quality=q, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()

def load():
    data = json.load(open(REPORT))
    res = data["result"]
    specs = {s["nn"]: s for s in res["specs"]}
    rep = {d["nn"]: d for d in res["report"]["designs"]}
    return specs, rep, res["report"]["recommendation"]

def esc(s): return html.escape(str(s or ""))

def main():
    specs, rep, recommendation = load()
    cards = []
    for nn in [f"{i:02d}" for i in range(1, 11)]:
        d = rep.get(nn, {}); s = specs.get(nn, {}); m = META[nn]
        name = d.get("name") or s.get("name") or nn
        concept = d.get("concept") or s.get("concept") or ""
        signature = d.get("signature") or s.get("signature") or ""
        pros = d.get("pros", []); cons = d.get("cons", []); best = d.get("bestFor", "")
        shots = ""
        for key, lbl in SCREENS:
            p = f"{SHOTS}/d{nn}_{key}.png"
            if os.path.exists(p) and os.path.getsize(p) > 1000:
                uri = img_data_uri(p)
                shots += (f'<figure class="shot" data-screen="{key}">'
                          f'<img loading="lazy" src="{uri}" alt="{esc(name)} — {lbl}" '
                          f'onclick="zoom(this)"><figcaption>{lbl}</figcaption></figure>')
            else:
                shots += (f'<figure class="shot miss" data-screen="{key}">'
                          f'<div class="ph">no render</div><figcaption>{lbl}</figcaption></figure>')
        pros_h = "".join(f"<li>{esc(x)}</li>" for x in pros)
        cons_h = "".join(f"<li>{esc(x)}</li>" for x in cons)
        star = '<span class="star" title="추천 후보">추천</span>' if nn in STANDOUTS else ""
        bright_ic = "☾" if m["bright"] == "dark" else "☀"
        cards.append(f"""
      <article class="card{' pick' if nn in STANDOUTS else ''}" style="--acc:{m['acc']}">
        <header class="c-head">
          <span class="idx">{nn}</span>
          <div class="c-title">
            <h2>{esc(name)}{star}</h2>
            <div class="tags">
              <span class="tag fam">{esc(m['fam'])}</span>
              <span class="tag">{bright_ic} {m['bright']}</span>
              <span class="tag cost cost-{m['cost'].split()[0].lower()}">빌드 {esc(m['cost'])}</span>
            </div>
          </div>
        </header>
        <p class="concept">{esc(concept)}</p>
        <p class="sig"><span>✦</span> {esc(signature)}</p>
        <div class="shots">{shots}</div>
        <div class="pc">
          <ul class="pros">{pros_h}</ul>
          <ul class="cons">{cons_h}</ul>
        </div>
        <p class="best"><b>적합</b> {esc(best)}</p>
      </article>""")

    cards_html = "\n".join(cards)
    doc = TEMPLATE.replace("__CARDS__", cards_html).replace("__RECO__", esc(recommendation))
    open(OUT, "w").write(doc)
    print("wrote", OUT, f"({os.path.getsize(OUT)//1024} KB)")

TEMPLATE = r"""<title>Memory Pager · 10 Design Directions</title>
<style>
  * { box-sizing: border-box; }
  :root{
    --bg:#ECEAE4; --surface:#F6F4EF; --ink:#211E19; --muted:#77726A; --line:#DAD6CD;
    --shadow:rgba(33,30,25,.10); --screenbg:#14151A;
    --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;
    --sans:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;
    --maxw:1180px;
  }
  @media (prefers-color-scheme:dark){:root{
    --bg:#131210; --surface:#1B1A17; --ink:#ECE9E3; --muted:#948E83; --line:#302E29; --shadow:rgba(0,0,0,.5);}}
  :root[data-theme="light"]{--bg:#ECEAE4;--surface:#F6F4EF;--ink:#211E19;--muted:#77726A;--line:#DAD6CD;--shadow:rgba(33,30,25,.10);}
  :root[data-theme="dark"]{--bg:#131210;--surface:#1B1A17;--ink:#ECE9E3;--muted:#948E83;--line:#302E29;--shadow:rgba(0,0,0,.5);}
  html{ -webkit-text-size-adjust:100%; }
  body{ margin:0; background:var(--bg); color:var(--ink); font-family:var(--sans);
        line-height:1.5; -webkit-font-smoothing:antialiased; }
  .wrap{ max-width:var(--maxw); margin:0 auto; padding:clamp(20px,4vw,52px) clamp(16px,4vw,40px) 80px; }
  a{ color:inherit; }

  /* header */
  .eyebrow{ font-family:var(--mono); font-size:12px; letter-spacing:.22em; text-transform:uppercase;
            color:var(--muted); display:flex; align-items:center; gap:10px; }
  .eyebrow::before{ content:""; width:26px; height:2px; background:currentColor; display:inline-block; }
  h1{ font-size:clamp(30px,5.4vw,54px); line-height:1.03; margin:.36em 0 .18em; letter-spacing:-.02em;
      font-weight:800; text-wrap:balance; max-width:16ch; }
  .lede{ color:var(--muted); font-size:clamp(15px,1.6vw,18px); max-width:60ch; margin:0; }
  .meta-row{ display:flex; flex-wrap:wrap; gap:8px 18px; margin-top:18px; font-family:var(--mono);
             font-size:12px; color:var(--muted); }
  .meta-row b{ color:var(--ink); font-weight:600; }

  header.top{ display:flex; justify-content:space-between; align-items:flex-start; gap:20px; }
  .toggle{ font-family:var(--mono); font-size:12px; letter-spacing:.08em; border:1px solid var(--line);
           background:var(--surface); color:var(--ink); padding:8px 12px; border-radius:999px; cursor:pointer;
           white-space:nowrap; }
  .toggle:focus-visible{ outline:2px solid var(--ink); outline-offset:2px; }

  /* recommendation */
  .reco{ margin:34px 0 8px; background:var(--surface); border:1px solid var(--line);
         border-left:3px solid var(--ink); border-radius:14px; padding:20px 22px; box-shadow:0 1px 0 var(--shadow); }
  .reco h3{ margin:0 0 8px; font-size:12px; font-family:var(--mono); letter-spacing:.16em; text-transform:uppercase; color:var(--muted); }
  .reco p{ margin:0; font-size:15.5px; }
  .picks{ display:flex; flex-wrap:wrap; gap:8px; margin-top:14px; }
  .pick-chip{ font-family:var(--mono); font-size:12px; padding:5px 10px; border-radius:999px;
              border:1px solid var(--line); background:var(--bg); }
  .pick-chip b{ color:var(--ink); }

  /* filter */
  .filter{ position:sticky; top:0; z-index:5; display:flex; gap:6px; flex-wrap:wrap; align-items:center;
           padding:14px 0 12px; margin-top:26px; background:linear-gradient(var(--bg),var(--bg) 70%,transparent);
           backdrop-filter:blur(2px); }
  .filter .lbl{ font-family:var(--mono); font-size:11px; letter-spacing:.14em; text-transform:uppercase; color:var(--muted); margin-right:6px; }
  .fbtn{ font-family:var(--mono); font-size:12.5px; padding:7px 13px; border-radius:999px; cursor:pointer;
         border:1px solid var(--line); background:var(--surface); color:var(--muted); }
  .fbtn[aria-pressed="true"]{ color:var(--bg); background:var(--ink); border-color:var(--ink); }
  .fbtn:focus-visible{ outline:2px solid var(--ink); outline-offset:2px; }

  /* grid */
  .grid{ display:grid; grid-template-columns:1fr; gap:20px; margin-top:8px; }
  @media (min-width:820px){ .grid{ grid-template-columns:1fr 1fr; } }

  .card{ background:var(--surface); border:1px solid var(--line); border-radius:16px; overflow:clip;
         padding:20px 20px 18px; display:flex; flex-direction:column; gap:12px; box-shadow:0 1px 2px var(--shadow); }
  .card.pick{ border-color:color-mix(in srgb, var(--acc) 55%, var(--line)); }
  .c-head{ display:flex; gap:14px; align-items:flex-start; }
  .idx{ font-family:var(--mono); font-weight:700; font-size:15px; letter-spacing:.02em;
        color:#0d0d0d; background:var(--acc); border-radius:8px; padding:6px 9px; line-height:1;
        box-shadow:inset 0 0 0 1px rgba(0,0,0,.08); }
  .c-title{ flex:1; min-width:0; }
  .c-title h2{ margin:0; font-size:20px; font-weight:800; letter-spacing:-.01em; line-height:1.12; display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
  .star{ font-family:var(--mono); font-size:10.5px; letter-spacing:.1em; color:#0d0d0d; background:var(--acc);
         padding:3px 7px; border-radius:999px; text-transform:uppercase; }
  .tags{ display:flex; flex-wrap:wrap; gap:6px; margin-top:8px; }
  .tag{ font-family:var(--mono); font-size:11px; color:var(--muted); border:1px solid var(--line);
        padding:3px 8px; border-radius:6px; letter-spacing:.02em; }
  .tag.fam{ color:var(--ink); border-color:color-mix(in srgb,var(--acc) 45%,var(--line)); }
  .cost-low{ color:#2f7d54; } .cost-medium{ color:#9a7b1f; } .cost-high{ color:#a8542f; } .cost-very{ color:#a33; }
  @media (prefers-color-scheme:dark){ .cost-low{color:#78d69c;} .cost-medium{color:#d9be6a;} .cost-high{color:#e69a76;} .cost-very{color:#e78} }
  :root[data-theme="dark"] .cost-low{color:#78d69c;} :root[data-theme="dark"] .cost-medium{color:#d9be6a;} :root[data-theme="dark"] .cost-high{color:#e69a76;} :root[data-theme="dark"] .cost-very{color:#e78;}

  .concept{ margin:0; font-size:14.5px; color:var(--ink); }
  .sig{ margin:0; font-size:13.5px; color:var(--muted); display:flex; gap:8px; }
  .sig span{ color:var(--acc); }

  .shots{ display:flex; gap:8px; background:var(--screenbg); border-radius:12px; padding:12px; }
  .shot{ margin:0; flex:1; display:flex; flex-direction:column; align-items:center; gap:6px; min-width:0; }
  .shot img{ width:100%; height:auto; border-radius:9px; display:block; cursor:zoom-in;
             box-shadow:0 6px 16px rgba(0,0,0,.4); }
  .shot figcaption{ font-family:var(--mono); font-size:10px; letter-spacing:.06em; color:#9a9a9a; text-transform:uppercase; }
  .shot.miss .ph{ width:100%; aspect-ratio:428/926; border-radius:9px; background:#222; color:#777;
                  display:grid; place-items:center; font-family:var(--mono); font-size:11px; }

  .pc{ display:grid; grid-template-columns:1fr 1fr; gap:6px 18px; }
  .pc ul{ margin:0; padding:0; list-style:none; font-size:13px; }
  .pc li{ position:relative; padding-left:18px; margin:5px 0; color:var(--ink); }
  .pros li::before{ content:"✓"; position:absolute; left:0; color:#3a9e63; font-weight:700; }
  .cons li::before{ content:"✕"; position:absolute; left:0; color:#c0603a; font-weight:700; }
  @media (prefers-color-scheme:dark){ .pros li::before{color:#74cf93;} .cons li::before{color:#e0906a;} }
  :root[data-theme="dark"] .pros li::before{color:#74cf93;} :root[data-theme="dark"] .cons li::before{color:#e0906a;}
  @media (max-width:420px){ .pc{ grid-template-columns:1fr; } }

  .best{ margin:2px 0 0; font-size:13px; color:var(--muted); border-top:1px solid var(--line); padding-top:12px; }
  .best b{ font-family:var(--mono); font-size:10.5px; letter-spacing:.1em; text-transform:uppercase; color:var(--ink); margin-right:8px; }

  /* footer */
  footer{ margin-top:44px; border-top:1px solid var(--line); padding-top:22px; color:var(--muted); font-size:13.5px; }
  footer code{ font-family:var(--mono); font-size:12.5px; background:var(--surface); border:1px solid var(--line);
               padding:2px 7px; border-radius:6px; color:var(--ink); }
  footer h4{ font-family:var(--mono); font-size:11px; letter-spacing:.14em; text-transform:uppercase; color:var(--ink); margin:0 0 8px; }

  /* lightbox */
  #lb{ position:fixed; inset:0; background:rgba(8,8,10,.9); display:none; place-items:center; z-index:50; padding:24px; cursor:zoom-out; }
  #lb.on{ display:grid; }
  #lb img{ max-height:94vh; max-width:min(96vw,520px); border-radius:16px; box-shadow:0 24px 80px rgba(0,0,0,.6); }
  @media (prefers-reduced-motion:no-preference){ .card{ transition:border-color .2s; } }
</style>

<div class="wrap">
  <header class="top">
    <div>
      <div class="eyebrow">Memory Pager · 디자인 디렉션</div>
      <h1>같은 앱, 완전히 다른 10가지 디자인</h1>
      <p class="lede">커플 전용 메모리 앱 “Memory Pager”를, 정보 구조는 그대로 두고 열 가지 완전히 다른 비주얼·UX 방향으로 구현했습니다. 각 방향마다 핵심 히어로 화면 3개(낙서 보내기 · 펫 키우기 · 사진첩)를 실제 Flutter로 렌더한 결과입니다.</p>
      <div class="meta-row">
        <span><b>10</b> directions</span><span><b>3</b> hero screens each</span>
        <span><b>30</b> real Flutter renders</span><span>web build · 428×926</span>
      </div>
    </div>
    <button class="toggle" id="themeBtn" aria-label="테마 전환">◐ Theme</button>
  </header>

  <section class="reco">
    <h3>추천 요약 · Where to start</h3>
    <p>__RECO__</p>
    <div class="picks">
      <span class="pick-chip"><b>07</b> Quiet Signal · 안전한 출발점</span>
      <span class="pick-chip"><b>05</b> Washi Scrapbook · 주제 적합·협업 킬러</span>
      <span class="pick-chip"><b>10</b> Darkroom · 가장 대담한 차별화</span>
    </div>
  </section>

  <nav class="filter" aria-label="화면 필터">
    <span class="lbl">화면</span>
    <button class="fbtn" data-f="all" aria-pressed="true">세 화면 모두</button>
    <button class="fbtn" data-f="drawSend" aria-pressed="false">Draw &amp; Send</button>
    <button class="fbtn" data-f="petHome" aria-pressed="false">Pet Home</button>
    <button class="fbtn" data-f="memoryAlbum" aria-pressed="false">Album</button>
  </nav>

  <main class="grid">
__CARDS__
  </main>

  <footer>
    <h4>실제로 만져보기</h4>
    <p>이 10개는 목업이 아니라 실행되는 Flutter 앱입니다. 프로젝트 루트에서 <code>flutter run -d chrome</code> 를 실행하면 갤러리가 뜨고, 좌측에서 디자인을, 상단에서 화면을 전환하며 인터랙션(펫 쓰다듬기, 모드 토글 등)까지 직접 확인할 수 있습니다. 특정 화면만 보려면 <code>?d=07&amp;s=petHome&amp;solo=1</code> 처럼 딥링크도 됩니다. 마음에 드는 방향을 고르시면, 그 하나를 iOS/Android로 빌드해 실제 제품으로 발전시킵니다.</p>
  </footer>
</div>

<div id="lb" onclick="this.classList.remove('on')"><img alt="enlarged preview"></div>

<script>
  (function(){
    var root=document.documentElement, btn=document.getElementById('themeBtn');
    btn.addEventListener('click',function(){
      var cur=root.getAttribute('data-theme');
      if(!cur){ cur = matchMedia('(prefers-color-scheme:dark)').matches ? 'dark':'light'; }
      root.setAttribute('data-theme', cur==='dark'?'light':'dark');
    });
    var btns=[].slice.call(document.querySelectorAll('.fbtn'));
    btns.forEach(function(b){ b.addEventListener('click',function(){
      var f=b.dataset.f;
      btns.forEach(function(x){ x.setAttribute('aria-pressed', x===b ? 'true':'false'); });
      document.querySelectorAll('.shot').forEach(function(s){
        s.style.display = (f==='all'||s.dataset.screen===f)?'':'none';
      });
    });});
    window.zoom=function(img){ var lb=document.getElementById('lb'); lb.querySelector('img').src=img.src; lb.classList.add('on'); };
    document.addEventListener('keydown',function(e){ if(e.key==='Escape') document.getElementById('lb').classList.remove('on'); });
  })();
</script>
"""

if __name__ == "__main__":
    main()
