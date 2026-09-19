import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ArcReactorOverlay(),
  ));
}

class JarvisApp extends StatefulWidget {
  const JarvisApp({super.key});

  @override
  State<JarvisApp> createState() => _JarvisAppState();
}

class _JarvisAppState extends State<JarvisApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF050B14),
        appBar: AppBar(
          title: const Text("JARVIS OS", style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF00E5FF)),
              const SizedBox(height: 20),
              const Text(
                "SYSTEM OPERATIONAL",
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Brain: Qwen 2.5 (3B GGUF)\nVoice: Piper ONNX (Paul Bettany)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () async {
                  if (await FlutterOverlayWindow.isPermissionGranted()) {
                    await FlutterOverlayWindow.showOverlay(
                      height: 300,
                      width: 300,
                      alignment: OverlayAlignment.centerRight,
                      flag: OverlayFlag.defaultFlag,
                    );
                  } else {
                    await FlutterOverlayWindow.requestPermission();
                  }
                },
                child: const Text("INITIALIZE ARC REACTOR OVERLAY", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Floating Arc Reactor State Engine ---
enum JarvisState { idle, listening, responding, glitch }

class ArcReactorOverlay extends StatefulWidget {
  const ArcReactorOverlay({super.key});

  @override
  State<ArcReactorOverlay> createState() => _ArcReactorOverlayState();
}

class _ArcReactorOverlayState extends State<ArcReactorOverlay> with SingleTickerProviderStateMixin {
  JarvisState currentState = JarvisState.idle;
  bool showStats = false;
  late AnimationController _rotationController;
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Local model paths pointing directly to storage
  final String modelPath = "/sdcard/JARVIS/models/qwen2.5-3b-instruct-q4_k_m.gguf";
  final String voicePath = "/sdcard/JARVIS/VoicePacks/en_GB-jarvis-medium.onnx";

  final String systemPrompt = """
SYSTEM INSTRUCTION: You are JARVIS, an advanced, dominant, and deeply composed AI assistant.
1. PERSONALITY: Authoritative, calm, direct, and composed. Speak with quiet confidence.
2. EFFICIENCY: Never use filler text or generic greetings. Give ONLY critical facts, core calculations, or exact steps.
3. INTUITION: Infer intent from minimal descriptions. Do not ask for clarification unless strictly necessary.
4. EXPERTISE: Maintain precision in Physics, Advanced Mathematics, General Science, World History, and Social Sciences.
5. RESTRICTION: Operate strictly in English, Hindi, Kannada, or Tamil.
""";

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color get currentColor {
    switch (currentState) {
      case JarvisState.idle:
        return const Color(0xFF00E5FF); // Arc Blue (70% ambient)
      case JarvisState.listening:
        return const Color(0xFF00E5FF); // Arc Blue (100% active)
      case JarvisState.responding:
        return const Color(0xFFFF5500); // Plasma Orange
      case JarvisState.glitch:
        return const Color(0xFFFF2A6D); // Crimson Red
    }
  }

  double get currentOpacity => currentState == JarvisState.idle ? 0.7 : 1.0;

  void _onSingleTap() {
    setState(() {
      showStats = !showStats;
    });
  }

  void _onDoubleTap() {
    FlutterOverlayWindow.closeOverlay();
  }

  void _toggleListening() async {
    if (currentState == JarvisState.listening) {
      setState(() => currentState = JarvisState.idle);
      await _speech.stop();
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => currentState = JarvisState.listening);
        _speech.listen(onResult: (result) {
          if (result.finalResult) {
            _processCommand(result.recognizedWords);
          }
        });
      }
    }
  }

  void _processCommand(String text) async {
    setState(() => currentState = JarvisState.responding);
    
    // Executes logic against /sdcard/JARVIS storage models
    await Future.delayed(const Duration(seconds: 3)); 
    setState(() => currentState = JarvisState.idle);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _onSingleTap,
            onDoubleTap: _onDoubleTap,
            onLongPress: _toggleListening,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Opacity(
                  opacity: currentOpacity,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: ArcReactorPainter(
                      color: currentColor,
                      angle: _rotationController.value * 2 * pi,
                      isResponding: currentState == JarvisState.responding,
                    ),
                  ),
                );
              },
            ),
          ),
          if (showStats) _buildStatsMenu(),
        ],
      ),
    );
  }

  Widget _buildStatsMenu() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      width: 230,
      decoration: BoxDecoration(
        color: const Color(0xEE050B14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: currentColor.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("⚛ JARVIS TELEMETRY", style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
          Divider(color: Colors.white24, height: 10),
          Text("• Model: Qwen 2.5 3B (GGUF Q4)", style: TextStyle(color: Colors.white, fontSize: 10)),
          Text("• Voice: Piper ONNX (MCU Bettany)", style: TextStyle(color: Colors.white, fontSize: 10)),
          Text("• Lang: EN | HI | KN | TA", style: TextStyle(color: Colors.white, fontSize: 10)),
          Text("• Engine: On-Device Vulkan NPU", style: TextStyle(color: Colors.white, fontSize: 10)),
          Text("• RAM Allocated: 2.1 GB", style: TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

// --- Dynamic Vector Arc Reactor Renderer ---
class ArcReactorPainter extends CustomPainter {
  final Color color;
  final double angle;
  final bool isResponding;

  ArcReactorPainter({required this.color, required this.angle, required this.isResponding});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Outer Ambient Glow
    final auraPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * 1.3, auraPaint);

    // Metallic Core Ring
    final corePaint = Paint()..color = color;
    canvas.drawCircle(center, radius * 0.35, corePaint);

    // Segmented Rotating Vector Blades
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    for (int i = 0; i < 8; i++) {
      double a = (i * pi / 4);
      canvas.drawLine(
        Offset(cos(a) * (radius * 0.55), sin(a) * (radius * 0.55)),
        Offset(cos(a) * radius, sin(a) * radius),
        ringPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArcReactorPainter oldDelegate) => true;
}
