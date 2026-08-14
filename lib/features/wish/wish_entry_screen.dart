import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../growth_os/data/wish_agent_service.dart';
import '../growth_os/data/wish_module_models.dart';
import '../growth_os/data/wish_repository.dart';

class WishEntryScreen extends ConsumerStatefulWidget {
  const WishEntryScreen({super.key});

  @override
  ConsumerState<WishEntryScreen> createState() => _WishEntryScreenState();
}

class _WishEntryScreenState extends ConsumerState<WishEntryScreen> {
  final TextEditingController _wishController = TextEditingController();
  bool _showShootingStar = false;
  bool _isSaving = false;
  String _selectedFocus = 'Personal';
  String _selectedMood = 'Hopeful';

  final List<Map<String, dynamic>> _focusAreas = [
    {'label': 'Physical', 'icon': Icons.directions_run},
    {'label': 'Mental', 'icon': Icons.psychology_outlined},
    {'label': 'Ethical', 'icon': Icons.favorite_outline},
  ];

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Hopeful', 'icon': Icons.sentiment_satisfied_alt},
    {'label': 'Excited', 'icon': Icons.wb_sunny},
    {'label': 'Courage', 'icon': Icons.shield_outlined},
    {'label': 'Wisdom', 'icon': Icons.lightbulb_outline},
  ];

  @override
  void initState() {
    super.initState();
    _wishController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _submitWish() async {
    final wishText = _wishController.text.trim();
    if (wishText.isEmpty) return;

    setState(() {
      _showShootingStar = true;
      _isSaving = true;
    });
    try {
      final repo = ref.read(wishRepositoryProvider);
      final requests = await repo.getRecommendedHelpRequests(_selectedFocus);
      final insight = await WishAgentService().analyzeWish(
        wishText: wishText,
        focusArea: _selectedFocus,
        feeling: _selectedMood,
        requests: requests,
        streakDays: await repo.getWishStreak(),
      );
      final wish = await repo.recordIndividualWish(
        wishText: wishText,
        focusArea: _selectedFocus,
        feeling: _selectedMood,
        insight: WishAgentInsightData(
          sentiment: insight.sentiment,
          primaryVirtue: insight.primaryVirtue,
        ),
      );
      await repo.saveWishModuleTasks(wishId: wish['id'].toString(), drafts: insight.tasks);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_wish', true);
      await prefs.setBool('has_visited_wish_module', true);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your wish could not be saved yet: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _showShootingStar = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Make a Wish',
          style: TextStyle(
            color: AppColors.red,
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Copy
              const Text(
                "What's in your heart?",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share your wish with the universe.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Wish Input Area with Mascot Companion
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tan1, width: 1.5),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        TextField(
                          controller: _wishController,
                          maxLength: 250,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'I wish for...',
                            hintStyle: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            counterText: '',
                          ),
                          maxLines: 4,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: 0.9,
                    child: const MascotWidget(height: 70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_wishController.text.length}/250',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Choose a Focus Area
              const Text(
                'Choose a Focus Area',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: _focusAreas.map((area) {
                  final isSelected = _selectedFocus == area['label'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFocus = area['label']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.red : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.red : AppColors.tan1,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              area['icon'] as IconData,
                              color: isSelected ? AppColors.white : AppColors.red,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              area['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.white : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // How it feels
              const Text(
                'How it feels',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['label'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMood = mood['label']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.red : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.red : AppColors.tan1,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              mood['icon'] as IconData,
                              color: isSelected ? AppColors.white : AppColors.red,
                              size: 22,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mood['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.white : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showShootingStar ? null : _submitWish,
                  icon: const Icon(Icons.auto_awesome, color: AppColors.white),
                   label: Text(
                    _isSaving ? 'Listening...' : 'Send My Wish',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
