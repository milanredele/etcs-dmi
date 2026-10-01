// Cross-check of the WebAssembly build of the ETCS on-board (onboard.wasm:
// EVC_Core of evc/ in the bench environment of sim/) against the native
// build: runs the scenario of Scenario_Bench_Onboard in
// test/src/evc_test.adb (reset, the desk on auto drive, Bench_Cycles
// cycles of 100 ms, the brake release acknowledged on the DMI port
// whenever the on-board asks for it, the driver's start of mission in
// level 1 after the first cycles) and compares the SHA-256 of the
// on-board's DMI frames with test/golden/evc/bench_onboard.sha256, which
// evc_test records natively. The two builds must feed the DMI the same
// bytes. Before it, the installation configuration of the page
// (onboard.cfg, onboard_configure); after it, the containment path of the
// page (a trap, Enter_Failure).
// Run from the repository root: node test/wasm/onboard_smoke.js
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const HEADER_LENGTH = 5;
const MSG_TRACK_LAYOUT = 0x08;   // the track strip frames of the page,
const MSG_SIM_STATE = 0x09;      // not the on-board's
const CYCLES = 600;              // evc_test Bench_Cycles

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

function receive(ex, bytes) {
  const cap = ex.onboard_rx_capacity();
  const base = ex.onboard_rx_buffer();
  for (let off = 0; off < bytes.length; off += cap) {
    const n = Math.min(cap, bytes.length - off);
    new Uint8Array(ex.memory.buffer, base, n).set(bytes.subarray(off, off + n));
    ex.onboard_receive(n);
  }
}

function transmit(ex) {
  const n = ex.onboard_transmit();
  return new Uint8Array(ex.memory.buffer, ex.onboard_tx_buffer(), n).slice();
}

function frames(bytes) {
  const list = [];
  for (let o = 0; o + HEADER_LENGTH <= bytes.length;) {
    const len = new DataView(bytes.buffer, bytes.byteOffset + o + 1, 4).getUint32(0, true);
    list.push(bytes.subarray(o, o + HEADER_LENGTH + len));
    o += HEADER_LENGTH + len;
  }
  return list;
}

function jruText(ex, age) {
  const n = ex.onboard_jru_describe(age);
  return Buffer.from(ex.memory.buffer, ex.onboard_text_buffer(), n).toString('latin1');
}

let failures = 0;
function check(ok, what) {
  if (ok) console.log(`pass: ${what}`);
  else { failures++; console.log(`FAIL: ${what}`); }
}

const ex = load('onboard.wasm');

// --- __multi3 (Wasm_Int128): the 128-bit product the on-board's checked
// --- 64-bit multiplications use on wasm32, against BigInt -------------
{
  const M64 = (1n << 64n) - 1n, M128 = (1n << 128n) - 1n;
  let seed = 12345n, bad = 0;
  const next = () => { seed = (seed * 6364136223846793005n + 1442695040888963407n) & M64; return seed; };
  const ret = ex.onboard_rx_buffer();   // 16 bytes of scratch, before any receive
  for (let i = 0; i < 2000; i++) {
    const a = (next() << 64n) | next(), b = i % 3 ? (next() << 64n) | next()
                                                  : BigInt.asUintN(128, BigInt.asIntN(64, next()));
    ex.__multi3(ret, BigInt.asIntN(64, a & M64), BigInt.asIntN(64, a >> 64n),
                     BigInt.asIntN(64, b & M64), BigInt.asIntN(64, b >> 64n));
    const dv = new DataView(ex.memory.buffer, ret, 16);
    const got = dv.getBigUint64(0, true) | (dv.getBigUint64(8, true) << 64n);
    if (got !== ((a * b) & M128)) bad++;
  }
  check(bad === 0, '__multi3 is the 128-bit product (2000 random operands)');
}

// --- The installation configuration, as the page loads it ------------
// onboard.cfg (the image of the default configuration, made by
// test/tools/evc_config.py from ports/hosted/evc.cfg) before the first
// reset; the golden stays that of the native run without an image, which
// uses the same default. A damaged copy is refused.
function configure(ex, image) {
  new Uint8Array(ex.memory.buffer, ex.onboard_rx_buffer(), image.length).set(image);
  return ex.onboard_configure(image.length);
}
{
  const image = fs.readFileSync(path.join(__dirname, 'onboard.cfg'));
  const damaged = Uint8Array.from(image);
  damaged[20] ^= 1;   // the antenna to cab A: the CRC no longer matches
  check(configure(ex, damaged) === 0, 'a damaged configuration image is refused');
  check(configure(ex, image) === 1, `onboard.cfg (${image.length} bytes) is the configuration`);
}

// --- The scenario of evc_test Scenario_Bench_Onboard ------------------
// MSG_DRIVER_ACTION, action 2 (acknowledgement), kind 5 (brake release)
const ACK = new Uint8Array([0x40, 5, 0, 0, 0, 2, 5, 0, 0, 0]);
// The driver's start of mission in level 1, one frame after each of the
// first cycles (Sim_Onboard_Env.SoM_Frame, phase E4): the driver ID
// "1234", level 1, the Train Data (200 m, 135 %, 160 km/h, ...), the train
// running number "5678", 'Start', the acknowledgement of SR
const SOM = [
  [0x41, 6, 0, 0, 0, 0, 4, 0x31, 0x32, 0x33, 0x34],
  [0x40, 3, 0, 0, 0, 11, 4, 0],
  [0x41, 13, 0, 0, 0, 2, 200, 0, 135, 0, 160, 0, 2, 4, 0, 0, 0, 1],
  [0x41, 6, 0, 0, 0, 1, 4, 0x35, 0x36, 0x37, 0x38],
  [0x40, 3, 0, 0, 0, 5, 0, 0],
  [0x40, 5, 0, 0, 0, 2, 1, 0, 0, 0],
].map((f) => new Uint8Array(f));
ex.onboard_reset();
ex.onboard_set_desk(0, 1);
const hash = crypto.createHash('sha256');
let bytes = 0, acks = 0, simFrames = 0;
for (let i = 0; i < CYCLES; i++) {
  ex.onboard_step(100);
  for (const f of frames(transmit(ex))) {
    if (f[0] === MSG_TRACK_LAYOUT || f[0] === MSG_SIM_STATE) { simFrames++; continue; }
    hash.update(f);
    bytes += f.length;
  }
  if (ex.onboard_ack_requested()) { receive(ex, ACK); acks++; }
  if (i < SOM.length) receive(ex, SOM[i]);
}
const actual = hash.digest('hex');
const expected = fs.readFileSync(
  path.join(root, 'test', 'golden', 'evc', 'bench_onboard.sha256'), 'utf8').trim();
console.log(`  ${CYCLES} cycles, ${bytes} bytes of DMI frames, ${acks} acknowledgement(s), ` +
            `the train at ${ex.onboard_position()} m, ${ex.onboard_speed()} km/h, ` +
            `mode ${ex.onboard_mode()} level ${ex.onboard_level()}, ` +
            `${ex.onboard_jru_count()} JRU records`);
if (actual === expected) {
  console.log('pass: bench_onboard, the wasm on-board sends the native bytes');
} else {
  failures++;
  console.log(`FAIL: bench_onboard\n  expected ${expected}\n  actual   ${actual}`);
}
check(ex.onboard_failed() === 0 && simFrames >= CYCLES,
      'the on-board runs, the track strip frames come every cycle');
check(ex.onboard_jru_available() > 0 && jruText(ex, 0).length > 0,
      `the JRU sink describes its records ("${jruText(ex, 0)}")`);
check(ex.onboard_group_count() === 6 && ex.onboard_group_at(1) === -12,
      'the balise groups of the line');

// --- Containment: a trap, then Enter_Failure (the page's path) ---------
ex.onboard_enter_failure();
check(ex.onboard_failed() === 1, 'the failure is latched');
let dmiFrames = 0;
for (let i = 0; i < 200; i++) {
  ex.onboard_step(100);
  for (const f of frames(transmit(ex))) {
    if (f[0] !== MSG_TRACK_LAYOUT && f[0] !== MSG_SIM_STATE) dmiFrames++;
  }
}
check(dmiFrames === 0 && ex.onboard_fail_safe() === 1 && ex.onboard_speed() === 0,
      'a failed on-board falls silent, the train interface brakes the train to a stand');
ex.onboard_reset();
check(ex.onboard_failed() === 0 && ex.onboard_fail_safe() === 0,
      'reset restarts the on-board');

console.log(`failures: ${failures}`);
process.exit(failures ? 1 : 0);
