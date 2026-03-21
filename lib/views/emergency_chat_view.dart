import 'package:flutter/material.dart';
import '../services/emergency_response_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';

/// Emergency Chat View
/// Text-based emergency guidance with category-specific AI assistance
class EmergencyChatView extends StatefulWidget {
  final EmergencyCategory initialCategory;

  const EmergencyChatView({
    super.key,
    this.initialCategory = EmergencyCategory.general,
  });

  @override
  State<EmergencyChatView> createState() => _EmergencyChatViewState();
}

class _EmergencyChatViewState extends State<EmergencyChatView> {
  late EmergencyResponseService _emergencyService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;
  String _streamingText = '';

  @override
  void initState() {
    super.initState();
    _emergencyService = EmergencyResponseService();
    _emergencyService.setCategory(widget.initialCategory);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _emergencyService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _isStreaming = true;
      _streamingText = '';
    });

    try {
      await for (final token in _emergencyService.streamEmergencyResponse(text)) {
        setState(() {
          _streamingText += token;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isStreaming = false;
        _streamingText = '';
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_emergencyService.currentCategory.title),
        actions: [
          PopupMenuButton<EmergencyCategory>(
            icon: const Icon(Icons.category),
            onSelected: (category) {
              setState(() {
                _emergencyService.setCategory(category);
              });
            },
            itemBuilder: (context) {
              return EmergencyCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(category.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(category.title),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _emergencyService.conversationHistory.length + (_isStreaming ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isStreaming && index == _emergencyService.conversationHistory.length) {
                  return _buildMessageBubble(
                    _streamingText,
                    false,
                    isStreaming: true,
                  );
                }
                
                final message = _emergencyService.conversationHistory[index];
                return _buildMessageBubble(message.text, message.isUser);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCategoryBanner() {
    final category = _emergencyService.currentCategory;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.emergencyRed.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, {bool isStreaming = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.emergencyRed
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: isUser
              ? null
              : Border.all(
                  color: AppColors.textMuted.withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isStreaming)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppColors.textMuted.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Describe the emergency...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                enabled: !_isStreaming,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _isStreaming ? null : _sendMessage,
              icon: Icon(
                _isStreaming ? Icons.stop : Icons.send,
                color: _isStreaming ? AppColors.textMuted : AppColors.emergencyRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
