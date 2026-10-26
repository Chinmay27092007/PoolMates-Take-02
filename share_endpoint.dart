import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ShareEndpoint extends Endpoint {
  /// Unauthenticated public trip summary by share token.
  /// Shows only route, time, creator first name, member count, safety status.
  /// No private phone numbers or emails exposed.
  Future<PublicTripSummary?> getByToken(Session session, String token) async {
    final ride = await Ride.db.findFirstRow(
      session,
      where: (t) => t.shareToken.equals(token),
    );

    if (ride == null) return null;

    final members = await RideMember.db.find(
      session,
      where: (t) => t.rideId.equals(ride.id!),
    );

    final creatorFirstName = ride.creatorName.split(' ').first;

    return PublicTripSummary(
      origin: ride.origin,
      destination: ride.destination,
      departAt: ride.departAt,
      creatorFirstName: creatorFirstName,
      memberCount: members.length,
      seatsTotal: ride.seatsTotal,
      womenOnly: ride.womenOnly,
      status: ride.status,
    );
  }
}
