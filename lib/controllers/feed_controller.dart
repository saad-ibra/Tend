import 'package:flutter/foundation.dart';
import '../models/feed_article.dart';
import '../repositories/feed_repository.dart';

class FeedController extends ChangeNotifier {
  final FeedRepository repository;

  List<FeedArticle> _articles = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showOnlyBookmarks = false;

  FeedController({required this.repository});

  List<FeedArticle> get articles {
    if (_showOnlyBookmarks) {
      return _articles.where((a) => a.isBookmarked).toList();
    }
    return _articles;
  }

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get showOnlyBookmarks => _showOnlyBookmarks;
  int get bookmarkedCount => _articles.where((a) => a.isBookmarked).length;

  Future<void> loadArticles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _articles = await repository.getArticles(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
    } catch (e) {
      debugPrint('Error loading feed articles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadArticles();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await loadArticles();
  }

  void toggleBookmarkFilter() {
    _showOnlyBookmarks = !_showOnlyBookmarks;
    notifyListeners();
  }

  Future<void> toggleBookmark(String articleId) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final current = _articles[index];
      _articles[index] = current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
    }

    try {
      await repository.toggleBookmark(articleId);
    } catch (e) {
      debugPrint('Error persisting bookmark: $e');
      // Rollback on failure
      if (index != -1) {
        final current = _articles[index];
        _articles[index] = current.copyWith(isBookmarked: !current.isBookmarked);
        notifyListeners();
      }
    }
  }
}
