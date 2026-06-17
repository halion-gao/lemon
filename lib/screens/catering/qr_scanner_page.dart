import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isAdding = true; 
  bool isProcessing = false; 
  final _manualInputCtrl = TextEditingController();

  @override
  void dispose() {
    _manualInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleManualSubmit() async {
    final code = _manualInputCtrl.text.trim();
    if (code.isEmpty) return;

    if (isProcessing) return;
    setState(() => isProcessing = true);

    await _updateDatabase(code);
    _manualInputCtrl.clear();
    setState(() => isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("掃描進出貨")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isAdding ? Colors.green : Colors.grey[400], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: () => setState(() => isAdding = true),
                  child: const Text("進貨 (+1)", style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: !isAdding ? Colors.red : Colors.grey[400], padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: () => setState(() => isAdding = false),
                  child: const Text("出貨 (-1)", style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(8.0), child: Text("請將鏡頭對準條碼，或於下方手動輸入執行動作", style: TextStyle(fontSize: 16))),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                if (isProcessing) return; 
                
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  isProcessing = true; 
                  final String code = barcodes.first.rawValue!;
                  
                  await _updateDatabase(code);
                  await Future.delayed(const Duration(seconds: 2));
                  isProcessing = false; 
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualInputCtrl,
                    decoration: const InputDecoration(
                      labelText: "手動輸入條碼 / 外接掃描槍支援",
                      hintText: "請輸入代碼並點選確認",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleManualSubmit(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: _handleManualSubmit,
                  child: const Text("確認", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDatabase(String docId) async {
    int change = isAdding ? 1 : -1;
    try {
      await FirebaseFirestore.instance.collection('inventory').doc(docId).update({'quantity': FieldValue.increment(change)});
      await FirebaseFirestore.instance.collection('inventory_logs').add({
        'item_id': docId,
        'change': change,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 成功！$docId 數量 ${change > 0 ? '+1' : '-1'}"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ 錯誤：找不到代碼為 $docId 的物品"), backgroundColor: Colors.red));
    }
  }
}