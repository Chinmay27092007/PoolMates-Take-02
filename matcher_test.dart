import 'package:test/test.dart';
import 'package:poolmates_server/src/generated/protocol.dart';
import 'package:poolmates_server/src/logic/matcher.dart';

void main() {
  group('RideMatcher Unit Tests', () {
    final now = DateTime.utc(2026, 10, 26, 10, 0);

    final me = UserProfile(
      userId: 'user_1',
      campusId: 1,
      name: 'Aarav Sharma',
      email: 'aarav@bennett.edu.in',
      branch: 'CSE',
      year: 3,
      gender: 'male',
      skills: ['developer', 'flutter'],
      interests: ['hackathons', 'startups'],
      lookingFor: ['editor', 'designer'],
      createdAt: now,
    );

    test('Skill overlap: calculates exact formula score = min(100, 40*a + 30*b + 10*c)', () {
      final candidate = UserProfile(
        userId: 'user_2',
        campusId: 1,
        name: 'Rohan Mehra',
        email: 'rohan@bennett.edu.in',
        branch: 'ECE',
        year: 2,
        gender: 'male',
        skills: ['editor'], // a = 1 (candidate has editor, me lookingFor editor) -> 40
        interests: ['hackathons'], // c = 1 (shared interest) -> 10
        lookingFor: ['developer'], // b = 1 (candidate lookingFor developer, me has developer) -> 30
        createdAt: now,
      );

      final result = RideMatcher.calculateScore(me: me, candidate: candidate);
      expect(result.score, equals(80)); // 40*1 + 30*1 + 10*1 = 80
      expect(result.reasons, contains("Has: Editor — you're looking for it"));
      expect(result.reasons, contains("Looking for: Developer — you have it"));
      expect(result.reasons, contains("Shared interest: Hackathons"));
    });

    test('Looking-for tag editor surfaces editor-skilled rider higher than non-editor', () {
      final editorRider = UserProfile(
        userId: 'cand_editor',
        campusId: 1,
        name: 'Priya',
        email: 'priya@bennett.edu.in',
        branch: 'BBA',
        year: 2,
        gender: 'female',
        skills: ['editor'],
        interests: ['music'],
        lookingFor: ['singer'],
        createdAt: now,
      );

      final otherRider = UserProfile(
        userId: 'cand_other',
        campusId: 1,
        name: 'Karan',
        email: 'karan@bennett.edu.in',
        branch: 'CSE',
        year: 1,
        gender: 'male',
        skills: ['robotics'],
        interests: ['chess'],
        lookingFor: ['gamer'],
        createdAt: now,
      );

      final scoreEditor = RideMatcher.calculateScore(me: me, candidate: editorRider);
      final scoreOther = RideMatcher.calculateScore(me: me, candidate: otherRider);

      expect(scoreEditor.score, greaterThan(scoreOther.score));
      expect(scoreEditor.score, equals(40));
      expect(scoreOther.score, equals(0));
    });

    test('Hard filter: departAt within +-30 min window', () {
      final rideInWindow = Ride(
        campusId: 1,
        creatorId: 'user_2',
        creatorName: 'Rohan',
        type: 'offer',
        origin: 'Campus',
        destination: 'Airport',
        departAt: now.add(Duration(minutes: 20)),
        seatsTotal: 4,
        seatsTaken: 1,
        totalFare: 1200,
        womenOnly: false,
        status: 'open',
        shareToken: 'token_1',
        createdAt: now,
      );

      final rideOutsideWindow = Ride(
        campusId: 1,
        creatorId: 'user_3',
        creatorName: 'Amit',
        type: 'offer',
        origin: 'Campus',
        destination: 'Airport',
        departAt: now.add(Duration(minutes: 45)),
        seatsTotal: 4,
        seatsTaken: 1,
        totalFare: 1200,
        womenOnly: false,
        status: 'open',
        shareToken: 'token_2',
        createdAt: now,
      );

      expect(
        RideMatcher.passesHardFilter(
          ride: rideInWindow,
          campusId: 1,
          origin: 'campus',
          destination: 'airport',
          departAt: now,
          seatsNeeded: 1,
          requesterWomenOnly: false,
          requesterGender: 'male',
        ),
        isTrue,
      );

      expect(
        RideMatcher.passesHardFilter(
          ride: rideOutsideWindow,
          campusId: 1,
          origin: 'campus',
          destination: 'airport',
          departAt: now,
          seatsNeeded: 1,
          requesterWomenOnly: false,
          requesterGender: 'male',
        ),
        isFalse,
      );
    });

    test('Hard filter: full ride is rejected when seats are insufficient', () {
      final fullRide = Ride(
        campusId: 1,
        creatorId: 'user_2',
        creatorName: 'Rohan',
        type: 'offer',
        origin: 'Campus',
        destination: 'Airport',
        departAt: now,
        seatsTotal: 4,
        seatsTaken: 4, // 0 free seats
        womenOnly: false,
        status: 'open',
        shareToken: 'token_full',
        createdAt: now,
      );

      expect(
        RideMatcher.passesHardFilter(
          ride: fullRide,
          campusId: 1,
          origin: 'Campus',
          destination: 'Airport',
          departAt: now,
          seatsNeeded: 1,
          requesterWomenOnly: false,
          requesterGender: 'male',
        ),
        isFalse,
      );
    });

    test('Hard filter: women-only gating rejects male user and protects privacy', () {
      final womenOnlyRide = Ride(
        campusId: 1,
        creatorId: 'user_girl',
        creatorName: 'Ananya',
        type: 'offer',
        origin: 'Campus',
        destination: 'City Centre',
        departAt: now,
        seatsTotal: 3,
        seatsTaken: 1,
        womenOnly: true,
        status: 'open',
        shareToken: 'token_women',
        createdAt: now,
      );

      // Male requester must fail
      expect(
        RideMatcher.passesHardFilter(
          ride: womenOnlyRide,
          campusId: 1,
          origin: 'Campus',
          destination: 'City Centre',
          departAt: now,
          seatsNeeded: 1,
          requesterWomenOnly: false,
          requesterGender: 'male',
        ),
        isFalse,
      );

      // Female requester must pass
      expect(
        RideMatcher.passesHardFilter(
          ride: womenOnlyRide,
          campusId: 1,
          origin: 'Campus',
          destination: 'City Centre',
          departAt: now,
          seatsNeeded: 1,
          requesterWomenOnly: true,
          requesterGender: 'female',
        ),
        isTrue,
      );
    });
  });
}
