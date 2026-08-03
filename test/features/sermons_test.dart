import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoked_church_app/features/sermons/application/sermon_providers.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon.dart';
import 'package:yoked_church_app/features/sermons/domain/sermon_series.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('Sermon.matches', () {
    final sermon = testSermon(
      title: 'Rest for the Weary',
      speaker: 'Pastor John Miller',
      seriesName: 'Yoked',
      scripture: 'Matthew 11:28-30',
    );

    test('empty query matches everything', () {
      expect(sermon.matches(''), isTrue);
      expect(sermon.matches('   '), isTrue);
    });

    test('matches on title, speaker, series, and scripture, case-insensitively', () {
      expect(sermon.matches('weary'), isTrue);
      expect(sermon.matches('MILLER'), isTrue);
      expect(sermon.matches('yoked'), isTrue);
      expect(sermon.matches('Matthew'), isTrue);
    });

    test('does not match unrelated text', () {
      expect(sermon.matches('genesis'), isFalse);
    });
  });

  group('filteredSermonsProvider', () {
    late ProviderContainer container;

    ProviderContainer makeContainer(List<Sermon> sermons, List<SermonSeries> series) {
      final c = ProviderContainer(overrides: fakeOverrides(sermons: sermons, series: series));
      addTearDown(c.dispose);
      return c;
    }

    test('hides unpublished sermons from the public list', () async {
      container = makeContainer([
        testSermon(id: 'a', title: 'Published One'),
        testSermon(id: 'b', title: 'Draft One', published: false),
      ], const []);

      await container.read(allSermonsProvider.future);
      final visible = container.read(publishedSermonsProvider).requireValue;

      expect(visible.map((s) => s.title), ['Published One']);
    });

    test('narrows by search query', () async {
      container = makeContainer([
        testSermon(id: 'a', title: 'Rest for the Weary'),
        testSermon(id: 'b', title: 'Faith Over Fear'),
      ], const []);
      await container.read(allSermonsProvider.future);

      container.read(sermonSearchQueryProvider.notifier).state = 'fear';

      expect(container.read(filteredSermonsProvider).requireValue.map((s) => s.title), ['Faith Over Fear']);
    });

    test('narrows by series filter, and combines with search', () async {
      container = makeContainer([
        testSermon(id: 'a', title: 'Rest', seriesId: 'yoked', seriesName: 'Yoked'),
        testSermon(id: 'b', title: 'Shepherd', seriesId: 'yoked', seriesName: 'Yoked'),
        testSermon(id: 'c', title: 'Anchor', seriesId: 'anchored', seriesName: 'Anchored'),
      ], const []);
      await container.read(allSermonsProvider.future);

      container.read(sermonSeriesFilterProvider.notifier).state = 'yoked';
      expect(container.read(filteredSermonsProvider).requireValue.length, 2);

      container.read(sermonSearchQueryProvider.notifier).state = 'shepherd';
      expect(container.read(filteredSermonsProvider).requireValue.map((s) => s.title), ['Shepherd']);
    });

    test('sorts newest first', () async {
      container = makeContainer([
        testSermon(id: 'old', title: 'Older', date: DateTime(2026, 1, 1)),
        testSermon(id: 'new', title: 'Newer', date: DateTime(2026, 6, 1)),
      ], const []);

      final sermons = await container.read(allSermonsProvider.future);
      expect(sermons.map((s) => s.title), ['Newer', 'Older']);
    });
  });
}
