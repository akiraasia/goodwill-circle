import 'package:flutter/material.dart';
import '../../shared/widgets/shooting_star_overlay.dart';

class WishEntryScreen extends StatefulWidget {
  const WishEntryScreen({Key? key}) : super(key: key);

  @override
  _WishEntryScreenState createState() => _WishEntryScreenState();
}

class _WishEntryScreenState extends State<WishEntryScreen> {
  final TextEditingController _wishController = TextEditingController();
  bool _showShootingStar = false;

  void _submitWish() {
    if (_wishController.text.trim().isNotEmpty) {
      setState(() {
        _showShootingStar = true;
      });
      
      // Delay to show animation before navigating to interview screen
      Future.delayed(const Duration(seconds: 2), () {
        // TODO: Navigate to WishInterviewScreen and pass the wish
      });
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'What is your honest wish?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _wishController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'I wish to...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _showShootingStar ? null : _submitWish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cast Wish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showShootingStar)
            const ShootingStarOverlay(),
        ],
      ),
    );
  }
}
