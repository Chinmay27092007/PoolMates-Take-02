import '../generated/protocol.dart';

class MatchScoreResult {
  final int score;
  final List<String> reasons;

  const MatchScoreResult({required this.score, required this.reasons});
}

class RideMatcher {
  static const int timeWindowMinutes = 30;

  static Set<String> normalizeTags(List<String> tags) {
    return tags
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  /// Calculates the skill score between requester and candidate member.
  /// a = |candidate.skills ∩ me.lookingFor|
  /// b = |me.skills ∩ candidate.lookingFor|
  /// c = |candidate.interests ∩ me.interests|
  /// score = min(100, 40*a + 30*b + 10*c)
  static MatchScoreResult calculateScore({
    required UserProfile me,
    required UserProfile candidate,
  }) {
    final mySkills = normalizeTags(me.skills);
    final myInterests = normalizeTags(me.interests);
    final myLookingFor = normalizeTags(me.lookingFor);

    final candidateSkills = normalizeTags(candidate.skills);
    final candidateInterests = normalizeTags(candidate.interests);
    final candidateLookingFor = normalizeTags(candidate.lookingFor);

    final a = candidateSkills.intersection(myLookingFor);
    final b = mySkills.intersection(candidateLookingFor);
    final c = candidateInterests.intersection(myInterests);

    final rawScore = 40 * a.length + 30 * b.length + 10 * c.length;
    final score = rawScore > 100 ? 100 : rawScore;

    final reasons = <String>[];
    for (final skill in a) {
      reasons.add("Has: ${_capitalize(skill)} — you're looking for it");
    }
    for (final looking in b) {
      reasons.add("Looking for: ${_capitalize(looking)} — you have it");
    }
    for (final interest in c) {
      reasons.add("Shared interest: ${_capitalize(interest)}");
    }

    if (reasons.isEmpty) {
      reasons.add("Route & schedule match");
    }

    return MatchScoreResult(score: score, reasons: reasons);
  }

  /// Checks hard filters for candidate ride.
  static bool passesHardFilter({
    required Ride ride,
    required int campusId,
    required String origin,
    required String destination,
    required DateTime departAt,
    required int seatsNeeded,
    required bool requesterWomenOnly,
    required String requesterGender,
  }) {
    // 1. Same campus
    if (ride.campusId != campusId) return false;

    // 2. Origin & destination equal (case-insensitive, normalized)
    if (ride.origin.trim().toLowerCase() != origin.trim().toLowerCase()) {
      return false;
    }
    if (ride.destination.trim().toLowerCase() != destination.trim().toLowerCase()) {
      return false;
    }

    // 3. departAt within +-30 min
    final diffMinutes = ride.departAt.difference(departAt).inMinutes.abs();
    if (diffMinutes > timeWindowMinutes) return false;

    // 4. Status open and free seats >= seatsNeeded
    final freeSeats = ride.seatsTotal - ride.seatsTaken;
    if (ride.status.toLowerCase() != 'open' || freeSeats < seatsNeeded) {
      return false;
    }

    // 5. Women-only gating
    final isRequesterFemale = requesterGender.trim().toLowerCase() == 'female';
    if (ride.womenOnly && !isRequesterFemale) {
      return false; // Male cannot see or join women-only ride
    }
    if (requesterWomenOnly && !ride.womenOnly) {
      return false; // Requester looking only for women-only rides
    }

    return true;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
