import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/mesh_service.dart';
import '../theme/app_theme.dart';

/// Premium Mesh Chat Screen
/// WhatsApp-style bubbles with timestamps, connection status, and animations.
class MeshChatPage extends StatefulWidget {
  final String peerName;

  const MeshChatPage({
    super.key,
    required this.peerName,
  });

  @override
  State<MeshChatPage> createState() => _MeshChatPageState();
}

// ─── Message Model ────────────────────────────────────────────────────────────

class _MeshMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  _MeshMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────

class _MeshChatPageState extends State<MeshChatPage> {
  final MeshService _mesh = MeshService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_MeshMessage> _messages = [];
  MeshConnectionState _connectionState = MeshConnectionState.connected;
  late String _peerName;

  @override
  void initState() {
    super.initState();
    _connectionState = _mesh.connectionState;
    _peerName = widget.peerName;

    _mesh.onMessageReceived = (msg) {
      if (!mounted) return;
      setState(() {
        _messages.add(_MeshMessage(
          text: msg,
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    };

    _mesh.onConnectionStateChanged = (state) {
      if (mounted) setState(() => _connectionState = state);
    };

    _mesh.onPeerNameChanged = (newName) {
      if (mounted) setState(() => _peerName = newName);
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _mesh.onMessageReceived = null;
    _mesh.onConnectionStateChanged = null;
    _mesh.onPeerNameChanged = null;
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _mesh.sendMessage(text);
    setState(() {
      _messages.add(_MeshMessage(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });
    _controller.clear();
    _scrollToBottom();
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

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            center: Alignment.topRight,
            radius: 1.5,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            _buildConnectionBanner(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessagesList(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: const Color(0xFF0F172A).withOpacity(0.6),
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),

                // Name & status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _peerName.isNotEmpty ? _peerName : 'Peer Device',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _connectionStateLabel(),
                          key: ValueKey(_connectionState),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: _connectionStateColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                onSelected: (value) {
                  if (value == 'edit_name') _showEditNameDialog();
                },
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_name',
                    child: Row(
                      children: [
                        Icon(Icons.badge_rounded, color: Colors.blueAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Edit My Identity', style: TextStyle(color: Colors.white, fontSize: 14)),
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
  }

  Widget _buildConnectionBanner() {
    if (_connectionState == MeshConnectionState.connected) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _connectionStateColor().withOpacity(0.12),
      child: Text(
        _connectionState == MeshConnectionState.disconnected
            ? '⚠️  Connection lost. Messages may not be delivered.'
            : '⏳  Connecting…',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _connectionStateColor(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
            child: Icon(
              Icons.forum_rounded,
              size: 64,
              color: Colors.blueAccent.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Secure Offline Chat',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.peerName.isNotEmpty ? widget.peerName : "your peer"}.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final showDate = index == 0 ||
            !_isSameDay(_messages[index - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.timestamp),
            _MessageBubble(message: msg),
          ],
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.12, end: 0, duration: 250.ms);
      },
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              _formatDate(dt).toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.6),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Send button
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  
  void _showEditNameDialog() {
    final controller = TextEditingController(text: _mesh.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit My Identity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your nickname...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _mesh.updateUserName(controller.text.trim());
                if (mounted) setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _connectionStateLabel() {
    switch (_connectionState) {
      case MeshConnectionState.connected:
        return '● Connected';
      case MeshConnectionState.connecting:
        return '○ Connecting…';
      case MeshConnectionState.disconnected:
        return '○ Disconnected';
      default:
        return '';
    }
  }

  Color _connectionStateColor() {
    switch (_connectionState) {
      case MeshConnectionState.connected:
        return AppColors.safeGreen;
      case MeshConnectionState.connecting:
        return AppColors.alertOrange;
      case MeshConnectionState.disconnected:
        return AppColors.emergencyRed;
      default:
        return AppColors.textMuted;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Today';
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ─── Message Bubble Widget ────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _MeshMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final timeLabel = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 40 : 0,
            right: isMe ? 0 : 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [const Color(0xFF1E293B), const Color(0xFF334155).withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
            boxShadow: [
              if (isMe)
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Message text
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Timestamp
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all_rounded, size: 12, color: Colors.white.withOpacity(0.8)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}