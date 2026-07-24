import 'package:flutter/material.dart';
import 'tasks/virtue_tasks_screen.dart';

class PathSelectionScreen extends StatelessWidget {
  final Map<String, int> assignedStats; // e.g., {'physical': 2, 'mental': 3, 'ethical': 1}

  const PathSelectionScreen({Key? key, required this.assignedStats}) : super(key: key);

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            'Lvl $value',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _proceedToTasks(BuildContext context) {
    // Assign virtues from stats — map mental->Wisdom, physical->Discipline, ethical->Integrity
    final virtues = <String>[];
    if ((assignedStats['mental'] ?? 0) >= 2) virtues.add('Wisdom');
    if ((assignedStats['physical'] ?? 0) >= 2) virtues.add('Discipline');
    if ((assignedStats['ethical'] ?? 0) >= 2) virtues.add('Integrity');
    if (virtues.isEmpty) virtues.add('Courage');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VirtueTasksScreen(assignedVirtues: virtues),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Stats Aligned',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Based on your answers, your core path has been assigned the following stats:',
                style: TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildStatCard('Physical', assignedStats['physical'] ?? 1, Icons.fitness_center, Colors.orange),
              const SizedBox(height: 16),
              _buildStatCard('Mental', assignedStats['mental'] ?? 1, Icons.psychology, Colors.blue),
              const SizedBox(height: 16),
              _buildStatCard('Ethical', assignedStats['ethical'] ?? 1, Icons.volunteer_activism, Colors.green),
              const SizedBox(height: 48),
              const Text(
                'Your Journey Awaits',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Story mode with visual novel choices is coming soon. For now, begin with task mode to start building your virtues through real-world actions.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _proceedToTasks(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.assignment, size: 32),
                    SizedBox(height: 12),
                    Text('Begin Task Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Start with real-world actions', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
