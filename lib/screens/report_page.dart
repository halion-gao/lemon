import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _timeRange = 7; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("系統營運報表")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("🔧 機板妥善率分析", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildBoardPieChart(), 
            
            const Divider(height: 40, thickness: 2),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("📈 庫存變動趨勢", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('每週')),
                    ButtonSegment(value: 30, label: Text('每月')),
                  ],
                  selected: {_timeRange},
                  onSelectionChanged: (Set<int> newSelection) => setState(() => _timeRange = newSelection.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("顯示所有品項每日的「淨變動量 (進貨 - 出貨)」", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            _buildInventoryLineChart(), 
          ],
        ),
      ),
    );
  }

  Widget _buildBoardPieChart() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('boards').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          int normalCount = 0;
          int repairingCount = 0;
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'repairing') {
              repairingCount++;
            } else {
              normalCount++;
            }
          }

          if (normalCount == 0 && repairingCount == 0) return const Center(child: Text("尚無資料"));

          return PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(color: Colors.green, value: normalCount.toDouble(), title: '正常 $normalCount', radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                PieChartSectionData(color: Colors.orange, value: repairingCount.toDouble(), title: '維修中 $repairingCount', radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryLineChart() {
    DateTime startDate = DateTime.now().subtract(Duration(days: _timeRange - 1));
    startDate = DateTime(startDate.year, startDate.month, startDate.day); 

    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventory_logs').where('timestamp', isGreaterThanOrEqualTo: startDate).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<double> dailyChanges = List.generate(_timeRange, (index) => 0.0);
          DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

          for (var doc in snapshot.data!.docs) {
            // 加入安全防護：將資料轉為 Map，避免找不到欄位當機
            var data = doc.data() as Map<String, dynamic>;
            
            // 檢查有沒有 timestamp 欄位
            if (!data.containsKey('timestamp') || data['timestamp'] == null) continue;
            
            Timestamp ts = data['timestamp'] as Timestamp;
            DateTime date = ts.toDate();
            DateTime logDay = DateTime(date.year, date.month, date.day);
            
            int daysAgo = today.difference(logDay).inDays;
            if (daysAgo >= 0 && daysAgo < _timeRange) {
              // 檢查有沒有 change 欄位，沒有就當作 0
              int change = data.containsKey('change') ? (data['change'] as num).toInt() : 0;
              dailyChanges[_timeRange - 1 - daysAgo] += change.toDouble();
            }
          }

          List<FlSpot> spots = [];
          for (int i = 0; i < _timeRange; i++) {
            spots.add(FlSpot(i.toDouble(), dailyChanges[i]));
          }

          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= _timeRange) return const SizedBox();
                      DateTime date = startDate.add(Duration(days: index));
                      if (_timeRange == 30 && index % 5 != 0 && index != 29) return const SizedBox();
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)));
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true), 
                  belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}