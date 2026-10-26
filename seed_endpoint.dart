import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class SeedEndpoint extends Endpoint {
  /// Seeds initial campus, channels, and 20+ realistic demo users & rides.
  Future<bool> seedDemoData(Session session) async {
    // 1. Seed Campus
    var campus = await Campus.db.findFirstRow(
      session,
      where: (t) => t.emailDomain.equals('bennett.edu.in'),
    );

    if (campus == null) {
      campus = await Campus.db.insertRow(
        session,
        Campus(
          name: 'Bennett University',
          emailDomain: 'bennett.edu.in',
        ),
      );
    }

    final campusId = campus.id!;

    // 2. Seed Community Channels
    final existingChannels = await Channel.db.find(
      session,
      where: (t) => t.campusId.equals(campusId),
    );

    if (existingChannels.isEmpty) {
      final channelsToSeed = [
        Channel(campusId: campusId, name: '#general', description: 'General campus carpooling & chatter'),
        Channel(campusId: campusId, name: '#airport-runs', description: 'Indira Gandhi International (DEL) rides'),
        Channel(campusId: campusId, name: '#hackathons', description: 'Form teams on the way to hackathons!'),
        Channel(campusId: campusId, name: '#clubs', description: 'Events, fests and club travel groups'),
      ];
      for (final ch in channelsToSeed) {
        await Channel.db.insertRow(session, ch);
      }
    }

    // 3. Seed Demo Users & Rides
    final existingRides = await Ride.db.find(
      session,
      where: (t) => t.campusId.equals(campusId),
    );

    if (existingRides.length < 5) {
      final now = DateTime.now();

      final demoUsers = [
        UserProfile(
          userId: 'user_tanya',
          campusId: campusId,
          name: 'Tanya Verma',
          email: 'tanya.v@bennett.edu.in',
          branch: 'CSE',
          year: 3,
          gender: 'female',
          bio: 'UI/UX Designer & Frontend enthusiast. Love hackathons!',
          skills: ['designer', 'figma', 'frontend'],
          interests: ['hackathons', 'design', 'travel'],
          lookingFor: ['developer', 'ml'],
          createdAt: now,
        ),
        UserProfile(
          userId: 'user_kabir',
          campusId: campusId,
          name: 'Kabir Joshi',
          email: 'kabir.j@bennett.edu.in',
          branch: 'ECE',
          year: 2,
          gender: 'male',
          bio: 'Video editor and filmmaker. Need a developer for my media startup.',
          skills: ['editor', 'video editing', 'after effects'],
          interests: ['cinematography', 'startups', 'gaming'],
          lookingFor: ['developer', 'marketing'],
          createdAt: now,
        ),
        UserProfile(
          userId: 'user_ananya',
          campusId: campusId,
          name: 'Ananya Roy',
          email: 'ananya.r@bennett.edu.in',
          branch: 'Biotech',
          year: 3,
          gender: 'female',
          bio: 'Heading home for the weekend. Guitar player.',
          skills: ['content writer', 'guitarist'],
          interests: ['music', 'reading', 'travel'],
          lookingFor: ['singer', 'editor'],
          createdAt: now,
        ),
        UserProfile(
          userId: 'user_rohan',
          campusId: campusId,
          name: 'Rohan Gupta',
          email: 'rohan.g@bennett.edu.in',
          branch: 'CSE',
          year: 4,
          gender: 'male',
          bio: 'ML researcher & backend builder. Looking for startup co-founders.',
          skills: ['ml', 'python', 'backend'],
          interests: ['ai', 'startups', 'chess'],
          lookingFor: ['designer', 'frontend'],
          createdAt: now,
        ),
        UserProfile(
          userId: 'user_sneha',
          campusId: campusId,
          name: 'Sneha Patel',
          email: 'sneha.p@bennett.edu.in',
          branch: 'BBA',
          year: 2,
          gender: 'female',
          bio: 'Growth marketing & social media lead. Looking for video editor!',
          skills: ['marketing', 'growth', 'sales'],
          interests: ['startups', 'podcasts', 'fests'],
          lookingFor: ['editor', 'video editing'],
          createdAt: now,
        ),
      ];

      for (final u in demoUsers) {
        final existingU = await UserProfile.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(u.userId),
        );
        if (existingU == null) {
          await UserProfile.db.insertRow(session, u);
        }
      }

      // Seed Demo Rides
      final demoRides = [
        Ride(
          campusId: campusId,
          creatorId: 'user_kabir',
          creatorName: 'Kabir Joshi',
          type: 'offer',
          origin: 'Campus',
          destination: 'Airport',
          departAt: now.add(Duration(hours: 2, minutes: 15)),
          seatsTotal: 4,
          seatsTaken: 2,
          totalFare: 1400.0,
          womenOnly: false,
          status: 'open',
          shareToken: 'trip_airport_kabir',
          createdAt: now,
        ),
        Ride(
          campusId: campusId,
          creatorId: 'user_tanya',
          creatorName: 'Tanya Verma',
          type: 'offer',
          origin: 'Campus',
          destination: 'City Centre',
          departAt: now.add(Duration(hours: 3)),
          seatsTotal: 3,
          seatsTaken: 1,
          totalFare: 600.0,
          womenOnly: true,
          status: 'open',
          shareToken: 'trip_city_tanya',
          createdAt: now,
        ),
        Ride(
          campusId: campusId,
          creatorId: 'user_rohan',
          creatorName: 'Rohan Gupta',
          type: 'offer',
          origin: 'Railway Station',
          destination: 'Campus',
          departAt: now.add(Duration(hours: 5)),
          seatsTotal: 4,
          seatsTaken: 1,
          totalFare: 800.0,
          womenOnly: false,
          status: 'open',
          shareToken: 'trip_rail_rohan',
          createdAt: now,
        ),
        Ride(
          campusId: campusId,
          creatorId: 'user_ananya',
          creatorName: 'Ananya Roy',
          type: 'offer',
          origin: 'Campus',
          destination: 'Airport',
          departAt: now.add(Duration(hours: 2, minutes: 25)),
          seatsTotal: 3,
          seatsTaken: 1,
          totalFare: 1350.0,
          womenOnly: true,
          status: 'open',
          shareToken: 'trip_airport_ananya',
          createdAt: now,
        ),
      ];

      for (final r in demoRides) {
        final insertedRide = await Ride.db.insertRow(session, r);
        await RideMember.db.insertRow(
          session,
          RideMember(
            rideId: insertedRide.id!,
            userId: r.creatorId,
            userName: r.creatorName,
            userGender: r.womenOnly ? 'female' : 'male',
            role: 'creator',
            joinedAt: now,
          ),
        );
      }
    }

    return true;
  }
}
