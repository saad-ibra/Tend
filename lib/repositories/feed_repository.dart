import '../models/feed_article.dart';

abstract class FeedRepository {
  /// Fetches all feed articles with optional category and search query filters.
  Future<List<FeedArticle>> getArticles({String? category, String? searchQuery});

  /// Toggles bookmark state for the specified article.
  Future<void> toggleBookmark(String articleId);

  /// Fetches only bookmarked articles.
  Future<List<FeedArticle>> getBookmarkedArticles();
}
