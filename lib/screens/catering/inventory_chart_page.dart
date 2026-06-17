import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // 記得在 pubspec.yaml 加入 intl 套件

class InventoryChartPage extends StatelessWidget {
  const InventoryChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("庫存週/月變化")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inventory_logs')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 將資料轉為統計格式
          List<FlSpot> spots = _processChartData(snapshot.data!.docs);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 將 Firebase 紀錄轉換為圖表數據的運算邏輯
  List<FlSpot> _processChartData(List<QueryDocumentSnapshot> docs) {
    Map<String, double> dailyTotals = {};
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
      
      // 將該日期的變動量加總
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + (data['quantity_change'] as num).toDouble();
    }

    // 將 Map 轉成圖表用的 FlSpot (X軸為天數，Y軸為數量變化)
    List<FlSpot> spots = [];
    int i = 0;
    dailyTotals.forEach((date, value) {
      spots.add(FlSpot(i.toDouble(), value));
      i++;
    });
    return spots;
  }
}