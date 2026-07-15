import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SITE CONFIG
/// ---------------------------------------------------------------------------
/// This is the single place to customize the whole website for a new church.
/// Change the values below (name, contact info, service times, colors, and the
/// content of each section) and the entire site updates automatically.
///
/// Everything is plain Dart data — no design knowledge required to edit it.
/// ---------------------------------------------------------------------------

class SiteConfig {
  const SiteConfig._();

  // --- Church identity -----------------------------------------------------
  static const String churchName = 'Grace City Church';
  static const String tagline = 'A place to belong, believe, and become.';
  static const String shortName = 'Grace City';

  // A one-line welcome shown large on the home page hero.
  static const String heroHeadline = 'You are welcome here.';
  static const String heroSubhead =
      'We are a warm, family church in the heart of the city — '
      'gathering each week to worship God, grow in faith, and love our neighbors.';

  // --- Contact & location --------------------------------------------------
  static const String addressLine1 = '1200 Riverside Avenue';
  static const String addressLine2 = 'Springfield, IL 62704';
  static const String phone = '(555) 019-2200';
  static const String email = 'hello@gracecitychurch.org';
  static const String mapUrl =
      'https://maps.google.com/?q=1200+Riverside+Avenue+Springfield+IL';

  // --- Social links (leave blank to hide) ----------------------------------
  static const String instagramUrl = 'https://instagram.com';
  static const String facebookUrl = 'https://facebook.com';
  static const String youtubeUrl = 'https://youtube.com';

  // --- Primary call to action ----------------------------------------------
  static const String giveUrl = 'https://gracecitychurch.org/give';

  // --- Service times -------------------------------------------------------
  static const List<ServiceTime> serviceTimes = [
    ServiceTime(day: 'Sunday', time: '9:00 AM', label: 'Morning Gathering'),
    ServiceTime(day: 'Sunday', time: '11:00 AM', label: 'Second Gathering'),
    ServiceTime(day: 'Wednesday', time: '7:00 PM', label: 'Midweek Prayer'),
  ];

  // --- Home: "What to expect" quick points ---------------------------------
  static const List<ValuePoint> whatToExpect = [
    ValuePoint(
      icon: Icons.emoji_people_outlined,
      title: 'A friendly welcome',
      body:
          'Look for our team in blue lanyards at the door. They will help you '
          'find your way, save you a seat, and answer any questions.',
    ),
    ValuePoint(
      icon: Icons.music_note_outlined,
      title: 'Heartfelt worship',
      body:
          'Our gatherings last about 75 minutes, with live music and a clear, '
          'encouraging message from the Bible.',
    ),
    ValuePoint(
      icon: Icons.child_care_outlined,
      title: 'Kids are cared for',
      body:
          'Safe, fun, age-appropriate environments for newborns through '
          '5th grade, running during every Sunday gathering.',
    ),
  ];

  // --- Home: core values / beliefs ----------------------------------------
  static const List<ValuePoint> values = [
    ValuePoint(
      icon: Icons.favorite_border,
      title: 'Love First',
      body: 'We lead with grace and treat every person with dignity and warmth.',
    ),
    ValuePoint(
      icon: Icons.menu_book_outlined,
      title: 'Rooted in Scripture',
      body: 'The Bible shapes how we live, teach, and make decisions together.',
    ),
    ValuePoint(
      icon: Icons.diversity_3_outlined,
      title: 'Better Together',
      body: 'Life change happens in community, not on our own.',
    ),
    ValuePoint(
      icon: Icons.volunteer_activism_outlined,
      title: 'Generous Living',
      body: 'We give our time, talent, and resources to serve our city.',
    ),
  ];

  // --- Ministries ----------------------------------------------------------
  static const List<Ministry> ministries = [
    Ministry(
      name: 'Kids',
      forWho: 'Birth – 5th Grade',
      description:
          'A safe and joyful place where children learn about Jesus through '
          'play, stories, and songs.',
      icon: Icons.toys_outlined,
    ),
    Ministry(
      name: 'Students',
      forWho: '6th – 12th Grade',
      description:
          'Middle and high schoolers build real friendships and a faith that '
          'lasts, Wednesday nights and beyond.',
      icon: Icons.sports_esports_outlined,
    ),
    Ministry(
      name: 'Young Adults',
      forWho: 'Ages 18 – 30',
      description:
          'Navigating faith, work, and relationships together in a generation '
          'that longs for authenticity.',
      icon: Icons.coffee_outlined,
    ),
    Ministry(
      name: 'Groups',
      forWho: 'Everyone',
      description:
          'Small groups meet in homes across the city to share life, pray, '
          'and grow closer to God.',
      icon: Icons.groups_outlined,
    ),
    Ministry(
      name: 'Worship',
      forWho: 'Musicians & Creatives',
      description:
          'Use your gifts on our vocal, band, and production teams to help '
          'people encounter God.',
      icon: Icons.piano_outlined,
    ),
    Ministry(
      name: 'Outreach',
      forWho: 'Serving the City',
      description:
          'Partnering with local schools, shelters, and families to bring '
          'practical hope to our neighbors.',
      icon: Icons.handshake_outlined,
    ),
  ];

  // --- Leadership / staff (lots of room for people photos) -----------------
  static const List<Person> leaders = [
    Person(
      name: 'Pastor David Miller',
      role: 'Lead Pastor',
      bio:
          'David and his wife Sarah planted Grace City in 2009 with a heart to '
          'see the city changed by the love of Jesus.',
    ),
    Person(
      name: 'Sarah Miller',
      role: 'Pastor of Community',
      bio:
          'Sarah leads our groups and care ministries, helping people find '
          'real belonging and support.',
    ),
    Person(
      name: 'Marcus Lee',
      role: 'Worship Pastor',
      bio:
          'Marcus leads our worship teams and creative arts, crafting moments '
          'for people to meet with God.',
    ),
    Person(
      name: 'Priya Anand',
      role: 'Kids & Family Director',
      bio:
          'Priya oversees our next generation, building safe and fun '
          'environments where kids love to be.',
    ),
  ];

  // --- Recent sermons ------------------------------------------------------
  static const List<Sermon> sermons = [
    Sermon(
      title: 'Rooted: Finding Steady Ground',
      series: 'Rooted',
      speaker: 'Pastor David Miller',
      date: 'July 6, 2026',
      description:
          'How to build a life that stays steady when everything around you '
          'feels shaky.',
    ),
    Sermon(
      title: 'The Practice of Rest',
      series: 'Rhythms',
      speaker: 'Sarah Miller',
      date: 'June 29, 2026',
      description:
          'Rediscovering the gift of Sabbath in a world that never stops.',
    ),
    Sermon(
      title: 'Everyday Generosity',
      series: 'Rhythms',
      speaker: 'Pastor David Miller',
      date: 'June 22, 2026',
      description:
          'Small, joyful habits of giving that shape a generous heart.',
    ),
  ];

  // --- Upcoming events -----------------------------------------------------
  static const List<ChurchEvent> events = [
    ChurchEvent(
      title: 'Sunday Gatherings',
      date: 'Every Sunday',
      time: '9:00 & 11:00 AM',
      location: 'Main Auditorium',
      description:
          'Join us for worship, teaching, and community. Kids programs run '
          'during both services.',
    ),
    ChurchEvent(
      title: 'City Serve Day',
      date: 'August 15, 2026',
      time: '9:00 AM – 1:00 PM',
      location: 'Meet at the Church',
      description:
          'A morning of serving our neighbors through local projects across '
          'the city. Families welcome.',
    ),
    ChurchEvent(
      title: 'Newcomers Lunch',
      date: 'August 23, 2026',
      time: '12:30 PM',
      location: 'The Commons',
      description:
          'New here? Grab a free lunch, meet the team, and learn about next '
          'steps at Grace City.',
    ),
    ChurchEvent(
      title: 'Worship Night',
      date: 'September 5, 2026',
      time: '7:00 PM',
      location: 'Main Auditorium',
      description:
          'An extended evening of worship and prayer for the whole church '
          'family. Everyone is invited.',
    ),
  ];
}

// ---------------------------------------------------------------------------
// Simple data models used by the config above.
// ---------------------------------------------------------------------------

class ServiceTime {
  final String day;
  final String time;
  final String label;
  const ServiceTime({
    required this.day,
    required this.time,
    required this.label,
  });
}

class ValuePoint {
  final IconData icon;
  final String title;
  final String body;
  const ValuePoint({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class Ministry {
  final String name;
  final String forWho;
  final String description;
  final IconData icon;
  const Ministry({
    required this.name,
    required this.forWho,
    required this.description,
    required this.icon,
  });
}

class Person {
  final String name;
  final String role;
  final String bio;

  /// Optional image path (asset or network URL). When null, a tasteful
  /// placeholder is shown so there is always room for a real photo.
  final String? imageUrl;
  const Person({
    required this.name,
    required this.role,
    required this.bio,
    this.imageUrl,
  });
}

class Sermon {
  final String title;
  final String series;
  final String speaker;
  final String date;
  final String description;
  const Sermon({
    required this.title,
    required this.series,
    required this.speaker,
    required this.date,
    required this.description,
  });
}

class ChurchEvent {
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  const ChurchEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });
}
