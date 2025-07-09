import 'package:flutter/material.dart';
import 'auth/choose_auth.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChooseAuthPage()),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'MTA ∑MTC',
            style: TextStyle(
              fontSize: 40,
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
