import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/shared/widgets/mascot_widget.dart';
import 'tasks/virtue_tasks_screen.dart';

class PathSelectionScreen extends StatelessWidget {
  final Map<String, int> assignedStats;

  const PathSelectionScreen({Key? key, required this.assignedStats}) : super(key: key);

  List<String> get _determinedVirtues {
    final virtues = <String>[];
    if ((assignedStats['mental'] ?? 0) >= 2) virtues.add('Wisdom');
    if ((assignedStats['physical'] ?? 0) >= 2) virtues.add('Discipline');
    if ((assignedStats['ethical'] ?? 0) >= 2) virtues.add('Integrity');
    if (virtues.isEmpty) virtues.add('Courage');
    return virtues;
  }

  void _proceedToTasks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VirtueTasksScreen(assignedVirtues: _determinedVirtues),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final virtues = _determinedVirtues;

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
          'Your Wish',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot Hero Illustration Container
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.redPale,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: MascotWidget(height: 160, state: MascotState.celebrating),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Your Wish is on its way!',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'The universe is working on it',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Values that may help you section
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tan1, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: AppColors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'A few values that may help you:',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: virtues.map((virtue) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.redPale,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.redMuted),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_outline, size: 14, color: AppColors.red),
                              const SizedBox(width: 6),
                              Text(
                                virtue,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // CTA Buttons
              ElevatedButton.icon(
                onPressed: () => _proceedToTasks(context),
                icon: const Icon(Icons.arrow_forward, color: AppColors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                label: const Text(
                  'Begin my journey',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => context.go('/app'),
                icon: const Icon(Icons.home_outlined, color: AppColors.textMid, size: 18),
                label: const Text(
                  'Return Home',
                  style: TextStyle(color: AppColors.textMid, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
