class FeedArticle {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String author;
  final String authorRole;
  final String category; // 'Stillness', 'Rhythm', 'Focus', 'Rest'
  final int readTimeMinutes;
  final DateTime publishedAt;
  bool isBookmarked;

  FeedArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.author,
    required this.authorRole,
    required this.category,
    required this.readTimeMinutes,
    required this.publishedAt,
    this.isBookmarked = false,
  });

  FeedArticle copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? content,
    String? author,
    String? authorRole,
    String? category,
    int? readTimeMinutes,
    DateTime? publishedAt,
    bool? isBookmarked,
  }) {
    return FeedArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      author: author ?? this.author,
      authorRole: authorRole ?? this.authorRole,
      category: category ?? this.category,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      publishedAt: publishedAt ?? this.publishedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'content': content,
        'author': author,
        'author_role': authorRole,
        'category': category,
        'read_time_minutes': readTimeMinutes,
        'published_at': publishedAt.toIso8601String(),
        'is_bookmarked': isBookmarked,
      };

  factory FeedArticle.fromJson(Map<String, dynamic> json) {
    return FeedArticle(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Reflection',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? 'Tend Editor',
      authorRole: json['author_role'] as String? ?? 'Mindful Practitioner',
      category: json['category'] as String? ?? 'Stillness',
      readTimeMinutes: (json['read_time_minutes'] as num?)?.toInt() ?? 3,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : DateTime.now(),
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }
}
