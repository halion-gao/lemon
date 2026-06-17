import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_scanner_page.dart';

class CateringInvPage extends StatelessWidget {
  const CateringInvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("庫存管理"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 30),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerPage())),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventory').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("📂 目前庫存沒有任何資料"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text("${doc.get('name') ?? '未知品項'} (代碼: ${doc.id})", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("數量: ${doc.get('quantity') ?? 0}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.blue), 
                      onPressed: () => _showQRCode(context, doc.id, doc.get('name')),
                    ),
                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _update(doc.id, -1)),
                    IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _update(doc.id, 1)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddInventoryDialog(context),
      ),
    );
  }

  void _update(String docId, int change) {
    FirebaseFirestore.instance.collection('inventory').doc(docId).update({'quantity': FieldValue.increment(change)});
    FirebaseFirestore.instance.collection('inventory_logs').add({
      'item_id': docId,
      'change': change,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showQRCode(BuildContext context, String code, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$name 的 QR Code"),
        content: SizedBox(width: 200, height: 200, child: QrImageView(data: code, version: QrVersions.auto, size: 200.0)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("關閉"))],
      ),
    );
  }

  void _showAddInventoryDialog(BuildContext context) {
    final TextEditingController idCtrl = TextEditingController();
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新增庫存"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(hintText: "條碼代號")),
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: "物品名稱")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = idCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (id.isNotEmpty) {
                final docRef = FirebaseFirestore.instance.collection('inventory').doc(id);
                final docSnap = await docRef.get();
                if (docSnap.exists) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text("❌ 錯誤：代碼 $id 已存在，無法重複新增"), backgroundColor: Colors.red),
                    );
                  }
                } else {
                  await docRef.set({'name': name, 'quantity': 0});
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
            },
            child: const Text("新增"),
          ),
        ],
      ),
    ).then((_) {
      idCtrl.dispose();
      nameCtrl.dispose();
    });
  }
}