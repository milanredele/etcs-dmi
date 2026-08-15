const WebSocket = require('ws');
const net = require('net');
const { packTelegram } = require('./protocol');
 
const wss = new WebSocket.Server({ port: 8080 });
var webSocket;
var tcpSocket;

function incoming(message) {
	console.log('received through ws: %s', message);
	if (tcpSocket) {
		try {
			const params = JSON.parse(message);
			const buf = packTelegram(params);
			tcpSocket.write(buf);
			console.log('Sent to TCP (16 bytes, CRC included): ' + buf.toString('hex'));
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