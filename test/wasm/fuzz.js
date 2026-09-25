// Robustness fuzz of the WebAssembly DMI: the counterpart of
// test/src/dmi_fuzz.adb. The wasm runtime cannot propagate exceptions, so
// any raise inside the DMI is a trap that would stop the display; this
// script fails on the first one and prints the message that caused it.
//
//   node test/wasm/fuzz.js [steps [seed]]      default 20000 steps, seed 1
const fs = require('fs');
const path = require('path');

const steps = parseInt(process.argv[2] || '20000', 10);
let state = (parseInt(process.argv[3] || '1', 10) >>> 0) || 1;

// xorshift32, the same generator as the Ada fuzzer
function next() {
  state ^= state << 13; state >>>= 0;
  state ^= state >>> 17;
  state ^= state << 5; state >>>= 0;
  return state;
}
const pick = (lo, hi) => lo + (next() % (hi - lo + 1));
const chance = (pct) => pick(1, 100) <= pct;
const speed = () => { const k = pick(1, 10); return k === 1 ? 0 : k === 2 ? 400 : pick(0, 400); };
const optional = (lo, hi, none) => (chance(40) ? none : pick(lo, hi));

let lastException = '';
const mod = {};
const env = {
  __gnat_grow: (pages) => mod.e.memory.grow(pages),
  __gnat_put_exception: (addr, size, line) => {
    lastException = Buffer.from(mod.e.memory.buffer, addr, size).toString('latin1') + (line ? ':' + line : '');
  },
};
const instance = new WebAssembly.Instance(
  new WebAssembly.Module(fs.readFileSync(path.join(__dirname, 'dmi.wasm'))), { env });
const dmi = mod.e = instance.exports;
dmi.__gnat_initialize(0);
dmi.adainit();
dmi.dmi_initialise();

class Msg {
  constructor() { this.b = []; }
  u8(v) { this.b.push(v & 0xFF); return this; }
  u16(v) { return this.u8(v).u8(v >>> 8); }
  u32(v) { return this.u16(v & 0xFFFF).u16(v >>> 16); }
  random(n) { for (let i = 0; i < n; i++) this.u8(pick(0, 255)); return this; }
}

const EVC_TYPES = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x0A, 0x0B, 0x0C,
                   0x0E, 0x0F];
const FIXED = { 0x01: 21, 0x02: 9, 0x04: 2, 0x07: 22, 0x0A: 8, 0x0C: 2, 0x0E: 2 };

function inDomain(type) {
  const m = new Msg();
  if (type === 0x01) {
    for (let i = 0; i < 6; i++) m.u16(speed());
    m.u32(pick(0, 90000)).u8(pick(0, 2)).u8(pick(0, 3)).u8(pick(0, 7))
      .u8(pick(0, 4)).u8(pick(0, 255)); // status, mrdt
  } else if (type === 0x02) {
    m.u8(pick(0, 17)).u8(pick(0, 5)).u8(optional(5, 12, 0xFF)).u8(optional(2, 5, 0xFF))
      .u8(pick(0, 1)).u8(pick(0, 1)).u8(pick(0, 1)).u16(optional(0, 400, 0xFFFF));
    // the National System's name: mostly none (9 bytes), else any bytes
    // up to two beyond the maximum of 10, now and then a wrong length
    if (chance(50)) {
      const n = pick(0, 12);
      m.u8(n).random(n);
      if (chance(5)) m.b.pop(); else if (chance(5)) m.u8(pick(0, 255));
    }
  } else if (type === 0x03) {
    const n = pick(0, 255); // up to the greatest length, any byte, words of any width
    m.u16(pick(0, 20)).u8(pick(0, 15)).u8(pick(0, 23)).u8(pick(0, 59)).u8(n);
    for (let i = 0; i < n; i++) m.u8(pick(0, 5) === 0 ? 0x20 : pick(0, 255));
  } else if (type === 0x04) {
    m.u16(pick(0, 20));
  } else if (type === 0x05) {
    const n = pick(0, 8);
    m.u8(n);
    for (let i = 0; i < n; i++) m.u8(pick(0, 255)).u8(pick(1, 38));
  } else if (type === 0x06) {
    m.u16(pick(0, 65534)).u16(optional(0, 40000, 0xFFFF)).u16(optional(0, 40000, 0xFFFF)).u16(speed());
    let n = pick(0, 12), d = 0;
    m.u8(n);
    for (let i = 0; i < n; i++) { m.u16(d).u8(pick(0, 255)); d = Math.min(d + pick(1, 6000), 65000); }
    n = pick(0, 14); d = 0;
    m.u8(n);
    for (let i = 0; i < n; i++) { d = Math.min(d + pick(1, 6000), 65000); m.u16(d).u16(chance(10) ? 0x8000 : speed()); }
    n = pick(0, 16);
    m.u8(n);
    for (let i = 0; i < n; i++) m.u8(pick(1, 37)).u16(pick(0, 40000));
  } else if (type === 0x07) {
    m.u8(pick(0, 3)).u8(pick(0, 2)).u8(pick(0, 1)).u8(pick(0, 1)).u8(pick(0, 1)).u8(pick(0, 2))
      .u16(optional(0, 400, 0xFFFF)).u8(optional(0, 30, 0xFF)).u8(pick(1, 30)).u8(pick(0, 2))
      .u32(pick(0, 90000)).u32(chance(30) ? 0xFFFFFFFF : pick(0, 9999999))
      .u8(pick(0, 23)).u8(pick(0, 59)).u8(pick(0, 59));
  } else if (type === 0x0A) {
    // on-board state: data, session, rbc, train, national, som, waiting,
    // start pending; the coded fields go one value beyond the documented
    m.u8(pick(0, 255)).u8(pick(0, 4)).u8(pick(0, 255)).u8(pick(0, 255))
      .u8(pick(0, 255)).u8(pick(0, 3)).u8(pick(0, 4)).u8(pick(0, 1));
  } else if (type === 0x0B) {
    // MSG_ATO: the coded fields go one value beyond the documented, the
    // name sometimes one byte beyond its maximum of 32
    const n = chance(5) ? 33 : pick(0, 32), count = pick(0, 12);
    m.u8(pick(0, 3)).u8(pick(0, 6)).u8(pick(0, 1)).u8(pick(0, 2)).u8(pick(0, 4))
      .u16(chance(10) ? pick(5999, 6001) : optional(0, 5999, 0xFFFF))
      .u8(pick(0, 1)).u8(pick(0, 8)).u8(pick(0, 4))
      .u16(chance(10) ? pick(399, 401) : optional(0, 400, 0xFFFF))
      .u8(pick(0, 1)).u8(optional(0, 24, 0xFF)).u8(pick(0, 60)).u8(pick(0, 60)).u8(n);
    for (let i = 0; i < n; i++) m.u8(pick(0, 255));
    m.u8(count);
    for (let i = 0; i < count; i++) m.u16(pick(0, 40000));
  } else if (type === 0x0C) {
    // system status: the catalogue and one number on each side, the
    // three events and one beyond, now and then any byte
    m.u8(chance(90) ? pick(0, 39) : pick(0, 255)).u8(chance(90) ? pick(0, 3) : pick(0, 255));
  } else if (type === 0x0E) {
    // system version: X and Y and one beyond each, now and then any byte
    m.u8(chance(90) ? pick(0, 8) : pick(0, 255)).u8(chance(90) ? pick(0, 16) : pick(0, 255));
  } else if (type === 0x0F) {
    // VBC list: up to two beyond the 16, codes up to 2**24 and now and
    // then any u32, now and then a wrong length
    const n = pick(0, 18);
    m.u8(n);
    for (let i = 0; i < n; i++) m.u32(chance(5) ? next() : pick(0, 0x1000000));
    if (chance(5)) m.b.pop(); else if (chance(5)) m.u8(pick(0, 255));
  }
  return m.b;
}

function stimulus() {
  const kind = pick(1, 100);
  if (kind <= 45) { const t = EVC_TYPES[pick(0, EVC_TYPES.length - 1)]; return [t, inDomain(t)]; }
  if (kind <= 60) { const t = EVC_TYPES[pick(0, EVC_TYPES.length - 1)]; return [t, new Msg().random(FIXED[t] ?? pick(0, 120)).b]; }
  if (kind <= 70) return [pick(0, 255), new Msg().random(pick(0, 300)).b];
  if (kind > 94) {
    // MSG_DESK_INPUT: the desk keys, mostly defined inputs going down
    // and up, sometimes any byte or a wrong length
    const m = new Msg().u8(chance(90) ? pick(0, 3) : pick(0, 255)).u8(chance(90) ? pick(0, 1) : pick(0, 255));
    if (chance(5)) m.b = m.b.slice(0, 1); else if (chance(5)) m.u8(pick(0, 255));
    return [0x52, m.b];
  }
  const m = new Msg().u8(chance(95) ? pick(0, 2) : pick(0, 255));
  if (chance(95)) m.u16(pick(0, 639)).u16(pick(0, 479)); else m.u16(pick(0, 65535)).u16(pick(0, 65535));
  return [0x50, m.b];
}

function send(type, payload) {
  const frame = new Uint8Array(5 + payload.length);
  frame[0] = type;
  new DataView(frame.buffer).setUint32(1, payload.length, true);
  frame.set(payload, 5);
  new Uint8Array(dmi.memory.buffer, dmi.dmi_rx_buffer(), frame.length).set(frame);
  dmi.dmi_receive(frame.length);
}

const hex = (b) => b.slice(0, 48).map((v) => v.toString(16).padStart(2, '0')).join(' ');

for (let step = 1; step <= steps; step++) {
  const [type, payload] = stimulus();
  let where = 'receive';
  try {
    send(type, payload);
    where = 'tick';
    dmi.dmi_tick(chance(2) ? 1000 : pick(0, 200));
    where = 'render';
    dmi.dmi_render();
    where = 'transmit';
    dmi.dmi_transmit();
  } catch (e) {
    console.log(`TRAP at step ${step} in ${where}: ${lastException || e.message}`);
    console.log(`   last message: type ${type} length ${payload.length} : ${hex(payload)}`);
    process.exit(1);
  }
}
console.log(`steps: ${steps}  no trap`);
