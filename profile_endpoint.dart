import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class ProfileEndpoint extends Endpoint {
  /// Fetches profile for a user ID.
  Future<UserProfile?> getMe(Session session, String userId) async {
    return await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
  }

  /// Verifies campus domain and logs in or creates profile.
  Future<UserProfile> registerOrLogin(
    Session session, {
    required String email,
    required String name,
    required String branch,
    required int year,
    required String gender,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final parts = cleanEmail.split('@');
    if (parts.length != 2) {
      throw FormatException('Invalid email address format.');
    }
    final domain = parts[1];

    final campus = await Campus.db.findFirstRow(
      session,
      where: (t) => t.emailDomain.equals(domain),
    );

    if (campus == null) {
      throw Exception(
        'Email domain "@$domain" is not authorized. Only verified campus emails (e.g. bennett.edu.in) can join.',
      );
    }

    var profile = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.email.equals(cleanEmail),
    );

    if (profile == null) {
      profile = UserProfile(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}_${cleanEmail.hashCode.abs() % 1000}',
        campusId: campus.id!,
        name: name.trim().isEmpty ? cleanEmail.split('.').first : name.trim(),
        email: cleanEmail,
        branch: branch.trim().isEmpty ? 'CSE' : branch.trim(),
        year: year <= 0 ? 1 : year,
        gender: gender.trim().toLowerCase(),
        bio: 'Student at ${campus.name}',
        skills: ['Developer'],
        interests: ['Hackathons'],
        lookingFor: ['Designer'],
        createdAt: DateTime.now(),
      );
      profile = await UserProfile.db.insertRow(session, profile);
    }

    return profile;
  }

  /// Updates profile tags and info.
  Future<UserProfile> updateProfile(
    Session session, {
    required String userId,
    required String name,
    required String branch,
    required int year,
    required String gender,
    String? bio,
    required List<String> skills,
    required List<String> interests,
    required List<String> lookingFor,
  }) async {
    var profile = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (profile == null) {
      throw Exception('User profile not found for ID: $userId');
    }

    profile.name = name;
    profile.branch = branch;
    profile.year = year;
    profile.gender = gender.toLowerCase();
    profile.bio = bio;
    profile.skills = skills;
    profile.interests = interests;
    profile.lookingFor = lookingFor;

    return await UserProfile.db.updateRow(session, profile);
  }
}
