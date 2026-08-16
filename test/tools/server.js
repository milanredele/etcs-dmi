// ETCS DMI test hub.
//
// Dumb message hub between three endpoints speaking protocol v2
// (see src/dmi_protocol.ads): every complete frame received from one
// endpoint is forwarded verbatim to the other two.
//
//   TCP 1337 : DMI
//   TCP 1338 : EVC simulator
//   WS  8080 : browser UI
const WebSocket = require('ws');
const net = require('net');

const HEADER_LENGTH = 5;

// Accumulates a byte stream and emits complete protocol frames.
function makeSplitter(onFrame) {
	let pending = Buffer.alloc(0);
	return function (data) {
		pending = Buffer.concat([pending, data]);
		while (pending.length >= HEADER_LENGTH) {
			const length = pending.readUInt32LE(1);
			const total = HEADER_LENGTH + length;
			if (pending.length < total) break;
			onFrame(pending.subarray(0, total));
			pending = pending.subarray(total);
		}
	};
}

let dmiSocket = null;
let evcSocket = null;
let webSocket = null;

const MSG_FRAME = 0x60;
const MSG_SOUND = 0x61;

function forward(from, frame) {
	const type = frame.readUInt8(0);
	// screen frames and sounds are for the UI only; flooding the EVC
	// with 300 kB frames would stall its receive path
	const uiOnly = type === MSG_FRAME || type === MSG_SOUND;
	if (from !== 'dmi' && !uiOnly && dmiSocket) dmiSocket.write(frame);
	if (from !== 'evc' && !uiOnly && evcSocket) evcSocket.write(frame);
	if (from !== 'web' && webSocket && webSocket.readyState === WebSocket.OPEN) {
		webSocket.send(frame);
	}
}

function tcpEndpoint(port, name, assign) {
	const server = net.createServer(function (socket) {
		console.log(`${name} connected`);
		assign(socket);
		socket.on('data', makeSplitter((frame) => forward(name, frame)));
		socket.on('error', (e) => console.log(`${name} error: ${e.message}`));
		socket.on('close', () => {
			console.log(`${name} disconnected`);
			assign(null);
		});
	});
	server.listen(port, '127.0.0.1');
	return server;
}

tcpEndpoint(1337, 'dmi', (s) => { dmiSocket = s; });
tcpEndpoint(1338, 'evc', (s) => { evcSocket = s; });

const wss = new WebSocket.Server({ port: 8080 });
wss.on('connection', function (ws) {
	console.log('browser connected');
	webSocket = ws;
	const split = makeSplitter((frame) => forward('web', frame));
	ws.on('message', (message) => split(Buffer.from(message)));
	ws.on('close', () => { console.log('browser disconnected'); webSocket = null; });
});

console.log('hub listening: DMI tcp:1337, EVC tcp:1338, UI ws:8080');
