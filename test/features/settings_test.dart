import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/app/theme.dart';
import 'package:yoked_church_app/core/config/church_settings.dart';
import 'package:yoked_church_app/core/config/contrast.dart';
import 'package:yoked_church_app/core/config/settings_providers.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('BrandColors parsing', () {
    test('accepts #RRGGBB', () {
      final colors = BrandColors.fromMap({'primary': '#112233'});
      expect(colors.primary, const Color(0xFF112233));
    });

    test('accepts RRGGBB without the hash', () {
      expect(BrandColors.fromMap({'accent': 'AABBCC'}).accent, const Color(0xFFAABBCC));
    });

    test('accepts #AARRGGBB', () {
      expect(BrandColors.fromMap({'primary': '#80112233'}).primary, const Color(0x80112233));
    });

    test('falls back on garbage rather than throwing', () {
      final colors = BrandColors.fromMap({'primary': 'not-a-color', 'accent': null});
      expect(colors.primary, BrandColors.fallback.primary);
      expect(colors.accent, BrandColors.fallback.accent);
    });

    test('round-trips through toMap', () {
      const original = BrandColors(
        primary: Color(0xFF1B3A4B),
        accent: Color(0xFFC9A24B),
        background: Color(0xFFF7F5F0),
      );
      expect(BrandColors.fromMap(original.toMap()).primary, original.primary);
      expect(BrandColors.fromMap(original.toMap()).accent, original.accent);
    });
  });

  group('ChurchSettings', () {
    test('survives a completely empty map', () {
      final settings = ChurchSettings.fromMap(const {});
      expect(settings.churchName, isNotEmpty);
      expect(settings.serviceTimes, isEmpty);
      expect(settings.features.sermons, isTrue);
    });

    test('round-trips through toMap/fromMap', () {
      final original = testSettings(churchName: 'Grace Chapel');
      final restored = ChurchSettings.fromMap(original.toMap());

      expect(restored.churchName, 'Grace Chapel');
      expect(restored.serviceTimes.single.day, 'Sunday');
      expect(restored.contact.email, 'test@example.org');
      expect(restored.social.givingUrl, 'https://example.org/give');
    });

    test('feature flags can be toggled by key', () {
      const flags = FeatureFlags();
      expect(flags.copyWithEntry('kidsCheckIn', false).kidsCheckIn, isFalse);
      expect(flags.copyWithEntry('kidsCheckIn', false).sermons, isTrue);
    });
  });

  group('theme derives from settings', () {
    test('brand colors flow into ThemeData', () {
      final settings = testSettings().copyWith(
        colors: const BrandColors(
          primary: Color(0xFF223344),
          accent: Color(0xFFAA9900),
          background: Color(0xFFFAFAFA),
        ),
      );

      final theme = buildTheme(settings);

      expect(theme.colorScheme.primary, const Color(0xFF223344));
      expect(theme.colorScheme.secondary, const Color(0xFFAA9900));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
    });

    test('changing settings changes the theme provider output', () async {
      final container = ProviderContainer(
        overrides: fakeOverrides(
          settings: testSettings().copyWith(
            colors: const BrandColors(primary: Colors.red, accent: Colors.green, background: Colors.white),
          ),
        ),
      );
      addTearDown(container.dispose);

      await container.read(churchSettingsProvider.future);
      expect(container.read(themeProvider).colorScheme.primary, Colors.red);
    });
  });

  /// The theme a church actually gets, rather than the numbers behind it.
  group('the theme a church gets', () {
    test('a button label is chosen for readability, not assumed white', () {
      // The default accent is a mid gold. White on it is 2.4:1, which is
      // what every primary button in the app used to be.
      final theme = buildTheme(testSettings(colors: BrandColors.fallback));
      final foreground = theme.elevatedButtonTheme.style?.foregroundColor
          ?.resolve(const <WidgetState>{});

      expect(foreground, isNotNull);
      expect(
        contrastRatio(foreground!, BrandColors.fallback.accent),
        greaterThanOrEqualTo(readableContrast),
      );
    });

    test('and white where white is what reads', () {
      // A dark accent should keep white text - the fix is a choice, not
      // a blanket switch to black.
      const dark = BrandColors(
        primary: Color(0xFF1B3A4B),
        accent: Color(0xFF14212B),
        background: Color(0xFFF7F5F0),
      );
      final foreground = buildTheme(testSettings(colors: dark))
          .elevatedButtonTheme
          .style
          ?.foregroundColor
          ?.resolve(const <WidgetState>{});

      expect(foreground, Colors.white);
    });
  });
}
