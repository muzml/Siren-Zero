import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'emergency_chat_view.dart';
import 'emergency_voice_view.dart';
import 'emergency_guide_view.dart';
import 'protocol_library_view.dart';
import 'mesh_device_discovery_view.dart';
import 'tactical_map_view.dart';

/// Siren-Zero Main Screen
/// Emergency-first UI for rapid access to life-saving guidance
class SirenZeroHomeView extends StatefulWidget {
  const SirenZeroHomeView({super.key});

  @override
  State<SirenZeroHomeView> createState() => _SirenZeroHomeViewState();
}

class _SirenZeroHomeViewState extends State<SirenZeroHomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  List<String> getSteps(String category) {
    final c = category.toLowerCase();

    if (c.contains("bleed")) {
      return [
        "Call 911 for severe bleeding",
        "Wear gloves if available",
        "Apply direct pressure",
        "Press firmly for 10 minutes",
        "Add more cloth if soaked",
        "Elevate injured area",
      ];
    }

    if (c.contains("breath")) {
      return [
        "Check responsiveness",
        "Call emergency services",
        "Start CPR (30 compressions)",
        "Give 2 rescue breaths",
        "Repeat until help arrives",
      ];
    }

    if (c.contains("unconscious")) {
      return [
        "Check responsiveness (tap and shout)",
        "Call emergency services immediately",
        "Check breathing for 10 seconds",
        "If breathing, place in recovery position",
        "Loosen tight clothing",
        "Monitor breathing continuously",
      ];
    }

    if (c.contains("burn")) {
      return [
        "Remove person from heat source",
        "Cool burn under running water (10–20 minutes)",
        "Remove tight items (rings, clothing)",
        "Cover with clean, non-stick cloth",
        "Do NOT apply ice or creams",
        "Seek medical help if severe",
      ];
    }

    return ["No steps available"];
  }

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkModelStatus() async {
    final modelService = Provider.of<ModelService>(context, listen: false);
    // Auto-load models if they're downloaded but not loaded
    final isDownloaded =
        await modelService.isModelDownloaded(ModelService.llmModelId);
    if (!modelService.isLLMLoaded && isDownloaded) {
      await modelService.downloadAndLoadLLM();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryGradient
              : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSystemStatusCard(),
                      const SizedBox(height: 20),
                      _buildMeshCard(),
                      const SizedBox(height: 28),
                      _buildSirenZeroCard(),
                      const SizedBox(height: 28),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildToolsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeshCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MeshDeviceDiscoveryView(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppColors.meshLightGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF38BDF8).withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // LEFT ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            // TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mesh Communication",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.lightTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Offline peer-to-peer survival network",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Text(
                        "TAP TO SCAN",
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.radar_rounded,
                          color: Color(0xFF38BDF8), size: 14),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppColors.lightTextSecondary,
                  size: 14),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.emergencyRed.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emergencyRed.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]),
            child: const Icon(Icons.emergency,
                color: AppColors.emergencyRed, size: 28),
          ),
          const SizedBox(width: 14),
          Text(
            "SIREN-ZERO",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: textColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            color: textColor,
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Consumer<ModelService>(
      builder: (context, modelService, child) {
        final isReady = modelService.isLLMLoaded;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B).withOpacity(0.6)
                    : Colors.white.withOpacity(0.85), // glass feel
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isReady
                      ? const Color(0xFF38BDF8).withOpacity(0.4)
                      : AppColors.warningYellow.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isReady
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : AppColors.warningYellow.withOpacity(0.15),
                    blurRadius: 25,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 🔷 ICON BOX
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            gradient: isReady
                                ? const LinearGradient(colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF3B82F6)
                                  ])
                                : LinearGradient(colors: [
                                    AppColors.warningYellow,
                                    AppColors.warningYellow.withOpacity(0.7)
                                  ]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: isReady
                                    ? const Color(0xFF38BDF8).withOpacity(0.4)
                                    : AppColors.warningYellow.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]),
                        child: Icon(
                          isReady
                              ? Icons.verified_rounded
                              : Icons.download_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 🔤 TEXT SECTION
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReady ? 'SYSTEM READY' : 'SETUP REQUIRED',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: isReady
                                        ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary)
                                        : AppColors.warningYellow,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isReady
                                  ? '100% Offline • All systems operational'
                                  : 'Download AI models to enable offline mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : AppColors.lightTextSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // ⚡ SETUP BUTTON
                      if (!isReady)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warningYellow,
                                AppColors.warningYellow.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showModelSetup(),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                child: Text(
                                  'SETUP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 🚨 ALERT BOX
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.emergencyRed.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.emergencyRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Always call emergency services when available (911)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.textPrimary
                                          : AppColors.lightTextPrimary,
                                      fontSize: 11.5,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSirenZeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.emergencyRed.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔴 TOP SECTION
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D55),
                      Color(0xFFE6003B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Chat with',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          SizedBox(height: 4),
                          Text(
                            'Siren Zero',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your personal AI emergency assistant 🚨',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TweenAnimationBuilder(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOutSine,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ⚪ BOTTOM SECTION
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B).withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 FIXED CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickChip(
                            "How to perform CPR?",
                            Icons.favorite,
                          ),
                          const SizedBox(width: 8),
                          _buildQuickChip(
                            "Treating burns",
                            Icons.local_fire_department,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 💬 INPUT BOX
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmergencyChatView(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF0F172A).withOpacity(0.8)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.2
                                        : 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Describe your emergency...',
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.4)
                                      : AppColors.lightTextMuted,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildIconBox(
                              Icons.image_rounded,
                              const Color(0xFF38BDF8),
                              _handleImageInput,
                            ),
                            const SizedBox(width: 8),
                            _buildIconBox(
                              Icons.mic_rounded,
                              const Color(0xFFFF9500),
                              _handleVoiceInput,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF2D55),
                                      Color(0xFFE6003B)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF2D55)
                                          .withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: _handleSendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔵 DOTS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedDot(),
                        const SizedBox(width: 6),
                        _buildAnimatedDot(delay: 200),
                        const SizedBox(width: 6),
                        _buildAnimatedDot(delay: 400),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildIconBox(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildQuickChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A).withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 🔥 key fix
        children: [
          Icon(icon, size: 16, color: AppColors.emergencyRed),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot({int delay = 0}) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _handleImageInput() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image input coming soon!')),
    );
  }

  void _handleVoiceInput() {
    // Navigate to voice view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyVoiceView(),
      ),
    );
  }

  void _handleSendMessage() {
    // Navigate to chat view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyChatView(),
      ),
    );
  }

  // ================= QUICK ACTION CARD =================

  Widget _buildQuickActionCard(Map<String, String> item, int index) {
    // ✅ SAFE EXTRACTION
    final String title = item['title'] ?? '';
    final String emoji = item['emoji'] ?? '';
    final String desc = item['desc'] ?? '';

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleQuickAction(title),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12), // 🔥 reduced padding
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardGradient
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textMuted.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

// 🔥 FIXED LAYOUT (NO OVERFLOW)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔝 TOP ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(
                            fontSize: 20), // 🔥 slightly smaller
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.infoBlue,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 🔽 TEXT AREA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // TITLE
                      Flexible(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 11, // 🔥 smaller
                                    letterSpacing: 0.5,
                                  ),
                          maxLines: 2, // 🔥 IMPORTANT
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // DESC
                      Text(
                        desc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : const Color(0xFF475569),
                              fontSize: 10,
                            ),
                        maxLines: 1, // 🔥 IMPORTANT
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: (1200 + (index * 80)).ms)
                .slideY(begin: 0.1, end: 0),
          ),
        ));
  }

// ================= QUICK ACTION GRID =================
  Widget _buildQuickActions() {
    final List<Map<String, String>> actions = [
      {
        'emoji': '🚨',
        'title': 'NOT BREATHING',
        'desc': 'Start CPR asap',
      },
      {
        'emoji': '🩸',
        'title': 'BLEEDING',
        'desc': 'Stop bleeding fast',
      },
      {
        'emoji': '🧠',
        'title': 'UNCONSCIOUS',
        'desc': 'Check response',
      },
      {
        'emoji': '🔥',
        'title': 'BURN / INJURY',
        'desc': 'Treat injury safely',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.18,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildQuickActionCard(actions[index], index);
      },
    );
  }

// ================= HANDLER =================

  void _handleQuickAction(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyGuideView(
          title: category,
          steps: getSteps(category),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isVertical = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isVertical ? 16 : 18),
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardGradient
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isVertical
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVertical)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.textMuted
                                      : const Color(0xFF475569),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                  ],
                )
              else ...[
                // VERTICAL STYLE for Tools Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMuted
                            : const Color(0xFF475569),
                        fontSize: 9,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

// ================= TOOLS SECTION =================

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tools & Resources',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimary
                    : const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildMissionMapCard(),
            const SizedBox(height: 12),
            _buildToolCard(
              'Protocol Library',
              'Medical emergency procedures',
              Icons.library_books,
              AppColors.alertOrange,
              () => _navigateToProtocolLibrary(),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
    );
  }

  void _navigateToProtocolLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProtocolLibraryView(initialCategory: 'general'),
      ),
    );
  }

  void _showModelSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModelSetupSheet(),
    );
  }

  // ================= MISSION MAP CARD =================

  Widget _buildMissionMapCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TacticalMapView()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.cardGradient
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF38BDF8).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // 🗺 MINI MAP ICON
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFF38BDF8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFF38BDF8).withOpacity(0.2)),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: AppColors.infoBlue,
                    size: 28,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "MISSION MAP",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "LIVE",
                            style: TextStyle(
                              color: AppColors.safeGreen,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tactical navigation & unit coordination",
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model setup bottom sheet
class ModelSetupSheet extends StatelessWidget {
  const ModelSetupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceCard
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Required',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download AI models to enable offline emergency guidance. This only needs to be done once.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ModelService>(
              builder: (context, modelService, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildModelItem(
                        context,
                        'Language Model (LLM)',
                        'SmolLM2 for emergency guidance',
                        '~400MB',
                        false, // Will check async
                        modelService.isLLMLoaded,
                        modelService.isLLMDownloading
                            ? modelService.llmDownloadProgress
                            : null,
                        () => modelService.downloadAndLoadLLM(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Speech-to-Text (STT)',
                        'Whisper Tiny for voice input',
                        '~80MB',
                        false, // Will check async
                        modelService.isSTTLoaded,
                        modelService.isSTTDownloading
                            ? modelService.sttDownloadProgress
                            : null,
                        () => modelService.downloadAndLoadSTT(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Text-to-Speech (TTS)',
                        'Piper TTS for voice output',
                        '~100MB',
                        false, // Will check async
                        modelService.isTTSLoaded,
                        modelService.isTTSDownloading
                            ? modelService.ttsDownloadProgress
                            : null,
                        () => modelService.downloadAndLoadTTS(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem(
    BuildContext context,
    String title,
    String subtitle,
    String size,
    bool isDownloaded,
    bool isLoaded,
    double? progress,
    VoidCallback onDownload,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceElevated
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.light
            ? Border.all(color: Colors.black.withOpacity(0.08))
            : Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitle • $size',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMuted
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isLoaded)
                const Icon(Icons.check_circle, color: AppColors.safeGreen)
              else if (progress != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
