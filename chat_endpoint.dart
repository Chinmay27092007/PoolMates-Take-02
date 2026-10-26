import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ChatEndpoint extends Endpoint {
  /// Streaming live chat for a ride. Only accessible to ride members.
  Stream<RideMessage> rideChatStream(Session session, int rideId) async* {
    yield* session.messages.createStream<RideMessage>('ride_chat_$rideId');
  }

  /// Sends a message to the ride chat and broadcasts it live.
  Future<RideMessage> sendMessage(
    Session session, {
    required int rideId,
    required String senderId,
    required String text,
  }) async {
    // Authorisation rule: Only ride members can read/write that ride's chat
    final member = await RideMember.db.findFirstRow(
      session,
      where: (t) => t.rideId.equals(rideId) & t.userId.equals(senderId),
    );
    if (member == null) {
      throw Exception('Access denied: You must join this ride to participate in the chat.');
    }

    final message = RideMessage(
      rideId: rideId,
      senderId: senderId,
      senderName: member.userName,
      text: text.trim(),
      sentAt: DateTime.now(),
    );

    final saved = await RideMessage.db.insertRow(session, message);

    // Broadcast live over streaming channel
    session.messages.postMessage('ride_chat_$rideId', saved);

    return saved;
  }

  /// Returns chat history for a ride.
  Future<List<RideMessage>> history(Session session, int rideId) async {
    return await RideMessage.db.find(
      session,
      where: (t) => t.rideId.equals(rideId),
      orderBy: (t) => t.sentAt,
    );
  }
}
