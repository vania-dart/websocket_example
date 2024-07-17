import 'dart:convert';

import 'package:events_emitter/events_emitter.dart';
import 'package:web_socket_client/web_socket_client.dart';

class Connection extends EventEmitter {

  
  static final Connection _singleton = Connection._internal();
  factory Connection() => _singleton;
  Connection._internal();

  late WebSocket _socket;

  void connect() {
    final uri = Uri.parse('ws://localhost:8000/ws');
    const backoff = ConstantBackoff(Duration(seconds: 1));
    _socket = WebSocket(uri, backoff: backoff);

    _socket.connection.listen((state) {
      if (state is Connected) {
        emit('connection_status','Connected');
      }
      if (state is Reconnected) {
        emit('connection_status','Connected');
      }
      if (state is Reconnecting) {
        emit('connection_status','Disconnected(Reconnecting...)');
      }
      if (state is Connecting) {
        emit('connection_status','Connecting');
      }
      if (state is Disconnected) {
        emit('connection_status','Disconnected');
      }
    });

    _socket.messages.listen((payload) {
      Map<String, dynamic> data = jsonDecode(payload);
      emit(data['event'], data['payload']);
    });

   
  }
  void send({required String event, dynamic payload}) {
    _socket.send(jsonEncode({'event': event, 'payload': payload}));
  }

  void joinRoom({required String roomId}) {
    _socket.send(jsonEncode({'event': 'join-room', 'room': roomId}));
  }

  void closeConnection() => _socket.close();
}
