import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Paneli (Yönetici)'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Özet Analiz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                         getTitlesWidget: (val, meta) {
                           switch(val.toInt()) {
                             case 0: return const Text('Pzt');
                             case 1: return const Text('Sal');
                             case 2: return const Text('Çar');
                             case 3: return const Text('Per');
                             case 4: return const Text('Cum');
                             default: return const Text('');
                           }
                         }
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.blue)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.blue)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.blue)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.blue)]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Hızlı İşlemler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(Icons.campaign, 'Kampanya\nOluştur', Colors.orange),
                _buildActionCard(Icons.analytics, 'Detaylı\nAnaliz', Colors.purple),
                _buildActionCard(Icons.qr_code_scanner, 'QR Okut\n(Puan Yükle)', Colors.green, onTap: () {
                  context.push('/business/scanner');
                }),
                _buildActionCard(Icons.message, 'Mesajlar', Colors.teal),
                _buildActionCard(Icons.store, 'Şirket\nBilgileri', Colors.blueGrey),
                _buildActionCard(Icons.people, 'Terminaller', Colors.indigo, onTap: () {
                  context.push('/business/terminals');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
