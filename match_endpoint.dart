import 'dart:math';
import '../generated/protocol.dart';
import '../logic/matcher.dart';
import 'package:serverpod/serverpod.dart';

class MatchEndpoint extends Endpoint {
  /// Finds rides matching route, time window, and ranks them by skill overlap score.
  Future<List<MatchedRide>> findMatches(
    Session session, {
    required int campusId,
    required String origin,
    required String destination,
    required DateTime departAt,
    required int seatsNeeded,
    required bool womenOnly,
    required String requesterUserId,
  }) async {
    final requester = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(requesterUserId),
    );

    final requesterGender = requester?.gender ?? (womenOnly ? 'female' : 'male');

    // Retrieve open rides for this campus
    final candidateRides = await Ride.db.find(
      session,
      where: (t) => t.campusId.equals(campusId) & t.status.equals('open'),
      orderBy: (t) => t.departAt,
    );

    final matchedList = <MatchedRide>[];

    for (final ride in candidateRides) {
      if (ride.creatorId == requesterUserId) continue; // Don't match own ride

      final passes = RideMatcher.passesHardFilter(
        ride: ride,
        campusId: campusId,
        origin: origin,
        destination: destination,
        departAt: departAt,
        seatsNeeded: seatsNeeded,
        requesterWomenOnly: womenOnly,
        requesterGender: requesterGender,
      );

      if (!passes) continue;

      // Get members of this ride
      final members = await RideMember.db.find(
        session,
        where: (t) => t.rideId.equals(ride.id!),
      );

      int maxScore = 0;
      List<String> topReasons = ['Route & schedule match'];

      if (requester != null) {
        for (final member in members) {
          final memberProfile = await UserProfile.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(member.userId),
          );

          if (memberProfile != null) {
            final scoreResult = RideMatcher.calculateScore(
              me: requester,
              candidate: memberProfile,
            );
            if (scoreResult.score >= maxScore) {
              maxScore = scoreResult.score;
              topReasons = scoreResult.reasons;
            }
          }
        }
      }

      double? farePerHead;
      if (ride.totalFare != null) {
        final count = max(1, ride.seatsTaken);
        farePerHead = double.parse((ride.totalFare! / count).toStringAsFixed(2));
      }

      matchedList.add(
        MatchedRide(
          ride: ride,
          score: maxScore,
          whyMatched: topReasons,
          farePerHead: farePerHead,
        ),
      );
    }

    // Sort descending by score, tie-break by smaller time difference
    matchedList.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      final diffA = (a.ride.departAt.difference(departAt).inMinutes).abs();
      final diffB = (b.ride.departAt.difference(departAt).inMinutes).abs();
      return diffA.compareTo(diffB);
    });

    return matchedList;
  }
}
