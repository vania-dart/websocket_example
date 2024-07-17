import 'package:vania/vania.dart';

class ChatWebSocketController extends Controller {
  Future newMessage(WebSocketClient client, dynamic payload) async {
    String toSessionId = payload['to_session_id'];
    String message = payload['message'];

    if (toSessionId.isEmpty || message.isEmpty) {
      return;
    }

    bool isClient = client.isActiveSession(sessionId: toSessionId);
    if (isClient) {
      Map<String, dynamic> messages = {
        'message': message,
        'sender_id': client.clientId,
      };
      client.to(toSessionId, 'message', messages);

      // Resend To me
      client.to(client.clientId, 'message', messages);
    } else {
      if (client.activeRoom.isEmpty) return;

      Map<String, dynamic> messages = {
        'message': message,
        'sender_id': client.clientId,
      };
      client.toRoom('message', client.activeRoom, messages);
    }
  }
}

ChatWebSocketController chatController = ChatWebSocketController();
