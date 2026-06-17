import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoardFormPage extends StatefulWidget {
  const BoardFormPage({super.key});
  @override
  State<BoardFormPage> createState() => _BoardFormPageState();
}

class _BoardFormPageState extends State<BoardFormPage> {
  final _controllers = {
    'lastFour': TextEditingController(),
    'warranty': TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveBoard() async {
    await FirebaseFirestore.instance.collection('boards').add({
      'last_four': _controllers['lastFour']!.text,
      'warranty_start': _controllers['warranty']!.text,
      'repair_count': 0, // 初始次數為 0
      'created_at': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("新增機板")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _controllers['lastFour'], decoration: const InputDecoration(labelText: '機板後四碼')),
        TextFormField(controller: _controllers['warranty'], decoration: const InputDecoration(labelText: '保固生效日')),
        ElevatedButton(onPressed: _saveBoard, child: const Text("開始登記機板")),
      ]),
    );
  }
}