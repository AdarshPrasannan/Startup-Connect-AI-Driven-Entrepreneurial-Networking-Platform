import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/screens/dashboard/dashboard_screen.dart';
import 'package:startup_corner/screens/registration/registration_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  late VideoPlayerController _controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/cover.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> handleAuthentication() async {
    try {
      if (isLoading) return;

      setState(() {
        isLoading = true;
      });

      final authAPI = AuthAPI();
      final userCred = await authAPI.googleSignin();

      if (userCred != null) {
        final alreadyReg = await authAPI.readCurrentUser();
        debugPrint('result: $alreadyReg, Type: ${alreadyReg.runtimeType}');

        _controller.pause();
        _controller.dispose();

        if (alreadyReg == null) {
          debugPrint('eneterd correctly!');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const RegistrationScreen()),
            );
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint('Authentication Failed! $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _controller.value.isInitialized
              ? VideoPlayer(_controller)
              : const Center(child: CircularProgressIndicator()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 280.0,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Startup Connect',
                        textStyle: const TextStyle(
                          color: Colors.blueAccent,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                    isRepeatingAnimation: false,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                    ))
                  : ElevatedButton(
                      onPressed: handleAuthentication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logos/logo-google.png',
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Get Started with Google",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
