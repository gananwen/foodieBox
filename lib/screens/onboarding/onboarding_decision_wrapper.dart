// lib/screens/onboarding/onboarding_decision_wrapper.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodiebox/screens/auth_wrapper.dart'; // Your existing login/auth entry
import 'onboarding_screen.dart'; // Your new onboarding flow

class OnboardingDecisionWrapper extends StatefulWidget {
  const OnboardingDecisionWrapper({super.key});

  @override
  State<OnboardingDecisionWrapper> createState() => _OnboardingDecisionWrapperState();
}

class _OnboardingDecisionWrapperState extends State<OnboardingDecisionWrapper> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // If the flag 'onboarding_complete' is true, we skip onboarding.
    final bool completed = prefs.getBool('onboarding_complete') ?? false;

    setState(() {
      _showOnboarding = !completed;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading screen while checking preferences
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If onboarding is needed, show the OnboardingScreen
    if (_showOnboarding) {
      return const OnboardingScreen();
    } 
    
    // If onboarding is complete, proceed to the main AuthWrapper (Login/Home decision)
    return const AuthWrapper(); 
  }
}