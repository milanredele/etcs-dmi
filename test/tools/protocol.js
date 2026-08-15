// Simple generator script to extract protocol from Ada to JS
const fs = require('fs');
const path = require('path');

const adsPath = path.join(__dirname, '../../src/dmi_protocol.ads');
const ads = fs.readFileSync(adsPath, 'utf8');

/**
 * Extracts the layout of DMI_Telegram_T from dmi_protocol.ads
 * to avoid hard-coded offsets in JS.
 */
function getTelegramLayout() {
    const layout = {};
    const regex = /(\w+)\s+at\s+(\d+)\s+range\s+(\d+)\s+\.\.\s+(\d+)/g;
    let match;
    while ((match = regex.exec(ads)) !== null) {
        layout[match[1]] = {
            offset: parseInt(match[2]),
            start: parseInt(match[3]),
            end: parseInt(match[4])
        };
    }
    return layout;
}

/**
 * Extracts bit offsets for DMI_Status_T.
 * Ada 'Pack' pragma on a record is assumed to assign bits sequentially.
 */
function getStatusBits() {
    const statusIdx = ads.indexOf('type DMI_Status_T is record');
    const endIdx = ads.indexOf('end record', statusIdx);
    const content = ads.substring(statusIdx, endIdx);
    const bits = [];
    const lineRegex = /(\w+)\s+:\s+(\w+)/g;
    let match;
    let currentBit = 0;
    
    while ((match = lineRegex.exec(content)) !== null) {
        const name = match[1];
        const type = match[2];
        let size = 1;
        if (type.includes('Two_Bits')) size = 2;
        if (type.includes('Four_Bits')) size = 4;
        if (type.includes('Unsigned_8')) size = 8;
        
        bits.push({ name: name.toLowerCase(), bit: currentBit, size: size });
        currentBit += size;
    }
    return bits;
}

const LAYOUT = getTelegramLayout();
const STATUS_BITS = getStatusBits();

function packTelegram(params) {
    const buf = Buffer.alloc(16);
    
    // Pack Status Word using parsed bit offsets
    let status = 0;
    STATUS_BITS.forEach(entry => {
        const val = params[entry.name];
        if (val !== undefined) {
            const mask = (1 << entry.size) - 1;
            status |= (val & mask) << entry.bit;
        } else if (entry.name === 'flash_on' && params.flash_on !== undefined) {
            status |= (params.flash_on ? 1 : 0) << entry.bit;
        } else if (entry.name === 'vrelease_exists' && params.vrelease_exists !== undefined) {
            status |= (params.vrelease_exists ? 1 : 0) << entry.bit;
        } else if (entry.name === 'show_taf' && params.show_taf !== undefined) {
            status |= (params.show_taf ? 1 : 0) << entry.bit;
        } else if (entry.name === 'speed_range' && params.range !== undefined) {
            status |= (params.range & 0x3) << entry.bit;
        }
    });

    // Write fields based on Ada representation clause
    if (LAYOUT.V_Cur) buf.writeUInt16LE(params.speed || 0, LAYOUT.V_Cur.offset);
    if (LAYOUT.V_Perm) buf.writeUInt16LE(params.vperm || 0, LAYOUT.V_Perm.offset);
    if (LAYOUT.V_Targ) buf.writeUInt16LE(params.vtarget || 0, LAYOUT.V_Targ.offset);
    if (LAYOUT.V_Rel) buf.writeUInt16LE(params.vrelease || 0, LAYOUT.V_Rel.offset);
    if (LAYOUT.D_Targ) buf.writeUInt32LE(params.dist || 0, LAYOUT.D_Targ.offset);
    if (LAYOUT.Status) buf.writeUInt16LE(status, LAYOUT.Status.offset);

    // CRC-16 CCITT
    const crc = crc16(buf.slice(0, 14));
    if (LAYOUT.Checksum) buf.writeUInt16LE(crc, LAYOUT.Checksum.offset);

    return buf;
}

function crc16(data) {
    let crc = 0xFFFF;
    for (let i = 0; i < data.length; i++) {
        crc ^= data[i] << 8;
        for (let j = 0; j < 8; j++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ 0x1021;
            } else {
                crc = (crc << 1);
            }
        }
    }
    return (crc & 0xFFFF);
}

module.exports = { packTelegram, crc16 };
