import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

class ProcedimentosRecomendadosScreen extends StatefulWidget {
  const ProcedimentosRecomendadosScreen({super.key, this.consultaId});

  final int? consultaId;

  @override
  State<ProcedimentosRecomendadosScreen> createState() =>
      _ProcedimentosRecomendadosScreenState();
}

class _ProcedimentosRecomendadosScreenState
    extends State<ProcedimentosRecomendadosScreen> {
  final TextEditingController _consultaIdController = TextEditingController();
  final List<_ProcedimentoItem> _procedimentos = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _consultaId;

  @override
  void initState() {
    super.initState();
    if (widget.consultaId != null) {
      _consultaId = widget.consultaId;
      _consultaIdController.text = widget.consultaId.toString();
      _loadProcedimentos();
    }
  }

  @override
  void dispose() {
    _consultaIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProcedimentos() async {
    if (_consultaId == null) {
      setState(() {
        _errorMessage = 'Informe o ID da consulta para ver os procedimentos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _procedimentos.clear();
    });

    final uri = Uri.parse(
      '${BackendService.baseUrl}/consultas/$_consultaId/procedimentos',
    );

    try {
      final headers = await BackendService.authHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawBody =
            decoded is Map<String, dynamic> && decoded['data'] != null
            ? decoded['data']
            : decoded;

        final lista = rawBody is List ? rawBody : [];

        setState(() {
          _procedimentos.addAll(
            lista
                .whereType<Map<String, dynamic>>()
                .map(_ProcedimentoItem.fromJson)
                .toList(),
          );
          _isLoading = false;
        });
      } else {
        final decoded = jsonDecode(response.body);
        final message = _extractErrorMessage(decoded);
        setState(() {
          _errorMessage =
              'Falha ao carregar procedimentos: ${message ?? response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar procedimentos: $e';
        _isLoading = false;
      });
    }
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          (decoded['data'] is Map<String, dynamic>
              ? decoded['data']['error']?.toString() ??
                    decoded['data']['message']?.toString()
              : null);
    }
    return null;
  }

  void _searchByConsultaId() {
    final consultaId = int.tryParse(_consultaIdController.text.trim());
    if (consultaId == null || consultaId <= 0) {
      setState(() {
        _errorMessage = 'Informe um ID de consulta válido.';
      });
      return;
    }

    setState(() {
      _consultaId = consultaId;
      _errorMessage = null;
    });

    _loadProcedimentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Procedimentos Recomendados')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _consultaIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID da Consulta',
                hintText: 'Digite o ID da consulta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar procedimentos'),
              onPressed: _isLoading ? null : _searchByConsultaId,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
                ),
              )
            else if (_procedimentos.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _consultaId == null
                        ? 'Informe o ID da consulta para listar os procedimentos recomendados.'
                        : 'Nenhum procedimento recomendado encontrado para esta consulta.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _procedimentos.length,
                  separatorBuilder: (_, __) => const Divider(),
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
              ),
          ],
        ),
      ),
    );
  }
}

class _ProcedimentoItem {
  _ProcedimentoItem({
    required this.id,
    required this.nome,
    required this.valor,
  });

  final int id;
  final String nome;
  final double valor;

  factory _ProcedimentoItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawValor = json['valor'];
    return _ProcedimentoItem(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      nome: json['nome']?.toString() ?? 'Procedimento sem nome',
      valor: rawValor is num
          ? rawValor.toDouble()
          : double.tryParse('$rawValor'.replaceAll(',', '.')) ?? 0,
    );
  }
}
