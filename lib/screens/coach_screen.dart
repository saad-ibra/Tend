import 'package:flutter/material.dart';
import '../controllers/coach_controller.dart';
import '../models/coach_action.dart';
import '../models/coach_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/coach_message_bubble.dart';

class CoachScreen extends StatefulWidget {
  final CoachController controller;
  final VoidCallback? onOpenProfile;

  const CoachScreen({
    super.key,
    required this.controller,
    this.onOpenProfile,
  });

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickPrompts = [
    'Weekly Summary',
    'Consistency Check',
    'Suggest New Rhythm',
    'Why am I struggling?',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
    widget.controller.loadConversation();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    await widget.controller.sendMessage(text);
  }

  Future<void> _handleAction(CoachAction action, bool isAccept) async {
    final messages = widget.controller.messages;
    final msg = messages.firstWhere(
      (m) => m.action?.id == action.id,
      orElse: () => messages.last,
    );
    if (isAccept) {
      final success = await widget.controller.executeAction(msg, action);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rhythm updated: ${action.title}'),
            backgroundColor: AppColors.espresso,
          ),
        );
      }
    } else {
      await widget.controller.dismissAction(msg, action);
    }
  }

  void _showRenameDialog(CoachSession session) {
    final titleController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Rename Conversation', style: AppTypography.headlineSm()),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Conversation Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                widget.controller.renameSession(session.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(CoachSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Conversation', style: AppTypography.headlineSm()),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This conversation history cannot be recovered.',
          style: AppTypography.bodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.deleteSession(session.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showConversationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeSessions = widget.controller.activeSessions;
            final archivedSessions = widget.controller.archivedSessions;
            final currentId = widget.controller.currentSession?.id;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollCtrl) {
                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Conversations',
                              style: const TextStyle(
                                fontFamily: 'Newsreader',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.controller.createNewSession();
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('New Chat'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tabs: Active & Archived
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.outline,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Active (${activeSessions.length})'),
                          Tab(text: 'Archived (${archivedSessions.length})'),
                        ],
                      ),
                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Active Tab
                            _buildSessionList(
                              sessions: activeSessions,
                              currentId: currentId,
                              scrollCtrl: scrollCtrl,
                              isArchivedTab: false,
                              setSheetState: setSheetState,
                            ),
                            // Archived Tab
                            _buildSessionList(
                              sessions: archivedSessions,
                              currentId: currentId,
                              scrollCtrl: scrollCtrl,
                              isArchivedTab: true,
                              setSheetState: setSheetState,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSessionList({
    required List<CoachSession> sessions,
    required String? currentId,
    required ScrollController scrollCtrl,
    required bool isArchivedTab,
    required StateSetter setSheetState,
  }) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isArchivedTab ? Icons.archive_outlined : Icons.chat_bubble_outline,
                size: 36,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                isArchivedTab ? 'No archived conversations' : 'No active conversations',
                style: AppTypography.bodyMd(color: AppColors.outline),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isSelected = session.id == currentId;

        return Material(
          color: isSelected
              ? AppColors.caramelCream.withValues(alpha: 0.4)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              widget.controller.switchSession(session.id);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  width: isSelected ? 1.4 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    session.isPinned
                        ? Icons.push_pin
                        : (isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline),
                    size: 18,
                    color: session.isPinned
                        ? AppColors.primary
                        : (isSelected ? AppColors.primary : AppColors.outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                session.title,
                                style: AppTypography.bodyMd().copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (session.isPinned)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.messages.length} message${session.messages.length == 1 ? '' : 's'} • ${_formatDate(session.updatedAt)}',
                          style: AppTypography.labelSm(color: AppColors.outline).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.outline),
                    onSelected: (action) async {
                      if (action == 'pin') {
                        await widget.controller.togglePinSession(session.id);
                        setSheetState(() {});
                      } else if (action == 'rename') {
                        _showRenameDialog(session);
                      } else if (action == 'archive') {
                        await widget.controller.toggleArchiveSession(session.id);
                        setSheetState(() {});
                      } else if (action == 'delete') {
                        _showDeleteDialog(session);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              session.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                              size: 16,
                              color: AppColors.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(session.isPinned ? 'Unpin' : 'Pin to Top'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'rename',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.onSurface),
                            SizedBox(width: 8),
                            Text('Rename'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              session.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                              size: 16,
                              color: AppColors.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(session.isArchived ? 'Unarchive' : 'Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.currentSession;
    final messages = widget.controller.messages;
    final isThinking = widget.controller.isThinking;
    final isCloudConfigured = widget.controller.coachService.isCloudConfigured;
    final activeLabel = widget.controller.coachService.activeModelLabel;
    final lastApiError = widget.controller.coachService.lastError;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.onSurface),
        title: GestureDetector(
          onTap: _showConversationsSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      session?.title ?? 'AI Habit Coach',
                      style: AppTypography.headlineSm(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.outline),
                ],
              ),
              Text(
                'Mindful Reflection',
                style: AppTypography.labelSm(color: AppColors.outline).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.onSurface),
            tooltip: 'Conversations (${widget.controller.activeSessions.length})',
            onPressed: _showConversationsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.onSurface),
            tooltip: 'New Conversation',
            onPressed: () => widget.controller.createNewSession(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.outline),
            onSelected: (val) {
              if (session == null) return;
              if (val == 'rename') {
                _showRenameDialog(session);
              } else if (val == 'pin') {
                widget.controller.togglePinSession(session.id);
              } else if (val == 'archive') {
                widget.controller.toggleArchiveSession(session.id);
              } else if (val == 'clear') {
                widget.controller.clearHistory();
              }
            },
            itemBuilder: (context) => [
              if (session != null) ...[
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        session.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(session.isPinned ? 'Unpin Conversation' : 'Pin Conversation'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Rename Conversation'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        session.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(session.isArchived ? 'Unarchive' : 'Archive Conversation'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'loading',
                  enabled: false,
                  child: Text('Loading conversation...'),
                ),
              ],
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // API Notice / Error Banner
          if (lastApiError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.amber.withValues(alpha: 0.18),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastApiError,
                      style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(fontSize: 11),
                    ),
                  ),
                  if (widget.onOpenProfile != null &&
                      (lastApiError.contains('Profile') || lastApiError.contains('key')))
                    TextButton(
                      onPressed: widget.onOpenProfile,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Setup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: AppColors.outline),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        widget.controller.coachService.clearError();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Conversation Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length + (isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isThinking) {
                  return _buildThinkingIndicator();
                }
                final msg = messages[index];
                return CoachMessageBubble(
                  message: msg,
                  onAcceptAction: (act) => _handleAction(act, true),
                  onDismissAction: (act) => _handleAction(act, false),
                );
              },
            ),
          ),

          // Quick Suggestion Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt),
                  labelStyle: AppTypography.labelSm(color: AppColors.primary),
                  backgroundColor: AppColors.surfaceContainerLowest,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: isThinking ? null : () => _handleSend(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Model Name Indicator Bar (Moved to bottom near text box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onOpenProfile,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCloudConfigured
                          ? AppColors.secondaryContainer.withValues(alpha: 0.5)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCloudConfigured
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.borderSubtle,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCloudConfigured ? Icons.cloud_done_outlined : Icons.offline_bolt_outlined,
                          size: 12,
                          color: isCloudConfigured ? AppColors.onSecondaryContainer : AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCloudConfigured ? AppColors.onSecondaryContainer : AppColors.outline,
                          ),
                        ),
                        if (widget.onOpenProfile != null) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: isCloudConfigured ? AppColors.onSecondaryContainer : AppColors.outline,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!isCloudConfigured && widget.onOpenProfile != null)
                  GestureDetector(
                    onTap: widget.onOpenProfile,
                    child: Text(
                      'Add Groq/Gemini key',
                      style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Message Input Field Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: isThinking ? null : (_) => _handleSend(),
                      style: AppTypography.bodyMd(),
                      decoration: InputDecoration(
                        hintText: 'Ask your coach anything about your habits...',
                        hintStyle: AppTypography.bodySm(color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                      onPressed: isThinking ? null : () => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                ),
                SizedBox(width: 10),
                Text(
                  'Coach is reflecting...',
                  style: TextStyle(fontSize: 12, color: AppColors.outline, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
