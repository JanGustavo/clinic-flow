import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProcedimentosScreen extends StatefulWidget {
  const ProcedimentosScreen({super.key, this.sessionToken});

  final String? sessionToken;

  @override
  State<ProcedimentosScreen> createState() => _ProcedimentosScreenState();
}

class _ProcedimentosScreenState extends State<ProcedimentosScreen> {
  final List<ProcedimentoItem> _procedimentos = [];
  bool _carregando = true;
  String? _erro;

  double _lerValor(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      final normalizado = valor.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();
    _carregarProcedimentos();
  }

  Future<void> _carregarProcedimentos() async {
    final url = Uri.parse('http://localhost:5000/procedimentos');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dadosRecebidos =
            jsonDecode(response.body) as Map<String, dynamic>;
        final lista = (dadosRecebidos['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => ProcedimentoItem(
                id: item['id'] is int
                    ? item['id'] as int
                    : int.tryParse('${item['id']}') ?? 0,
                nome: item['nome']?.toString() ?? '',
                valor: _lerValor(item['valor']),
              ),
            )
            .toList();

        if (!mounted) return;
        setState(() {
          _procedimentos
            ..clear()
            ..addAll(lista);
          _carregando = false;
          _erro = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _erro =
              'Erro ao carregar procedimentos. Status code: ${response.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar procedimentos: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procedimentos'),
        actions: [
          IconButton(
            onPressed: _carregarProcedimentos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_erro!, textAlign: TextAlign.center),
              ),
            )
          : _procedimentos.isEmpty
          ? const Center(child: Text('Nenhum procedimento encontrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _procedimentos.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final procedimento = _procedimentos[index];
                return ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(procedimento.nome),
                  subtitle: Text('ID: ${procedimento.id}'),
                  trailing: Text(
                    'R\$ ${procedimento.valor.toStringAsFixed(2)}',
                  ),
                );
              },
            ),
    );
  }
}

class ProcedimentoItem {
  const ProcedimentoItem({
    required this.id,
    required this.nome,
    required this.valor,
  });

  final int id;
  final String nome;
  final double valor;
}
