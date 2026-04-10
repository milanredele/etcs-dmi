const WebSocket = require('ws');
const net = require('net');
 
const wss = new WebSocket.Server({ port: 8080 });
var webSocket;
var tcpSocket;

function incoming(message) {
	console.log('received through ws: %s', message);
	if (tcpSocket) {
		// Send the param update to Ada as a simple binary packet
		// 6 values: Speed, Vperm, Vtarget, Vrelease, Distance (32-bit), Range (each remaining 16-bit)
		try {
			const params = JSON.parse(message);
			const buf = Buffer.alloc(14);
			buf.writeUInt16LE(params.speed || 0, 0);
			buf.writeUInt16LE(params.vperm || 0, 2);
			buf.writeUInt16LE(params.vtarget || 0, 4);
			buf.writeUInt16LE(params.vrelease || 0, 6);
			buf.writeUInt16LE(params.range !== undefined ? params.range : 1, 8); // Allow index 0
			buf.writeUInt32LE(params.dist || 0, 10);
			tcpSocket.write(buf);
			console.log('Sent to TCP: ' + buf.toString('hex'));
		} catch (e) {
			console.error('Invalid JSON from WS:', e);
		}
	}
}

wss.on('connection', function connection(ws) {
	console.log('WebSocket connected');
	webSocket = ws;
	webSocket.on('message', incoming);
});
 
var server = net.createServer(function(socket) {
	console.log('TCP client connected');
	tcpSocket = socket;
	socket.on ('data', function (data) {
		if (webSocket && webSocket.readyState === WebSocket.OPEN) {
			webSocket.send (data);
		}
	});
	socket.on('end', () => {
		console.log('TCP client disconnected');
		tcpSocket = null;
	});
});

server.listen(1337, '127.0.0.1');