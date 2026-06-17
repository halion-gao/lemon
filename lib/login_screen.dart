import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(), 
        password: passCtrl.text.trim()
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("登入失敗: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("VROOM 登入")),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
        TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "密碼"), obscureText: true),
        ElevatedButton(onPressed: login, child: const Text("登入")),
      ])),
    );
  }
}