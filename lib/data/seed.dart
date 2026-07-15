import '../models/app_user.dart';
import '../models/attendance.dart';
import '../models/member.dart';
import '../models/serving.dart';
import '../models/site_content.dart';
import 'auth_hash.dart';

/// Default website content used the first time the app runs (and as the
/// starting point in the Site Editor).
SiteContent defaultSiteContent() => SiteContent(
      churchName: 'Grace City Church',
      shortName: 'Grace City',
      tagline: 'A place to belong, believe, and become.',
      heroHeadline: 'You are welcome here.',
      heroSubhead:
          'We are a warm, family church in the heart of the city — gathering '
          'each week to worship God, grow in faith, and love our neighbors.',
      addressLine1: '1200 Riverside Avenue',
      addressLine2: 'Springfield, IL 62704',
      phone: '(555) 019-2200',
      email: 'hello@gracecitychurch.org',
      mapUrl:
          'https://maps.google.com/?q=1200+Riverside+Avenue+Springfield+IL',
      giveUrl: 'https://gracecitychurch.org/give',
      instagramUrl: 'https://instagram.com',
      facebookUrl: 'https://facebook.com',
      youtubeUrl: 'https://youtube.com',
      accentColor: 0xFFC6A15B,
      serviceTimes: [
        ServiceTime(day: 'Sunday', time: '9:00 AM', label: 'Morning Gathering'),
        ServiceTime(day: 'Sunday', time: '11:00 AM', label: 'Second Gathering'),
        ServiceTime(day: 'Wednesday', time: '7:00 PM', label: 'Midweek Prayer'),
      ],
      whatToExpect: [
        ValuePoint(
          iconKey: 'people',
          title: 'A friendly welcome',
          body:
              'Look for our team in blue lanyards at the door. They will help '
              'you find your way and answer any questions.',
        ),
        ValuePoint(
          iconKey: 'music',
          title: 'Heartfelt worship',
          body:
              'Our gatherings last about 75 minutes, with live music and a '
              'clear, encouraging message from the Bible.',
        ),
        ValuePoint(
          iconKey: 'kids',
          title: 'Kids are cared for',
          body:
              'Safe, fun, age-appropriate environments for newborns through '
              '5th grade during every Sunday gathering.',
        ),
      ],
      values: [
        ValuePoint(
          iconKey: 'heart',
          title: 'Love First',
          body:
              'We lead with grace and treat every person with dignity and '
              'warmth.',
        ),
        ValuePoint(
          iconKey: 'book',
          title: 'Rooted in Scripture',
          body:
              'The Bible shapes how we live, teach, and make decisions '
              'together.',
        ),
        ValuePoint(
          iconKey: 'community',
          title: 'Better Together',
          body: 'Life change happens in community, not on our own.',
        ),
        ValuePoint(
          iconKey: 'give',
          title: 'Generous Living',
          body: 'We give our time, talent, and resources to serve our city.',
        ),
      ],
      ministries: [
        Ministry(
          id: 'min_kids',
          name: 'Kids',
          forWho: 'Birth – 5th Grade',
          description:
              'A safe and joyful place where children learn about Jesus '
              'through play, stories, and songs.',
          iconKey: 'toys',
        ),
        Ministry(
          id: 'min_students',
          name: 'Students',
          forWho: '6th – 12th Grade',
          description:
              'Middle and high schoolers build real friendships and a faith '
              'that lasts, Wednesday nights and beyond.',
          iconKey: 'games',
        ),
        Ministry(
          id: 'min_young',
          name: 'Young Adults',
          forWho: 'Ages 18 – 30',
          description:
              'Navigating faith, work, and relationships together in a '
              'generation that longs for authenticity.',
          iconKey: 'coffee',
        ),
        Ministry(
          id: 'min_groups',
          name: 'Groups',
          forWho: 'Everyone',
          description:
              'Small groups meet in homes across the city to share life, '
              'pray, and grow closer to God.',
          iconKey: 'groups',
        ),
        Ministry(
          id: 'min_worship',
          name: 'Worship',
          forWho: 'Musicians & Creatives',
          description:
              'Use your gifts on our vocal, band, and production teams to '
              'help people encounter God.',
          iconKey: 'piano',
        ),
        Ministry(
          id: 'min_outreach',
          name: 'Outreach',
          forWho: 'Serving the City',
          description:
              'Partnering with local schools, shelters, and families to '
              'bring practical hope to our neighbors.',
          iconKey: 'handshake',
        ),
      ],
      leaders: [
        Person(
          id: 'ldr_david',
          name: 'Pastor David Miller',
          role: 'Lead Pastor',
          bio:
              'David and his wife Sarah planted Grace City in 2009 with a '
              'heart to see the city changed by the love of Jesus.',
        ),
        Person(
          id: 'ldr_sarah',
          name: 'Sarah Miller',
          role: 'Pastor of Community',
          bio:
              'Sarah leads our groups and care ministries, helping people '
              'find real belonging and support.',
        ),
        Person(
          id: 'ldr_marcus',
          name: 'Marcus Lee',
          role: 'Worship Pastor',
          bio:
              'Marcus leads our worship teams and creative arts, crafting '
              'moments for people to meet with God.',
        ),
        Person(
          id: 'ldr_priya',
          name: 'Priya Anand',
          role: 'Kids & Family Director',
          bio:
              'Priya oversees our next generation, building safe and fun '
              'environments where kids love to be.',
        ),
      ],
      sermons: [
        Sermon(
          id: 'srm_1',
          title: 'Rooted: Finding Steady Ground',
          series: 'Rooted',
          speaker: 'Pastor David Miller',
          date: 'July 6, 2026',
          description:
              'How to build a life that stays steady when everything around '
              'you feels shaky.',
        ),
        Sermon(
          id: 'srm_2',
          title: 'The Practice of Rest',
          series: 'Rhythms',
          speaker: 'Sarah Miller',
          date: 'June 29, 2026',
          description:
              'Rediscovering the gift of Sabbath in a world that never stops.',
        ),
        Sermon(
          id: 'srm_3',
          title: 'Everyday Generosity',
          series: 'Rhythms',
          speaker: 'Pastor David Miller',
          date: 'June 22, 2026',
          description:
              'Small, joyful habits of giving that shape a generous heart.',
        ),
      ],
      events: [
        ChurchEvent(
          id: 'evt_sun',
          title: 'Sunday Gatherings',
          date: 'Every Sunday',
          time: '9:00 & 11:00 AM',
          location: 'Main Auditorium',
          description:
              'Join us for worship, teaching, and community. Kids programs '
              'run during both services.',
        ),
        ChurchEvent(
          id: 'evt_serve',
          title: 'City Serve Day',
          date: 'August 15, 2026',
          time: '9:00 AM – 1:00 PM',
          location: 'Meet at the Church',
          description:
              'A morning of serving our neighbors through local projects '
              'across the city. Families welcome.',
        ),
        ChurchEvent(
          id: 'evt_lunch',
          title: 'Newcomers Lunch',
          date: 'August 23, 2026',
          time: '12:30 PM',
          location: 'The Commons',
          description:
              'New here? Grab a free lunch, meet the team, and learn about '
              'next steps.',
        ),
        ChurchEvent(
          id: 'evt_worship',
          title: 'Worship Night',
          date: 'September 5, 2026',
          time: '7:00 PM',
          location: 'Main Auditorium',
          description:
              'An extended evening of worship and prayer for the whole '
              'church family. Everyone is invited.',
        ),
      ],
    );

/// Demo members so the dashboard has data on first run.
List<Member> defaultMembers() => [
      Member(
        id: 'mbr_alex',
        firstName: 'Alex',
        lastName: 'Johnson',
        email: 'alex.johnson@example.com',
        phone: '(555) 200-1010',
        status: MemberStatus.member,
        household: 'Johnson',
        joined: DateTime(2021, 3, 14),
      ),
      Member(
        id: 'mbr_maria',
        firstName: 'Maria',
        lastName: 'Garcia',
        email: 'maria.garcia@example.com',
        phone: '(555) 200-1020',
        status: MemberStatus.member,
        household: 'Garcia',
        joined: DateTime(2020, 8, 2),
      ),
      Member(
        id: 'mbr_james',
        firstName: 'James',
        lastName: 'Wright',
        email: 'james.wright@example.com',
        phone: '(555) 200-1030',
        status: MemberStatus.regular,
        household: 'Wright',
        joined: DateTime(2023, 1, 22),
      ),
      Member(
        id: 'mbr_grace',
        firstName: 'Grace',
        lastName: 'Kim',
        email: 'member@church.app',
        phone: '(555) 200-1040',
        status: MemberStatus.member,
        household: 'Kim',
        joined: DateTime(2019, 11, 5),
      ),
      Member(
        id: 'mbr_daniel',
        firstName: 'Daniel',
        lastName: 'Smith',
        email: 'daniel.smith@example.com',
        phone: '(555) 200-1050',
        status: MemberStatus.visitor,
        household: 'Smith',
        joined: DateTime(2026, 6, 28),
      ),
      Member(
        id: 'mbr_hannah',
        firstName: 'Hannah',
        lastName: 'Lopez',
        email: 'hannah.lopez@example.com',
        phone: '(555) 200-1060',
        status: MemberStatus.regular,
        household: 'Lopez',
        joined: DateTime(2024, 4, 18),
      ),
    ];

/// Demo login accounts. Passwords are shown on the login screen for the demo.
List<AppUser> defaultUsers() => [
      AppUser(
        id: 'usr_staff',
        name: 'Pastor David Miller',
        email: 'staff@church.app',
        role: UserRole.staff,
        passwordHash: hashPassword('church123'),
      ),
      AppUser(
        id: 'usr_member',
        name: 'Grace Kim',
        email: 'member@church.app',
        role: UserRole.member,
        passwordHash: hashPassword('welcome123'),
        memberId: 'mbr_grace',
      ),
    ];

List<ServingTeam> defaultServingTeams() => [
      ServingTeam(
        id: 'team_welcome',
        name: 'Welcome Team',
        description:
            'Greet people at the doors, help them find seats, and make '
            'everyone feel at home.',
        iconKey: 'people',
      ),
      ServingTeam(
        id: 'team_worship',
        name: 'Worship Team',
        description: 'Lead the church in worship through music and production.',
        iconKey: 'music',
      ),
      ServingTeam(
        id: 'team_kids',
        name: 'Kids Team',
        description:
            'Care for and teach our youngest members in safe, fun rooms.',
        iconKey: 'kids',
      ),
      ServingTeam(
        id: 'team_hospitality',
        name: 'Hospitality',
        description: 'Serve coffee and refreshments and create a warm space.',
        iconKey: 'coffee',
      ),
    ];

List<ServingSlot> defaultServingSlots() {
  final now = DateTime.now();
  DateTime nextSunday([int weeks = 0]) {
    var d = now.add(Duration(days: (7 - now.weekday % 7) % 7));
    if (d.isBefore(now)) d = d.add(const Duration(days: 7));
    return DateTime(d.year, d.month, d.day).add(Duration(days: 7 * weeks));
  }

  return [
    ServingSlot(
      id: 'slot_1',
      teamId: 'team_welcome',
      title: 'Door Greeter',
      date: nextSunday(),
      time: '8:30 AM',
      needed: 3,
      memberIds: ['mbr_alex'],
    ),
    ServingSlot(
      id: 'slot_2',
      teamId: 'team_worship',
      title: 'Vocalist',
      date: nextSunday(),
      time: '8:00 AM',
      needed: 2,
      memberIds: ['mbr_maria', 'mbr_grace'],
    ),
    ServingSlot(
      id: 'slot_3',
      teamId: 'team_kids',
      title: 'Nursery Helper',
      date: nextSunday(),
      time: '9:00 AM',
      needed: 4,
      memberIds: ['mbr_hannah'],
    ),
    ServingSlot(
      id: 'slot_4',
      teamId: 'team_hospitality',
      title: 'Coffee Bar',
      date: nextSunday(1),
      time: '8:30 AM',
      needed: 2,
      memberIds: [],
    ),
    ServingSlot(
      id: 'slot_5',
      teamId: 'team_welcome',
      title: 'Info Desk',
      date: nextSunday(1),
      time: '8:30 AM',
      needed: 2,
      memberIds: [],
    ),
  ];
}

List<AttendanceRecord> defaultAttendance() {
  final now = DateTime.now();
  DateTime past(int weeksAgo) {
    final d = now.subtract(Duration(days: 7 * weeksAgo));
    return DateTime(d.year, d.month, d.day);
  }

  return [
    AttendanceRecord(
      id: 'att_1',
      date: past(3),
      serviceLabel: 'Sunday Morning',
      presentMemberIds: ['mbr_alex', 'mbr_maria', 'mbr_grace', 'mbr_james'],
      visitorCount: 12,
    ),
    AttendanceRecord(
      id: 'att_2',
      date: past(2),
      serviceLabel: 'Sunday Morning',
      presentMemberIds: ['mbr_alex', 'mbr_maria', 'mbr_grace', 'mbr_hannah'],
      visitorCount: 9,
    ),
    AttendanceRecord(
      id: 'att_3',
      date: past(1),
      serviceLabel: 'Sunday Morning',
      presentMemberIds: [
        'mbr_alex',
        'mbr_maria',
        'mbr_grace',
        'mbr_james',
        'mbr_hannah',
      ],
      visitorCount: 15,
    ),
  ];
}
