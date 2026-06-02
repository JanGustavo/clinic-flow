import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsultasScreen extends StatefulWidget {
  const ConsultasScreen({super.key});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  static String get _backendBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5000';
      default:
        return 'http://127.0.0.1:5000';
    }
  }

  final List<_ConsultaItem> _consultas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConsultas();
  }

  Future<void> _fetchConsultas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uri = Uri.parse('$_backendBaseUrl/consultas');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw Exception(
          'Erro ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Resposta inesperada do servidor.');
      }

      final consultas = decoded
          .whereType<Map<String, dynamic>>()
          .map(_ConsultaItem.fromJson)
          .toList();

      setState(() {
        _consultas
          ..clear()
          ..addAll(consultas);
      });
    } catch (error) {
      setState(() {
        _errorMessage =
            'Não foi possível carregar as consultas.\n${error.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Token de autenticação não encontrado. Faça login novamente.',
      );
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas marcadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _fetchConsultas,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Próximas consultas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoading
                    ? 'Buscando suas consultas...'
                    : 'Você tem ${_consultas.length} consultas agendadas.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fique tranquilo: suas consultas são carregadas direto do servidor.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_consultas.isEmpty) {
      return const Center(child: Text('Nenhuma consulta encontrada.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _consultas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final consulta = _consultas[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: consulta.corStatus.withAlpha(41),
                      child: Icon(
                        Icons.calendar_month,
                        color: consulta.corStatus,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consulta.odontologo,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paciente: ${consulta.paciente}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        consulta.status,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: consulta.corStatus.withAlpha(36),
                      labelStyle: TextStyle(color: consulta.corStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(consulta.dataHora),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sell, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(consulta.valor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(consulta.motivo)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Responsável: ${consulta.usuarioResponsavel}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detalhes'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar presença'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConsultaItem {
  _ConsultaItem({
    required this.id,
    required this.dataHora,
    required this.motivo,
    required this.valor,
    required this.prioridade,
    required this.paciente,
    required this.odontologo,
    required this.usuarioResponsavel,
  }) : status = _statusFromPrioridade(prioridade),
       corStatus = _colorFromPrioridade(prioridade);

  final int id;
  final String dataHora;
  final String motivo;
  final String valor;
  final String prioridade;
  final String paciente;
  final String odontologo;
  final String usuarioResponsavel;
  final String status;
  final Color corStatus;

  factory _ConsultaItem.fromJson(Map<String, dynamic> json) {
    final rawDataHora = json['data_hora']?.toString() ?? '';
    return _ConsultaItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      dataHora: _formatDateTime(rawDataHora),
      motivo: json['motivo']?.toString() ?? 'Sem motivo informado',
      valor: _formatValor(json['valor']),
      prioridade: json['prioridade']?.toString() ?? 'BAIXA',
      paciente: json['paciente']?.toString() ?? 'Desconhecido',
      odontologo: json['odontologo']?.toString() ?? 'Odontologista',
      usuarioResponsavel:
          json['usuario_responsavel']?.toString() ?? 'Não informado',
    );
  }

  static String _statusFromPrioridade(String prioridade) {
    switch (prioridade.toUpperCase()) {
      case 'ALTA':
        return 'Urgente';
      case 'MÉDIA':
      case 'MEDIA':
        return 'Prioritária';
      default:
        return 'Normal';
    }
  }

  static Color _colorFromPrioridade(String prioridade) {
    switch (prioridade.toUpperCase()) {
      case 'ALTA':
        return Colors.red;
      case 'MÉDIA':
      case 'MEDIA':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  static String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.replaceAll('T', ' ').replaceAll('.000Z', '');
    }
    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year} '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }

  static String _formatValor(dynamic rawValor) {
    if (rawValor == null) return 'R\$ 0,00';
    if (rawValor is num) {
      return 'R\$ ${rawValor.toStringAsFixed(2)}';
    }
    final parsed = double.tryParse(rawValor.toString().replaceAll(',', '.'));
    if (parsed != null) {
      return 'R\$ ${parsed.toStringAsFixed(2)}';
    }
    return rawValor.toString();
  }
}
