import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BoardDetailPage extends StatelessWidget {
  final String boardId;
  final String boardName;
  const BoardDetailPage({super.key, required this.boardId, required this.boardName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("機板 $boardName 維修歷程")),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('boards').doc(boardId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
              
              var data = snapshot.data!.data() as Map<String, dynamic>;
              String status = data.containsKey('status') ? data['status'] : 'normal';
              int count = data.containsKey('repair_count') ? data['repair_count'] : 0;
              Timestamp? warrantyTs = data['warranty_end'];
              String warrantyText = warrantyTs != null ? DateFormat('yyyy-MM-dd').format(warrantyTs.toDate()) : "無/已過期";

              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blueGrey[100],
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("狀態: ${status == 'repairing' ? '🔧 維修中' : '✅ 正常/閒置'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("累計維修: $count 次", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(alignment: Alignment.centerLeft, child: Text("保固期限: $warrantyText", style: const TextStyle(fontSize: 16, color: Colors.blue))),
                    const SizedBox(height: 15),
                    
                    status == 'repairing' 
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text("登記完修 (延保固/加次數)", style: TextStyle(color: Colors.white, fontSize: 18)),
                          onPressed: () => _showReturnDialog(context, warrantyTs),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
                          icon: const Icon(Icons.build, color: Colors.white),
                          label: const Text("發起送修", style: TextStyle(color: Colors.white, fontSize: 18)),
                          onPressed: () => _showSendRepairDialog(context),
                        ),
                  ],
                ),
              );
            },
          ),
          const Divider(thickness: 2),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('boards').doc(boardId).collection('logs').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("目前無紀錄"));

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final log = snapshot.data!.docs[index];
                    Timestamp? ts = log['timestamp'] as Timestamp?;
                    String timeStr = ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate()) : "剛剛";
                    
                    bool isReturn = log['action'] == '完修';
                    return ListTile(
                      leading: Icon(isReturn ? Icons.verified : Icons.warning, color: isReturn ? Colors.green : Colors.orange),
                      title: Text(isReturn ? "【完修更換】${log['parts']}" : "【送修原因】${log['problem']}"),
                      subtitle: Text("$timeStr\n判定狀態: ${log['usable'] == true ? '可正常使用' : (isReturn ? '報廢/無法使用' : '待修')}"),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSendRepairDialog(BuildContext context) {
    final TextEditingController problemCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("發起送修"),
        content: TextField(controller: problemCtrl, decoration: const InputDecoration(hintText: "請描述損壞狀況 (例如: 不過電)"), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              if (problemCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('boards').doc(boardId).update({'status': 'repairing'});
                FirebaseFirestore.instance.collection('boards').doc(boardId).collection('logs').add({
                  'action': '送修',
                  'problem': problemCtrl.text,
                  'usable': false,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("確認送出"),
          )
        ],
      )
    );
  }

  void _showReturnDialog(BuildContext context, Timestamp? currentWarrantyTs) {
    final TextEditingController partsCtrl = TextEditingController();
    bool isUsable = true; 

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("登記完修"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: partsCtrl, decoration: const InputDecoration(hintText: "更換了哪些零件？(例如: LM5576)"), maxLines: 2),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("修復成功，可正常使用"),
                    value: isUsable,
                    onChanged: (val) => setState(() => isUsable = val!),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
                ElevatedButton(
                  onPressed: () {
                    if (partsCtrl.text.isNotEmpty) {
                      DateTime baseDate = DateTime.now();
                      if (currentWarrantyTs != null && currentWarrantyTs.toDate().isAfter(baseDate)) {
                        baseDate = currentWarrantyTs.toDate();
                      }
                      DateTime newWarranty = DateTime(baseDate.year, baseDate.month + 3, baseDate.day);

                      FirebaseFirestore.instance.collection('boards').doc(boardId).update({
                        'status': isUsable ? 'normal' : 'broken',
                        'repair_count': FieldValue.increment(1),
                        'warranty_end': newWarranty,
                      });

                      FirebaseFirestore.instance.collection('boards').doc(boardId).collection('logs').add({
                        'action': '完修',
                        'parts': partsCtrl.text,
                        'usable': isUsable,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("確認完修"),
                )
              ],
            );
          }
        );
      }
    );
  }
}