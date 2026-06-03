import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';
import 'package:frontend/pages/procedimentos.dart';

class ProcedimentosRecomendadosScreen extends StatefulWidget {
  const ProcedimentosRecomendadosScreen({super.key, this.consultaId});

  final int? consultaId;

  @override
  State<ProcedimentosRecomendadosScreen> createState() =>
      _ProcedimentosRecomendadosScreenState();
}

class _ProcedimentosRecomendadosScreenState
    extends State<ProcedimentosRecomendadosScreen> {
  final List<_ProcedimentoItem> _procedimentos = [];
  List<Map<String, dynamic>> _consultas = [];
  bool _isLoading = false;
  bool _loadingConsultas = true;
  String? _errorMessage;
  int? _consultaId;

  @override
  void initState() {
    super.initState();
    _consultaId = widget.consultaId;
    _loadConsultas();
  }

  Future<void> _loadConsultas() async {
    setState(() {
      _loadingConsultas = true;
      _errorMessage = null;
    });

    final url = Uri.parse('${BackendService.baseUrl}/consultas');

    try {
      final headers = await BackendService.authHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listaJson = [];
        if (decoded is List) {
          listaJson = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          listaJson = decoded['data'];
        }

        final List<Map<String, dynamic>> loadedConsultas = listaJson
            .whereType<Map<String, dynamic>>()
            .toList();

        setState(() {
          _consultas = loadedConsultas;
          // Se já veio um consultaId por parâmetro, carrega as ações dele
          if (_consultaId != null &&
              loadedConsultas.any((c) => c['id'] == _consultaId)) {
            // mantém
          } else if (loadedConsultas.isNotEmpty) {
            _consultaId = loadedConsultas.first['id'] as int;
          }
          _loadingConsultas = false;
        });

        if (_consultaId != null) {
          _loadProcedimentos();
        }
      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar consultas (${response.statusCode})';
          _loadingConsultas = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar consultas: $e';
        _loadingConsultas = false;
      });
    }
  }

  Future<void> _loadProcedimentos() async {
    if (_consultaId == null) return;

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

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'AGENDADA':
        return Colors.blue;
      case 'EM_ANDAMENTO':
        return Colors.orange;
      case 'FINALIZADA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B4D8),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Procedimentos Recomendados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFEFF7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loadingConsultas
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8), // Card mais quadrado!
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                size: 32,
                                color: Color(0xFF00B4D8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Procedimentos por Consulta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B2D42),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Selecione uma consulta para buscar exames reais',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<int>(
                            value: _consultaId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Selecione a Consulta',
                              prefixIcon: const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF00B4D8),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF00B4D8),
                                  width: 2,
                                ),
                              ),
                            ),
                            items: _consultas.map((c) {
                              final id = c['id'] as int;
                              final paciente = c['paciente']?.toString() ?? 'Sem Paciente';
                              final dataRaw = c['data_hora']?.toString() ?? '';
                              String dataFormatted = dataRaw;
                              try {
                                if (dataRaw.length >= 16) {
                                  dataFormatted = dataRaw.substring(0, 16).replaceAll('T', ' ');
                                }
                              } catch (_) {}
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  '#$id - $paciente ($dataFormatted)',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _consultaId = val;
                                });
                                _loadProcedimentos();
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4D8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Procedimentos Vinculados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2D42),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (_procedimentos.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                _consultaId == null
                                    ? 'Selecione uma consulta.'
                                    : 'Nenhum exame recomendado nesta consulta.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _procedimentos.length,
                                itemBuilder: (context, index) {
                                  final procedimento = _procedimentos[index];
                                  final selectedConsulta = _consultas.firstWhere(
                                    (c) => c['id'] == _consultaId,
                                    orElse: () => {},
                                  );
                                  final doctorName = selectedConsulta['odontologo']?.toString() ?? 'Não atribuído';
                                  final dataRaw = selectedConsulta['data_hora']?.toString() ?? '';
                                  String dataFormatted = dataRaw;
                                  try {
                                    if (dataRaw.length >= 16) {
                                      dataFormatted = dataRaw.substring(0, 16).replaceAll('T', ' ');
                                    }
                                  } catch (_) {}
                                  final statusStr = selectedConsulta['status']?.toString();

                                  return Card(
                                    color: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00B4D8).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.medical_services_outlined,
                                              size: 20,
                                              color: Color(0xFF00B4D8),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  procedimento.nome,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2B2D42),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: #${procedimento.id} | R\$ ${procedimento.valor.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Dr(a).: $doctorName',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Recomendado em: $dataFormatted',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                if (statusStr != null) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(statusStr).withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Status: $statusStr',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getStatusColor(statusStr),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: _consultaId != null
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00B4D8),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProcedimentosScreen(
                      consultaId: _consultaId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadProcedimentos();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar Procedimento',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
