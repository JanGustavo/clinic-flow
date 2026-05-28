import 'package:flutter/material.dart';

class ConsultasScreen extends StatelessWidget {
  const ConsultasScreen({Key? super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Consulta com Dr. Silva'),
            subtitle: Text('10/06/2026 - 14:00'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Consulta com Dra. Pereira'),
            subtitle: Text('18/06/2026 - 09:30'),
          ),
        ],
      ),
    );
  }
}
