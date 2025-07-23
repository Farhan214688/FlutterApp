import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class ProfessionalCongratulationsPage extends StatefulWidget {
  const ProfessionalCongratulationsPage({Key? key}) : super(key: key);

  @override
  _ProfessionalCongratulationsPageState createState() => _ProfessionalCongratulationsPageState();
}

class _ProfessionalCongratulationsPageState extends State<ProfessionalCongratulationsPage> {
  Future<void> _finishOnboarding(BuildContext context) async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('professionalOnboardingComplete', true);
    await prefs.setString('userType', 'professional');

    // Navigate to the professional dashboard using the named route
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/professional_dashboard',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightGreen.shade300,
              Colors.lightGreen.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation or Image
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 200,
                  height: 200,
                  child: Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_zv5kpqkj.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.check_circle,
                        size: 100,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Title
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Your account is now set up. You can start offering professional services with Rapit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: 15),
              // Service info
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Selected Service',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Button to continue
              Container(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _finishOnboarding(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.lightGreen.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => _finishOnboarding(context),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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