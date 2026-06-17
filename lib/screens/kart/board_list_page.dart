import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'board_detail_page.dart';

class BoardListPage extends StatefulWidget {
  const BoardListPage({super.key});

  @override
  State<BoardListPage> createState() => _BoardListPageState();
}

class _BoardListPageState extends State<BoardListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = ""; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("機板列表"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110.0), 
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "搜尋機板編號...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black, // 指示線改成黑色
                labelColor: Colors.black,     // 選中的文字改成黑色
                unselectedLabelColor: Colors.black54, // 未選中的文字改成深灰色
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // 字體稍微加粗放大
                tabs: const [Tab(text: "全部"), Tab(text: "正常可用"), Tab(text: "🔧 維修中")],
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('boards').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("📂 目前無機板資料"));

          final docs = snapshot.data!.docs;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBoardList(docs, null),
              _buildBoardList(docs, 'normal'),
              _buildBoardList(docs, 'repairing'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddBoardDialog(context),
      ),
    );
  }

  Widget _buildBoardList(List<QueryDocumentSnapshot> docs, String? filterStatus) {
    var filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      String status = data.containsKey('status') ? data['status'] : 'normal';
      String boardName = data.containsKey('last_four') ? data['last_four'].toString() : '';

      bool matchStatus = filterStatus == null || status == filterStatus;
      bool matchSearch = _searchQuery.isEmpty || boardName.contains(_searchQuery);

      return matchStatus && matchSearch;
    }).toList();

    if (filteredDocs.isEmpty) return Center(child: Text(_searchQuery.isNotEmpty ? "找不到符合「$_searchQuery」的機板" : "目前沒有符合條件的機板"));

    return ListView.builder(
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        
        String status = data.containsKey('status') ? data['status'] : 'normal';
        int repairCount = data.containsKey('repair_count') ? data['repair_count'] : 0;
        bool isRepairing = status == 'repairing';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(isRepairing ? Icons.build_circle : Icons.check_circle, color: isRepairing ? Colors.orange : Colors.green, size: 40),
            title: Text("機板: ${data['last_four'] ?? '無編號'} ${isRepairing ? '(維修中)' : ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text("維修次數: $repairCount 次"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BoardDetailPage(boardId: doc.id, boardName: data['last_four'] ?? '未知'))),
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
          ),
        );
      },
    );
  }

  void _showAddBoardDialog(BuildContext context) {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("新增機板"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "請輸入機板編號")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('boards').add({
                  'last_four': ctrl.text,
                  'status': 'normal',
                  'repair_count': 0,
                  'warranty_end': null,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("新增"),
          )
        ],
      )
    );
  }
}