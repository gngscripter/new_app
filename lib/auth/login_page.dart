import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../homepage.dart'; // ✅ Adjust the path if needed
import 'signup_page.dart'; // ✅ Make sure this points to the correct file

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String emailOrPhone = '';
  String password = '';

  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (!emailOrPhone.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please login using your email"),
          ));
          return;
        }

        // Sign in with Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: emailOrPhone,
          password: password,
        );

        final uid = userCredential.user!.uid;

        // Fetch user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (!doc.exists) {
          throw Exception("User record not found in Firestore.");
        }

        final name = doc['name'];
        final role = doc['role'];

        // Navigate to your existing homepage with name and role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Homepage(username: name, position: role),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $e')),
        );
      }
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Login to Worksync',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => emailOrPhone = val,
                    validator: (val) =>
                    val!.isEmpty ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => password = val,
                    validator: (val) =>
                    val!.isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loginUser,
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goToSignup,
                    child: const Text("Don't have an account? Sign Up"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}