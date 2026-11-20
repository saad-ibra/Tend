import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tend/controllers/feed_controller.dart';
import 'package:tend/models/feed_article.dart';
import 'package:tend/repositories/feed_repository.dart';

class InMemoryFeedRepository implements FeedRepository {
  final List<FeedArticle> _articles = [];
  final Set<String> _bookmarkedIds = {};

  InMemoryFeedRepository({List<FeedArticle>? initialArticles}) {
    if (initialArticles != null) {
      _articles.addAll(initialArticles);
    }
  }

  @override
  Future<List<FeedArticle>> getArticles({String? category, String? searchQuery}) async {
    return _articles
        .map((a) => a.copyWith(isBookmarked: _bookmarkedIds.contains(a.id)))
        .where((a) {
          if (category != null && category.isNotEmpty && category != 'All') {
            if (a.category.toLowerCase() != category.toLowerCase()) return false;
          }
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            return a.title.toLowerCase().contains(q) ||
                a.excerpt.toLowerCase().contains(q);
          }
          return true;
        })
        .toList();
  }

  @override
  Future<void> toggleBookmark(String articleId) async {
    if (_bookmarkedIds.contains(articleId)) {
      _bookmarkedIds.remove(articleId);
    } else {
      _bookmarkedIds.add(articleId);
    }
  }

  @override
  Future<List<FeedArticle>> getBookmarkedArticles() async {
    return _articles.where((a) => _bookmarkedIds.contains(a.id)).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedArticle Model Tests', () {
    test('JSON serialization & deserialization', () {
      final article = FeedArticle(
        id: 'art_1',
        title: 'The Architecture of Stillness',
        excerpt: 'Why pauses anchor habits.',
        content: 'Long form content on intentionality.',
        author: 'Elena Vance',
        authorRole: 'Mindful Behaviorist',
        category: 'Stillness',
        readTimeMinutes: 3,
        publishedAt: DateTime(2026, 11, 15),
        isBookmarked: true,
      );

      final json = article.toJson();
      final restored = FeedArticle.fromJson(json);

      expect(restored.id, equals('art_1'));
      expect(restored.title, equals('The Architecture of Stillness'));
      expect(restored.category, equals('Stillness'));
      expect(restored.readTimeMinutes, equals(3));
      expect(restored.isBookmarked, isTrue);
    });
  });

  group('FeedController Tests', () {
    late InMemoryFeedRepository repo;
    late FeedController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = InMemoryFeedRepository(initialArticles: [
        FeedArticle(
          id: '1',
          title: 'Morning Light',
          excerpt: 'Photon reset for melatonin.',
          content: 'Circadian rhythm science.',
          author: 'Dr. Sarah',
          authorRole: 'Neurobiologist',
          category: 'Focus',
          readTimeMinutes: 3,
          publishedAt: DateTime.now(),
        ),
        FeedArticle(
          id: '2',
          title: 'The Architecture of Stillness',
          excerpt: 'Micro-pauses before habits.',
          content: 'Ergonomic stillness.',
          author: 'Elena',
          authorRole: 'Mindful Behaviorist',
          category: 'Stillness',
          readTimeMinutes: 4,
          publishedAt: DateTime.now(),
        ),
      ]);
      controller = FeedController(repository: repo);
    });

    test('Loads articles correctly', () async {
      await controller.loadArticles();
      expect(controller.articles.length, equals(2));
      expect(controller.isLoading, isFalse);
    });

    test('Filters articles by category', () async {
      await controller.setCategory('Focus');
      expect(controller.articles.length, equals(1));
      expect(controller.articles.first.title, equals('Morning Light'));
    });

    test('Searches articles by keyword', () async {
      await controller.setSearchQuery('stillness');
      expect(controller.articles.length, equals(1));
      expect(controller.articles.first.id, equals('2'));
    });

    test('Toggles article bookmark', () async {
      await controller.loadArticles();
      expect(controller.bookmarkedCount, equals(0));

      await controller.toggleBookmark('1');
      expect(controller.bookmarkedCount, equals(1));
      expect(controller.articles.firstWhere((a) => a.id == '1').isBookmarked, isTrue);

      controller.toggleBookmarkFilter();
      expect(controller.showOnlyBookmarks, isTrue);
      expect(controller.articles.length, equals(1));
    });
  });
}
