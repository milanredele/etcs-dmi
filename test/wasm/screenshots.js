// Regenerates doc/images/bench.png: drives the browser bench in headless
// Chrome through the DevTools protocol, runs the start-up dialogue by
// touch like a driver would, lets the mission run into target speed
// monitoring and takes the screenshot (about three minutes, real time).
//
//   python3 -m http.server 8768 --bind 127.0.0.1 &     (repository root)
//   node test/wasm/screenshots.js [output directory, default doc/images]
//
// CHROME overrides the browser binary (default: Google Chrome on macOS).
// The DMI-only images come from the regression runner instead:
//   DUMP=1 obj/dmi_test && test/tools/frame2png.py test/golden/<name>.actual out.png
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');
const out = path.resolve(process.argv[2] || path.join(__dirname, '..', '..', 'doc', 'images'));
const CHROME = process.env.CHROME || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const PORT = 9333, HTTP = 8768;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const chrome = spawn(CHROME, [
    '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
    '--autoplay-policy=no-user-gesture-required', '--mute-audio',
    `--remote-debugging-port=${PORT}`, '--window-size=800,1700',
    `--user-data-dir=${fs.mkdtempSync(path.join(os.tmpdir(), 'dmi-shot-'))}`, `http://127.0.0.1:${HTTP}/test/wasm/`,
  ], { stdio: 'ignore' });
  try {
    let target;
    for (let i = 0; i < 40 && !target; i++) {
      await sleep(500);
      try {
        const list = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
        target = list.find((t) => t.type === 'page' && t.url.includes('test/wasm'));
      } catch (e) { /* not up yet */ }
    }
    const ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((r) => { ws.onopen = r; });
    let id = 0; const pending = new Map();
    ws.onmessage = (m) => { const d = JSON.parse(m.data); if (pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); } };
    const send = (method, params = {}) => new Promise((r) => { pending.set(++id, r); ws.send(JSON.stringify({ id, method, params })); });
    const evalJSON = async (expr) => JSON.parse((await send('Runtime.evaluate', { expression: `JSON.stringify(${expr})`, returnByValue: true })).result.value);

    await sleep(2500);
    const rect = await evalJSON(`document.getElementById('myCanvas').getBoundingClientRect()`);
    const press = async (x, y) => {
      const p = { x: rect.left + x, y: rect.top + y, button: 'left', clickCount: 1 };
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', ...p });
      await sleep(160);
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', ...p });
      await sleep(320);
    };
    const shot = async (name) => {
      const top = await evalJSON(`document.querySelector('.panel').getBoundingClientRect().top + window.scrollY`);
      const bottom = await evalJSON(`document.querySelector('.bezel').getBoundingClientRect().bottom + window.scrollY`);
      const r = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true,
        clip: { x: 0, y: Math.max(0, top - 8), width: 800, height: bottom - top + 24, scale: 1 } });
      fs.writeFileSync(`${out}/${name}.png`, Buffer.from(r.data, 'base64'));
      console.log('shot', name, await evalJSON(`document.getElementById('stats').textContent`));
    };

    const ENTER = [589, 390];
    await press(610, 40);                       // Main
    await press(410, 90);                       // Start -> driver ID
    for (const k of [[385, 240], [487, 240], [589, 240]]) await press(...k); // 123
    await press(...ENTER);                      // -> level
    await press(410, 90);                       // Level 1 -> train data
    for (const k of [[385, 290], [487, 390], [487, 390]]) await press(...k); // 400
    await press(...ENTER);
    for (const k of [[385, 240], [589, 240], [487, 290]]) await press(...k); // 135
    await press(...ENTER);
    for (const k of [[385, 240], [385, 290], [487, 390]]) await press(...k); // 140
    await press(...ENTER);                      // -> validation
    await press(410, 390);                      // Yes -> TRN
    for (const k of [[385, 290], [385, 340], [385, 240], [385, 240]]) await press(...k); // 4711
    await press(...ENTER);                      // sequence ends, mission starts
    await sleep(1500);
    await press(375, 440);                      // close the Main window
    const simTime = async () => parseFloat((await evalJSON(`document.getElementById('stats').textContent`)).match(/t=([0-9.]+)/)[1]);
    while (await simTime() < 172) await sleep(500); // braking towards the 100 km/h restriction
    await shot('bench');
    ws.close();
  } finally {
    chrome.kill();
  }
})().catch((e) => { console.error(e); process.exit(1); });
