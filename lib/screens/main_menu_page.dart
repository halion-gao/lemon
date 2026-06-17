import 'package:flutter/material.dart';
import 'kart/board_list_page.dart';
import 'catering/catering_inv_page.dart';
import 'report_page.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vroom 管理系統", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade100],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: isWideScreen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMenuCard(
                          context,
                          title: "機板維修管理",
                          description: "管理與追蹤賽車機板的維修歷史與妥善率。",
                          icon: Icons.developer_board,
                          iconColor: Colors.blue.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardListPage())),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMenuCard(
                          context,
                          title: "庫存管理 (含掃碼)",
                          description: "進出貨管理，支援 QR Code 掃描與條碼生成。",
                          icon: Icons.inventory_2,
                          iconColor: Colors.teal.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CateringInvPage())),
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMenuCard(
                          context,
                          title: "營運與維修報表",
                          description: "統計分析機板妥善率與庫存變動趨勢圖表。",
                          icon: Icons.analytics,
                          iconColor: Colors.orange.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPage())),
                        )),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMenuCard(
                          context,
                          title: "機板維修管理",
                          description: "管理與追蹤賽車機板的維修歷史與妥善率。",
                          icon: Icons.developer_board,
                          iconColor: Colors.blue.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardListPage())),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: "庫存管理 (含掃碼)",
                          description: "進出貨管理，支援 QR Code 掃描與條碼生成。",
                          icon: Icons.inventory_2,
                          iconColor: Colors.teal.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CateringInvPage())),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuCard(
                          context,
                          title: "營運與維修報表",
                          description: "統計分析機板妥善率與庫存變動趨勢圖表。",
                          icon: Icons.analytics,
                          iconColor: Colors.orange.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPage())),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}