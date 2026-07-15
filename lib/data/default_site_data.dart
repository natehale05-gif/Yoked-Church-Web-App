import '../models/church_config.dart';
import '../models/site_data.dart';
import '../models/sermon.dart';
import '../models/church_event.dart';
import '../models/ministry.dart';
import '../models/staff_member.dart';
import '../models/service_time.dart';
import '../models/social_link.dart';
import '../models/giving_fund.dart';

/// The out-of-the-box demo church ("Circle Church"). Sellers can start from
/// this and re-brand everything from the admin panel.
class DefaultSiteData {
  const DefaultSiteData._();

  static SiteData build() {
    final now = DateTime.now();
    return SiteData(
      config: const ChurchConfig(
        churchName: 'Circle Church',
        tagline: 'Come as you are. Belong here.',
        logoInitials: 'CC',
        primaryColorHex: '#FF6C5CE7',
        secondaryColorHex: '#FF00CEC9',
        accentColorHex: '#FFFDCB6E',
        fontFamily: 'Poppins',
        cornerRadius: 28,
        darkMode: false,
        heroTitle: 'A place to belong,\nbelieve, and become.',
        heroSubtitle:
            'We are a community of ordinary people following Jesus together. '
            'Wherever you are on your journey, there is a seat for you here.',
        heroCtaLabel: 'Plan Your Visit',
        heroCtaUrl: 'https://example.com/visit',
        welcomeTitle: "We're so glad you're here",
        welcomeBody:
            'Whether you have been part of a church your whole life or have '
            'never stepped inside one, Circle Church is a place where you can '
            'ask questions, build friendships, and grow in faith at your own '
            'pace. Join us this weekend — we saved you a seat.',
        aboutTitle: 'Our Story',
        aboutBody:
            'Circle Church began in 2009 with a handful of families meeting in '
            'a living room. Today we gather each week across our campuses, but '
            'our heart is the same: to love God, love people, and serve our '
            'city. We believe church is not a building but a family gathered '
            'around the good news of Jesus.',
        missionStatement:
            'To help people find and follow Jesus in everyday life.',
        beliefs: [
          'We believe the Bible is the inspired word of God.',
          'We believe in one God — Father, Son, and Holy Spirit.',
          'We believe salvation is a free gift of grace through faith in Jesus.',
          'We believe the church exists to love God and serve people.',
        ],
        address: '1200 Grace Avenue, Springfield, USA',
        phone: '(555) 018-2049',
        email: 'hello@circlechurch.example',
        mapUrl: 'https://maps.google.com/?q=1200+Grace+Avenue',
        liveStreamUrl: 'https://youtube.com/@example/live',
        givingTitle: 'Generosity changes everything',
        givingBody:
            'Your generosity fuels everything God is doing in and through '
            'Circle Church — from Sunday gatherings to caring for our city. '
            'Thank you for giving cheerfully.',
        primaryGiveUrl: 'https://example.com/give',
        givingFunds: [
          GivingFund(
            id: 'fund-general',
            name: 'General Fund',
            description:
                'Supports the day-to-day ministry and mission of the church.',
            url: 'https://example.com/give/general',
          ),
          GivingFund(
            id: 'fund-missions',
            name: 'Missions',
            description: 'Supports local and global outreach partners.',
            url: 'https://example.com/give/missions',
          ),
          GivingFund(
            id: 'fund-building',
            name: 'Building Fund',
            description: 'Helps us create space for our growing community.',
            url: 'https://example.com/give/building',
          ),
        ],
        serviceTimes: [
          ServiceTime(
            id: 'svc-1',
            name: 'Sunday Gathering',
            day: 'Sunday',
            time: '9:00 AM',
            location: 'Main Auditorium',
          ),
          ServiceTime(
            id: 'svc-2',
            name: 'Sunday Gathering',
            day: 'Sunday',
            time: '11:00 AM',
            location: 'Main Auditorium',
          ),
          ServiceTime(
            id: 'svc-3',
            name: 'Midweek Prayer',
            day: 'Wednesday',
            time: '7:00 PM',
            location: 'The Chapel',
          ),
        ],
        socialLinks: [
          SocialLink(
              id: 's1',
              platform: 'instagram',
              url: 'https://instagram.com/example'),
          SocialLink(
              id: 's2',
              platform: 'facebook',
              url: 'https://facebook.com/example'),
          SocialLink(
              id: 's3',
              platform: 'youtube',
              url: 'https://youtube.com/@example'),
        ],
        footerNote:
            'Circle Church is a 501(c)(3) non-profit. All gifts are tax-deductible.',
      ),
      sermons: [
        Sermon(
          id: 'sm-1',
          title: 'The God Who Runs',
          speaker: 'Pastor Daniel Reyes',
          series: 'Prodigal',
          date: now.subtract(const Duration(days: 3)),
          scripture: 'Luke 15:11-32',
          description:
              'A fresh look at the parable of the prodigal son and the '
              'relentless love of the Father.',
          mediaUrl: 'https://youtube.com/watch?v=example1',
        ),
        Sermon(
          id: 'sm-2',
          title: 'When You Feel Far',
          speaker: 'Pastor Daniel Reyes',
          series: 'Prodigal',
          date: now.subtract(const Duration(days: 10)),
          scripture: 'Psalm 139',
          description:
              'God is closer than you think, even in the seasons that feel '
              'the most distant.',
          mediaUrl: 'https://youtube.com/watch?v=example2',
        ),
        Sermon(
          id: 'sm-3',
          title: 'Rhythms of Rest',
          speaker: 'Pastor Amara Okafor',
          series: 'Unhurried',
          date: now.subtract(const Duration(days: 17)),
          scripture: 'Matthew 11:28-30',
          description:
              'Learning the unforced rhythms of grace in a hurried world.',
          mediaUrl: 'https://youtube.com/watch?v=example3',
        ),
      ],
      events: [
        ChurchEvent(
          id: 'ev-1',
          title: 'Community Night',
          start: now.add(const Duration(days: 4, hours: 18)),
          end: now.add(const Duration(days: 4, hours: 20)),
          location: 'The Commons',
          category: 'Community',
          description:
              'Dinner, worship, and connection for the whole family. Bring a '
              'friend and a dish to share!',
          registrationUrl: 'https://example.com/events/community-night',
        ),
        ChurchEvent(
          id: 'ev-2',
          title: 'Serve the City Day',
          start: now.add(const Duration(days: 12, hours: 9)),
          end: now.add(const Duration(days: 12, hours: 13)),
          location: 'Downtown Springfield',
          category: 'Outreach',
          description:
              'A morning of hands-on service projects across our city. All '
              'ages welcome.',
          registrationUrl: 'https://example.com/events/serve',
        ),
        ChurchEvent(
          id: 'ev-3',
          title: 'Baptism Sunday',
          start: now.add(const Duration(days: 19, hours: 11)),
          location: 'Main Auditorium',
          category: 'Worship',
          description:
              'Celebrate with those taking their next step of faith through '
              'baptism.',
        ),
      ],
      ministries: [
        Ministry(
          id: 'min-kids',
          name: 'Circle Kids',
          icon: 'child_care',
          leader: 'Jenna Powell',
          description:
              'Safe, fun, and faith-filled environments for birth through 5th '
              'grade every weekend.',
        ),
        Ministry(
          id: 'min-youth',
          name: 'Circle Students',
          icon: 'school',
          leader: 'Marcus Lee',
          description:
              'Middle and high schoolers growing in faith and friendship.',
        ),
        Ministry(
          id: 'min-groups',
          name: 'Small Groups',
          icon: 'groups',
          leader: 'Priya Nair',
          description:
              'Life is better together. Find your people in a group near you.',
        ),
        Ministry(
          id: 'min-worship',
          name: 'Worship & Arts',
          icon: 'music_note',
          leader: 'David Kim',
          description:
              'Using our gifts in music, tech, and creativity to serve the '
              'church.',
        ),
        Ministry(
          id: 'min-care',
          name: 'Care & Prayer',
          icon: 'volunteer_activism',
          leader: 'Susan Bright',
          description:
              'Walking with people through hardship with prayer and practical '
              'support.',
        ),
        Ministry(
          id: 'min-outreach',
          name: 'City Outreach',
          icon: 'diversity_3',
          leader: 'Tom Alvarez',
          description:
              'Loving our neighbors and serving the vulnerable in our city.',
        ),
      ],
      staff: [
        StaffMember(
          id: 'st-1',
          name: 'Daniel Reyes',
          role: 'Lead Pastor',
          bio:
              'Daniel and his wife Maria planted Circle Church in 2009. He loves '
              'preaching, strong coffee, and his three kids.',
          email: 'daniel@circlechurch.example',
        ),
        StaffMember(
          id: 'st-2',
          name: 'Amara Okafor',
          role: 'Teaching Pastor',
          bio:
              'Amara leads our teaching team and has a passion for helping '
              'people understand the Bible.',
          email: 'amara@circlechurch.example',
        ),
        StaffMember(
          id: 'st-3',
          name: 'Jenna Powell',
          role: 'Family Pastor',
          bio:
              'Jenna oversees Circle Kids and Students, championing the next '
              'generation.',
          email: 'jenna@circlechurch.example',
        ),
      ],
    );
  }
}
