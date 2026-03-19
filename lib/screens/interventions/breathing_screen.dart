import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';

class BreathingScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const BreathingScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const Color _primaryColor = Color(0xFFA9D6E5);
  static const Color _backgroundColor = Color(0xFFEEF8FB);

  String phase = "Inhala suave";
  int completedCycles = 0;
  final int totalCycles = 4;
  bool isFinishing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = Tween<double>(begin: 150, end: 190).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (!mounted || isFinishing) return;

      if (status == AnimationStatus.completed) {
        setState(() {
          phase = "Exhala lento";
        });
        _controller.reverse();
      }

      if (status == AnimationStatus.dismissed) {
        completedCycles++;

        if (completedCycles >= totalCycles) {
          _finishExercise();
          return;
        }

        setState(() {
          phase = "Inhala suave";
        });
        _controller.forward();
      }
    });

    _controller.forward();
  }

  String _getSupportMessage() {
    if (completedCycles == 0) {
      return "Solo sigue este ritmo. No necesitas hacerlo perfecto.";
    }

    if (completedCycles < totalCycles - 1) {
      return "Bien. Sigue conmigo un momento más.";
    }

    return "Ya casi terminamos. Solo una vez más.";
  }

  void _finishExercise() {
    if (isFinishing) return;

    isFinishing = true;
    _controller.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: "breathing",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Respiración guiada",
      child: Container(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.self_improvement,
                size: 54,
                color: _primaryColor,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _getSupportMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          width: _animation.value,
                          height: _animation.value,
                          decoration: const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      phase,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Ciclo ${completedCycles + 1} de $totalCycles",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _finishExercise,
                  child: const Text(
                    "Seguir",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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