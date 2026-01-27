import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardDashboard extends StatelessWidget {
  const StandardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Paneli (Standart)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             // Big Scan Button
             Expanded(
               flex: 2,
               child: InkWell(
                 onTap: () {
                   context.push('/business/scanner');
                 }, // Navigate to Scanner
                 child: Container(
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: Colors.teal.shade50,
                     border: Border.all(color: Colors.teal, width: 2),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.qr_code_scanner, size: 80, color: Colors.teal.shade700),
                       const SizedBox(height: 16),
                       Text('Müşteri QR Okut', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                     ],
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 16),
             Expanded(
               flex: 1,
               child: Row(
                 children: [
                   Expanded(
                     child: _buildStatCard('Bugün İşlem', '24', Colors.orange),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: _buildStatCard('Bekleyen Onay', '3', Colors.red),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 16),
             ListTile(
               leading: const Icon(Icons.message),
               title: const Text('Yönetici Mesajları'),
               trailing: const CircleAvatar(radius: 10, child: Text('2', style: TextStyle(fontSize: 12))),
               onTap: () {},
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
