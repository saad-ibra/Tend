class NoteItem {
  final String id;
  final String content;
  final DateTime createdAt;
  final String tag;
  final bool isAudio;

  NoteItem({
    required this.id,
    required this.content,
    required this.createdAt,
    this.tag = 'Thought',
    this.isAudio = false,
  });
}
