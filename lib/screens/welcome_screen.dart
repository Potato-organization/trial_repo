import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';  
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _hintController;
  
  final String _title = "Chaos";
  final List<Animation<double>> _charAnimations = [];

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _hintController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // animation for each character
    final intervalStep = 0.5 / _title.length;
    for (int i = 0; i < _title.length; i++) {
      final start = i * intervalStep;
      final end = start + 0.4;
      
      _charAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _textController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    _textController.forward();
  }

  double _dragOffset = 0.0;
  
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < 0) { // Dragging up
      setState(() {
        _dragOffset += details.primaryDelta!;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset < -100 || details.primaryVelocity! < -500) {
      _navigateToDashboard();
    } else {
      setState(() {
        _dragOffset = 0.0; // Reset if not enough drag
      });
    }
  }

  Future<void> _navigateToDashboard() async {
    // Mark first launch as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', false);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.fastLinearToSlowEaseIn;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          color: Colors.transparent, 
          width: double.infinity,
          height: double.infinity,
          child: AnimatedBuilder(
            animation: _textController, 
            builder: (context, child) {

              return Transform.translate(
                offset: Offset(0, _dragOffset * 0.3), 
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_title.length, (index) {
                              return AnimatedBuilder(
                                animation: _textController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _charAnimations[index].value.clamp(0.0, 1.0),
                                    child: Transform.translate(
                                      offset: Offset(
                                        0, 
                                        20 * (1 - _charAnimations[index].value),
                                      ),
                                      child: Text(
                                        _title[index],
                                        style: TextStyle(
                                          fontFamily: 'MomoSignature',
                                          fontSize: 90,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: Colors.blueAccent.withOpacity(0.5 * _charAnimations[index].value),
                                              offset: const Offset(2, 2),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (_textController.value > 0.6) 
                                    ? (_textController.value - 0.6) / 0.4 
                                    : 0.0,
                                child: child,
                              );
                            },
                            child: Text(
                              'Unleash the Sound',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white70,
                                letterSpacing: 4.0,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: _hintController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (0.4 + (0.6 * _hintController.value)) * (1 + (_dragOffset / 200)).clamp(0.0, 1.0), 
                            child: Transform.translate(
                              offset: Offset(0, -10 * _hintController.value), 
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    color: Colors.white54,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Swipe up to start',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white54,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

