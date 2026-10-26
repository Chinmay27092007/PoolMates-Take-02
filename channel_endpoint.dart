import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ChannelEndpoint extends Endpoint {
  /// Lists community channels for a campus.
  Future<List<Channel>> list(Session session, int campusId) async {
    return await Channel.db.find(
      session,
      where: (t) => t.campusId.equals(campusId),
      orderBy: (t) => t.name,
    );
  }

  /// Live streaming messages for a community channel.
  Stream<ChannelMessage> streamChannel(Session session, int channelId) async* {
    yield* session.messages.createStream<ChannelMessage>('channel_stream_$channelId');
  }

  /// Sends a message to a community channel and broadcasts live.
  Future<ChannelMessage> sendChannelMessage(
    Session session, {
    required int channelId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = ChannelMessage(
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      sentAt: DateTime.now(),
    );

    final saved = await ChannelMessage.db.insertRow(session, message);

    session.messages.postMessage('channel_stream_$channelId', saved);

    return saved;
  }

  /// Fetches history for a community channel.
  Future<List<ChannelMessage>> history(Session session, int channelId) async {
    return await ChannelMessage.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
      orderBy: (t) => t.sentAt,
    );
  }
}
