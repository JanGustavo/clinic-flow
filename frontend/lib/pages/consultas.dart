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
      List<dynamic> listaJson = [];

      if (decoded is List) {
        listaJson = decoded;
      } else if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          listaJson = decoded['data'];
        } else if (decoded['consultas'] is List) {
          listaJson = decoded['consultas'];
        } else if (decoded['payload'] is List) {
          listaJson = decoded['payload'];
        } else if (decoded['results'] is List) {
          listaJson = decoded['results'];
        } else {
          final listKey = decoded.keys.firstWhere(
            (k) => decoded[k] is List,
            orElse: () => '',
          );
          if (listKey.isNotEmpty) {
            listaJson = decoded[listKey];
          } else {
            throw Exception('Nenhuma lista de dados de consulta foi encontrada.');
          }
        }
      } else {
        throw Exception('Resposta inesperada do servidor.');
      }

      final consultas = listaJson
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

  void _mostrarContatoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 10),
            const Text("Falar Conosco", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Deseja falar com nossa recepção via WhatsApp para reagendar ou tirar dúvidas sobre sua consulta?",
          style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redirecionando para o WhatsApp...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Conversar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8F9FA);
    const colorPrimary = Color(0xFF00B4D8);
    const colorSecondary = Color(0xFFF50057);
    const colorText = Color(0xFF212529);
    const colorMuted = Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Consultas Marcadas',
          style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: colorPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: colorPrimary, size: 26),
            tooltip: 'Atualizar',
            onPressed: _fetchConsultas,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFEFF7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de Resumo de Consultas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [colorPrimary, Color(0xFF0077B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorPrimary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agenda Clínica',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading
                                  ? 'Buscando consultas no servidor...'
                                  : 'Você tem ${_consultas.length} consultas cadastradas.',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildBody(context, colorPrimary, colorSecondary, colorText, colorMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, 
    Color colorPrimary, 
    Color colorSecondary, 
    Color colorText, 
    Color colorMuted
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorPrimary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: colorSecondary, size: 50),
              const SizedBox(height: 14),
              const Text(
                'Falha de Carregamento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorMuted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _fetchConsultas,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_consultas.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded, color: colorPrimary, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nenhuma Consulta Ativa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF212529)),
              ),
              const SizedBox(height: 8),
              Text(
                'Você não possui nenhuma consulta marcada em sua agenda clínica até o momento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _mostrarContatoDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Agendar no WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _consultas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final consulta = _consultas[index];
        final dentistInitials = consulta.odontologo.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: consulta.corStatus.withOpacity(0.1),
                      child: Text(
                        dentistInitials.isNotEmpty ? dentistInitials : 'D',
                        style: TextStyle(
                          color: consulta.corStatus,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consulta.odontologo,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Paciente: ${consulta.paciente}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: consulta.corStatus.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        consulta.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          color: consulta.corStatus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 16),
                
                _buildRowInfo(Icons.calendar_today_rounded, "Data & Hora", consulta.dataHora, colorPrimary),
                const SizedBox(height: 10),
                _buildRowInfo(Icons.payments_outlined, "Valor do Serviço", consulta.valor, colorPrimary),
                const SizedBox(height: 10),
                _buildRowInfo(Icons.assignment_outlined, "Motivo / Descrição", consulta.motivo, colorPrimary),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 14),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Agendado por: ${consulta.usuarioResponsavel}',
                      style: TextStyle(fontSize: 11.5, color: colorMuted, fontStyle: FontStyle.italic),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _mostrarContatoDialog(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('Mensagem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorSecondary,
                        side: BorderSide(color: colorSecondary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
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

  Widget _buildRowInfo(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF212529), height: 1.3),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
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
  })  : corStatus = _colorFromPrioridade(prioridade),
        status = _statusFromPrioridade(prioridade);

  final int id;
  final String dataHora;
  final String motivo;
  final String valor;
  final String prioridade;
  final String paciente;
  final String odontologo;
  final String usuarioResponsavel;
  final Color corStatus;
  final String status;

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
        return const Color(0xFFF50057); // Rosa Neon
      case 'MÉDIA':
      case 'MEDIA':
        return Colors.orange;
      default:
        return const Color(0xFF00B4D8); // Azul Ciano
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
