import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_article.dart';
import 'feed_repository.dart';

class LocalFeedRepository implements FeedRepository {
  static const _bookmarkStorageKey = 'tend_feed_bookmarks_v1';
  final Set<String> _bookmarkedIds = {};
  bool _initialized = false;

  final List<FeedArticle> _seedArticles = [
    FeedArticle(
      id: 'article_1',
      title: 'The Architecture of Stillness: Why 5-Minute Pauses Anchor Habits',
      excerpt:
          'When we rush between demands, our nervous system remains in high friction. Micro-pauses restore the baseline needed to sustain intentional action.',
      content: '''
Most habit failures are not failures of willpower; they are failures of physiological margin. When we schedule our days with back-to-back demands, our cognitive load spikes, and the default response to any newly introduced rhythm is immediate resistance.

In Japanese aesthetics, 'Ma' represents the negative space—the silent interval between notes that gives music its beauty. In behavioral psychology, micro-stillness serves an identical purpose.

By carving out 3 to 5 minutes of deliberate inaction before beginning your chosen rhythm, you signal to your prefrontal cortex that you are acting from autonomy rather than reaction. 

Try this tomorrow: Before opening your notebook or tying your walking shoes, sit by a window without a screen for exactly 180 seconds. Observe your breath. Notice how the activation energy required to begin plummets once the mental chatter subsides.
''',
      author: 'Elena Vance',
      authorRole: 'Mindful Behaviorist',
      category: 'Stillness',
      readTimeMinutes: 3,
      publishedAt: DateTime(2026, 11, 15),
    ),
    FeedArticle(
      id: 'article_2',
      title: 'Friction & Grace: Reducing Activation Energy for Morning Routines',
      excerpt:
          'Willpower is an exhaustible fuel. Sustainable rhythms rely instead on physical environments arranged with gentle anticipation.',
      content: '''
The easiest way to preserve a rhythm is to make non-compliance slightly more troublesome than adherence. In ergonomics, this is known as managing friction vectors.

If your intention is morning stillness or stretching, place your mat beside your bed before sleeping. If your goal is reading 10 pages of prose, leave your book resting directly on your morning tea mug.

Conversely, introduce gentle friction to destructive compulsive loops. Charge your handheld device across the room or outside the bed chamber entirely. 

Tend approaches habits with grace: when an obstacle arises, we do not blame ourselves. We simply inspect the physical room and adjust the friction until movement feels natural and unforced.
''',
      author: 'Marcus Chen',
      authorRole: 'Architectural Ergonomist',
      category: 'Rhythm',
      readTimeMinutes: 4,
      publishedAt: DateTime(2026, 11, 14),
    ),
    FeedArticle(
      id: 'article_3',
      title: 'The Circadian Reset: Morning Light as an Organic Alarm',
      excerpt:
          'Before coffee, before checking notifications, direct natural sunlight anchors your internal master clock and regulates nocturnal melatonin.',
      content: '''
The suprachiasmatic nucleus (SCN) in your hypothalamus is biological hardware tuned to photon intensity. Fluorescent lighting or smartphone glass does not emit sufficient lux to signal a full biological dawn.

Viewing natural outdoor light within thirty minutes of waking triggers a timed cortisol release that sharpens attention, lifts mood, and initiates a countdown timer for melatonin synthesis 14 hours later.

You do not need direct sunlight on bare skin for hours; 10 to 15 minutes of looking toward the morning horizon on a clear morning—or 20 minutes on an overcast day—is sufficient to synchronize your cellular clocks.

Pair this with a gentle habit: step outside with warm water, breathe the crisp air, and let the morning light tend to your circadian rhythms naturally.
''',
      author: 'Dr. Sarah Lindqvist',
      authorRole: 'Neurobiologist',
      category: 'Focus',
      readTimeMinutes: 3,
      publishedAt: DateTime(2026, 11, 12),
    ),
    FeedArticle(
      id: 'article_4',
      title: 'Rhythm Recovery: Moving Past the Guilt of Broken Streaks',
      excerpt:
          'The myth of unbroken streaks often causes more psychological harm than missed days. A true rhythm breathes and recovers without self-condemnation.',
      content: '''
In digital culture, the gamified 'streak counter' has created a toxic fragility: miss one day due to illness or family obligations, and the entire edifice feels ruined. Many practitioners abandon their practice precisely when their streak resets to zero.

Living organisms do not operate in continuous, unyielding lines. The tides ebb; trees shed leaves; the heart contracts and relaxes in cyclic balance.

Tend reframes streaks as living rhythms. Missing one day is an organic pause, not a moral failure. The golden rule of sustainable behavior is simple: never miss two consecutive cycles. If today was interrupted by unforeseen storms, acknowledge it, rest without guilt, and resume tomorrow with quiet confidence.
''',
      author: 'Elena Vance',
      authorRole: 'Mindful Behaviorist',
      category: 'Rest',
      readTimeMinutes: 5,
      publishedAt: DateTime(2026, 11, 10),
    ),
    FeedArticle(
      id: 'article_5',
      title: 'Digital Minimalism in Practice: Guarding Attention from Compulsive Loops',
      excerpt:
          'Attention is the raw currency of presence. Here is how to reclaim two quiet hours every evening from algorithmic feeds.',
      content: '''
We rarely choose to scroll social media for two hours; we choose to unlock our phone for two seconds to check a single text, and an engineering team in California captures our visual cortex for the subsequent 120 minutes.

Reclaiming attention requires intentional architectural boundaries:
1. Greyscale mode: Remove the hyper-stimulating saturation from your screen after 7:00 PM.
2. The Evening Hearth: Designate one room in your home—preferably the bedroom—as a sanctuary free of illuminated displays.
3. Replace rather than eliminate: If you strip away evening scrolling without offering a tactile alternative (such as loose-leaf herbal tea, journaling, or ambient acoustic music), the vacuum will inevitably pull you back into the feed.

Guard your evening attention as a precious garden.
''',
      author: 'Kaelen Mori',
      authorRole: 'Cultural Philosopher',
      category: 'Stillness',
      readTimeMinutes: 4,
      publishedAt: DateTime(2026, 11, 08),
    ),
    FeedArticle(
      id: 'article_6',
      title: 'The Breath as Anchor: Breathwork for Midday Reset',
      excerpt:
          'A three-minute physiological sigh downregulates sympathetic tone faster than any cognitive re-framing exercise.',
      content: '''
When stress mounts during afternoon tasks, our respiratory rate involuntarily shallows, leading to carbon dioxide retention and heightened sympathetic arousal.

The physiological sigh—two rapid inhales through the nose followed by a long, slow sighing exhalation through the mouth—immediately re-inflates collapsed alveoli and triggers vagal nerve stimulation.

Three consecutive cycles take less than 40 seconds. Practice this between deep work sessions or right after a demanding conversation to cleanse mental fatigue and restore clarity.
''',
      author: 'Dr. Sarah Lindqvist',
      authorRole: 'Neurobiologist',
      category: 'Rest',
      readTimeMinutes: 2,
      publishedAt: DateTime(2026, 11, 05),
    ),
  ];

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookmarkStorageKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString());
        _bookmarkedIds.addAll(list);
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<void> _persistBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookmarkStorageKey, jsonEncode(_bookmarkedIds.toList()));
  }

  @override
  Future<List<FeedArticle>> getArticles({String? category, String? searchQuery}) async {
    await _ensureInitialized();

    return _seedArticles
        .map((article) => article.copyWith(
              isBookmarked: _bookmarkedIds.contains(article.id),
            ))
        .where((article) {
          if (category != null && category.isNotEmpty && category != 'All') {
            if (article.category.toLowerCase() != category.toLowerCase()) {
              return false;
            }
          }
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final query = searchQuery.trim().toLowerCase();
            final matchesTitle = article.title.toLowerCase().contains(query);
            final matchesExcerpt = article.excerpt.toLowerCase().contains(query);
            final matchesAuthor = article.author.toLowerCase().contains(query);
            if (!matchesTitle && !matchesExcerpt && !matchesAuthor) {
              return false;
            }
          }
          return true;
        })
        .toList();
  }

  @override
  Future<void> toggleBookmark(String articleId) async {
    await _ensureInitialized();
    if (_bookmarkedIds.contains(articleId)) {
      _bookmarkedIds.remove(articleId);
    } else {
      _bookmarkedIds.add(articleId);
    }
    await _persistBookmarks();
  }

  @override
  Future<List<FeedArticle>> getBookmarkedArticles() async {
    final all = await getArticles();
    return all.where((article) => article.isBookmarked).toList();
  }
}
