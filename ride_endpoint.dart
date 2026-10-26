import 'dart:math';
import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class RideEndpoint extends Endpoint {
  /// Creates a new ride offer or request.
  Future<Ride> create(
    Session session, {
    required int campusId,
    required String creatorId,
    required String creatorName,
    required String type, // 'offer' or 'request'
    required String origin,
    required String destination,
    required DateTime departAt,
    required int seatsTotal,
    double? totalFare,
    required bool womenOnly,
  }) async {
    final creator = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(creatorId),
    );

    if (creator != null && womenOnly && creator.gender.toLowerCase() != 'female') {
      throw Exception('Only female students can create women-only rides.');
    }

    final shareToken = 'pm_${Random().nextInt(900000) + 100000}_${DateTime.now().millisecondsSinceEpoch % 10000}';

    var ride = Ride(
      campusId: campusId,
      creatorId: creatorId,
      creatorName: creatorName,
      type: type,
      origin: origin.trim(),
      destination: destination.trim(),
      departAt: departAt,
      seatsTotal: seatsTotal,
      seatsTaken: 1, // Creator is first member
      totalFare: totalFare,
      womenOnly: womenOnly,
      status: 'open',
      shareToken: shareToken,
      createdAt: DateTime.now(),
    );

    ride = await Ride.db.insertRow(session, ride);

    // Add creator as member
    await RideMember.db.insertRow(
      session,
      RideMember(
        rideId: ride.id!,
        userId: creatorId,
        userName: creatorName,
        userGender: creator?.gender ?? 'unknown',
        role: 'creator',
        joinedAt: DateTime.now(),
      ),
    );

    return ride;
  }

  /// Fetches a ride by ID.
  Future<Ride?> get(Session session, int id) async {
    return await Ride.db.findById(session, id);
  }

  /// Lists all rides the user is a member of.
  Future<List<Ride>> listMine(Session session, String userId) async {
    final memberships = await RideMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (memberships.isEmpty) return [];

    final rideIds = memberships.map((m) => m.rideId).toList();
    return await Ride.db.find(
      session,
      where: (t) => t.id.inSet(rideIds.toSet()),
      orderBy: (t) => t.departAt,
    );
  }

  /// Lists all members of a ride.
  Future<List<RideMember>> getMembers(Session session, int rideId) async {
    return await RideMember.db.find(
      session,
      where: (t) => t.rideId.equals(rideId),
      orderBy: (t) => t.joinedAt,
    );
  }

  /// Joins an open ride. Enforces women-only security strictly on the server.
  Future<bool> join(Session session, int rideId, String userId) async {
    final ride = await Ride.db.findById(session, rideId);
    if (ride == null) throw Exception('Ride not found');

    if (ride.status != 'open') {
      throw Exception('Ride is not open (status: ${ride.status})');
    }

    if (ride.seatsTaken >= ride.seatsTotal) {
      throw Exception('Ride is already full');
    }

    final user = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (user == null) throw Exception('User not found');

    // Strict safety check:
    if (ride.womenOnly && user.gender.toLowerCase() != 'female') {
      throw Exception('Access Denied: This is a verified women-only ride.');
    }

    // Check existing membership
    final existing = await RideMember.db.findFirstRow(
      session,
      where: (t) => t.rideId.equals(rideId) & t.userId.equals(userId),
    );
    if (existing != null) return true; // Already joined

    // Add member
    await RideMember.db.insertRow(
      session,
      RideMember(
        rideId: rideId,
        userId: userId,
        userName: user.name,
        userGender: user.gender,
        role: 'member',
        joinedAt: DateTime.now(),
      ),
    );

    // Update ride counts
    ride.seatsTaken += 1;
    if (ride.seatsTaken >= ride.seatsTotal) {
      ride.status = 'full';
    }
    await Ride.db.updateRow(session, ride);

    // Broadcast stream update
    session.messages.postMessage(
      'ride_update_$rideId',
      ride,
    );

    return true;
  }

  /// Leaves a ride.
  Future<bool> leave(Session session, int rideId, String userId) async {
    final member = await RideMember.db.findFirstRow(
      session,
      where: (t) => t.rideId.equals(rideId) & t.userId.equals(userId),
    );
    if (member == null) return false;

    await RideMember.db.deleteRow(session, member);

    final ride = await Ride.db.findById(session, rideId);
    if (ride != null) {
      ride.seatsTaken = max(0, ride.seatsTaken - 1);
      if (ride.status == 'full' && ride.seatsTaken < ride.seatsTotal) {
        ride.status = 'open';
      }
      await Ride.db.updateRow(session, ride);

      session.messages.postMessage(
        'ride_update_$rideId',
        ride,
      );
    }

    return true;
  }

  /// Cancels a ride (creator only).
  Future<bool> cancel(Session session, int rideId, String userId) async {
    final ride = await Ride.db.findById(session, rideId);
    if (ride == null) return false;
    if (ride.creatorId != userId) {
      throw Exception('Only the creator can cancel this ride.');
    }

    ride.status = 'cancelled';
    await Ride.db.updateRow(session, ride);

    session.messages.postMessage(
      'ride_update_$rideId',
      ride,
    );
    return true;
  }

  /// Sets total fare (creator only).
  Future<bool> setFare(
    Session session, {
    required int rideId,
    required String userId,
    required double totalFare,
  }) async {
    final ride = await Ride.db.findById(session, rideId);
    if (ride == null) return false;
    if (ride.creatorId != userId) {
      throw Exception('Only the creator can update the total fare.');
    }

    ride.totalFare = totalFare;
    await Ride.db.updateRow(session, ride);

    session.messages.postMessage(
      'ride_update_$rideId',
      ride,
    );
    return true;
  }
}
