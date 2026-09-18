// Cross-check of the WebAssembly build against the native golden frames:
// replays two regression scenarios through dmi.wasm / evc.wasm exactly
// as test/src/dmi_test.adb does and compares the SHA-256 of the rendered
// screen with test/golden. Run from the repository root: node test/wasm/smoke.js
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const HEADER_LENGTH = 5;

function load(file) {
  const mod = {};
  const env = {
    __gnat_grow: (pages) => mod.exports.memory.grow(pages),
    __gnat_put_exception: (addr, size, line) => {
      const msg = Buffer.from(mod.exports.memory.buffer, addr, size).toString('latin1');
      throw new Error(`${file}: exception ${msg}${line ? ':' + line : ''}`);
    },
  };
  const module = new WebAssembly.Module(fs.readFileSync(path.join(__dirname, file)));
  const instance = new WebAssembly.Instance(module, { env });
  mod.exports = instance.exports;
  instance.exports.__gnat_initialize(0);
  instance.exports.adainit();
  return instance.exports;
}

function receive(ex, prefix, bytes) {
  const cap = ex[prefix + '_rx_capacity']();
  const base = ex[prefix + '_rx_buffer']();
  for (let off = 0; off < bytes.length; off += cap) {
    const n = Math.min(cap, bytes.length - off);
    new Uint8Array(ex.memory.buffer, base, n).set(bytes.subarray(off, off + n));
    ex[prefix + '_receive'](n);
  }
}

function transmit(ex, prefix) {
  const n = ex[prefix + '_transmit']();
  return new Uint8Array(ex.memory.buffer, ex[prefix + '_tx_buffer'](), n).slice();
}

function frame(type, payload) {
  const buf = new Uint8Array(HEADER_LENGTH + payload.length);
  const dv = new DataView(buf.buffer);
  dv.setUint8(0, type);
  dv.setUint32(1, payload.length, true);
  buf.set(payload, HEADER_LENGTH);
  return buf;
}

function digest(dmi) {
  const w = dmi.dmi_frame_width(), h = dmi.dmi_frame_height();
  const px = new Uint8Array(dmi.memory.buffer, dmi.dmi_frame(), w * h);
  return crypto.createHash('sha256').update(px).digest('hex');
}

function golden(name) {
  return fs.readFileSync(path.join(root, 'test', 'golden', name + '.sha256'), 'utf8').trim();
}

let failures = 0;
function check(name, dmi) {
  const actual = digest(dmi), expected = golden(name);
  if (actual === expected) {
    console.log(`pass: ${name}`);
  } else {
    failures++;
    console.log(`FAIL: ${name}\n  expected ${expected}\n  actual   ${actual}`);
  }
}

const dmi = load('dmi.wasm');
const evc = load('evc.wasm');

// --- Scenario_FS_CSM, first frame: mode/level + speed state, one tick ---
dmi.dmi_initialise();
{
  const ml = new Uint8Array([2, 4, 0xFF, 0xFF, 0, 0, 0, 0xFF, 0xFF]); // FS, L1
  const ss = new Uint8Array(19);
  const dv = new DataView(ss.buffer);
  let o = 0;
  for (const v of [100, 120, 0, 0, 135, 125]) { dv.setUint16(o, v, true); o += 2; }
  dv.setUint32(o, 0, true); o += 4;
  ss[o++] = 0; ss[o++] = 1; ss[o++] = 0;
  receive(dmi, 'dmi', frame(0x02, ml));
  receive(dmi, 'dmi', frame(0x01, ss));
  transmit(dmi, 'dmi'); // drain sounds
  dmi.dmi_tick(50);
  dmi.dmi_render();
  check('fs_csm_nos', dmi);
}

// --- Scenario_Mission, first frame: five idle EVC steps in SB ----------
dmi.dmi_initialise();
evc.evc_reset();
for (let i = 0; i < 5; i++) {
  evc.evc_step(100);
  receive(dmi, 'dmi', transmit(evc, 'evc')); // the DMI ignores the sim only frames
  dmi.dmi_tick(100);
}
dmi.dmi_render();
check('mission_sb', dmi);

// --- Mission start: driver action travels back to the EVC ---------------
{
  receive(evc, 'evc', frame(0x40, new Uint8Array([5, 0, 0]))); // start mission
  let tsm = false;
  for (let i = 0; i < 2000 && !tsm; i++) {
    evc.evc_step(100);
    receive(dmi, 'dmi', transmit(evc, 'evc'));
    dmi.dmi_tick(100);
    tsm = evc.evc_core__monitoring() === 1;
  }
  if (tsm) console.log('pass: mission reaches TSM through the wasm EVC');
  else { failures++; console.log('FAIL: mission never reaches TSM'); }
  if (dmi.dmi_link_lost() === 0) console.log('pass: link up while the EVC talks');
  else { failures++; console.log('FAIL: link reported lost'); }
  for (let i = 0; i < 25; i++) dmi.dmi_tick(50); // 1.25 s of silence
  if (dmi.dmi_link_lost() === 1) console.log('pass: link lost after silence');
  else { failures++; console.log('FAIL: link not lost after silence'); }
}

console.log(`failures: ${failures}`);
process.exit(failures ? 1 : 0);
