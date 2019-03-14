const WebSocket = require('ws');
const net = require('net');
 
const wss = new WebSocket.Server({ port: 8080 });
var webSocket;

function incoming(message) {
	console.log('received through ws: %s', message);
}

wss.on('connection', function connection(ws) {
	console.log('WebSocket connected');
	webSocket = ws;
	webSocket.on('message', incoming);
});
 
var server = net.createServer(function(socket) {
	socket.on ('data', function (data) {
		webSocket.send (data);
	});
});

server.listen(1337, '127.0.0.1');