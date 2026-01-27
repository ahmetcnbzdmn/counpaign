import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/business_provider.dart';

class TerminalsScreen extends StatefulWidget {
  const TerminalsScreen({super.key});

  @override
  State<TerminalsScreen> createState() => _TerminalsScreenState();
}

class _TerminalsScreenState extends State<TerminalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().fetchTerminals();
    });
  }

  void _showAddTerminalDialog() {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Terminal Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Terminal Adı (örn: Kasa 1)')),
            TextField(controller: idController, decoration: const InputDecoration(labelText: 'Terminal ID (Benzersiz)')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Terminal Şifresi (Giriş için)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<BusinessProvider>().createTerminal(
                  nameController.text, 
                  idController.text, 
                  passwordController.text
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terminal oluşturuldu')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Terminallerim')),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: provider.terminals.length,
            itemBuilder: (context, index) {
              final terminal = provider.terminals[index];
              return ListTile(
                leading: const Icon(Icons.point_of_sale, size: 36, color: Colors.indigo),
                title: Text(terminal['terminalName'] ?? 'No Name'),
                subtitle: Text('ID: ${terminal['terminalId']}'),
                // trailing: Icon(terminal['isActive'] ? Icons.check_circle : Icons.cancel, color: terminal['isActive'] ? Colors.green : Colors.red),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTerminalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
