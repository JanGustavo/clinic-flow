import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/procedimentos_recomendados.dart';
import 'package:frontend/services/backend_service.dart';

class ConsultasScreen extends StatefulWidget {
  const ConsultasScreen({super.key});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  final List<_ConsultaItem> _consultas = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmittingConsulta = false;

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

    final uri = Uri.parse('${BackendService.baseUrl}/consultas');

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
            throw Exception(
              'Nenhuma lista de dados de consulta foi encontrada.',
            );
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

  int? _currentUserId;

  Future<Map<String, String>> _getAuthHeaders() async {
    return await BackendService.authHeaders();
  }

  Future<int?> _getCurrentUserId() async {
    if (_currentUserId != null) {
      return _currentUserId;
    }

    try {
      final uri = Uri.parse('${BackendService.baseUrl}/usuarios/perfil');
      final headers = await BackendService.authHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      final data =
          decoded is Map<String, dynamic> &&
              decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;

      final id = data['id'];
      if (id is int) {
        _currentUserId = id;
      } else if (id is String) {
        _currentUserId = int.tryParse(id);
      }
      return _currentUserId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showSolicitarConsultaDialog() async {
    final idPacienteController = TextEditingController();
    final idOdontologoController = TextEditingController();
    final dataHoraController = TextEditingController();
    final motivoController = TextEditingController();
    final valorController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String prioridade = 'MEDIA';
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Solicitar Consulta'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: idPacienteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID do Paciente',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o ID do paciente.';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'ID do paciente deve ser numérico.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idOdontologoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID do Odontólogo',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o ID do odontólogo.';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'ID do odontólogo deve ser numérico.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dataHoraController,
                        decoration: const InputDecoration(
                          labelText: 'Data e hora',
                          hintText: 'YYYY-MM-DD HH:MM:SS',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a data e hora da consulta.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: motivoController,
                        decoration: const InputDecoration(
                          labelText: 'Motivo da consulta',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o motivo da consulta.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          hintText: 'Ex: 99.90',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor do serviço.';
                          }
                          if (double.tryParse(
                                value.trim().replaceAll(',', '.'),
                              ) ==
                              null) {
                            return 'Valor inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: prioridade,
                        items: const [
                          DropdownMenuItem(
                            value: 'BAIXA',
                            child: Text('Baixa'),
                          ),
                          DropdownMenuItem(
                            value: 'MEDIA',
                            child: Text('Média'),
                          ),
                          DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Prioridade',
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              prioridade = value;
                            });
                          }
                        },
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          localError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSubmittingConsulta
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final idPaciente = int.tryParse(
                            idPacienteController.text.trim(),
                          );
                          final idOdontologo = int.tryParse(
                            idOdontologoController.text.trim(),
                          );
                          final dataHora = dataHoraController.text.trim();
                          final motivo = motivoController.text.trim();
                          final valor = valorController.text.trim().replaceAll(
                            ',',
                            '.',
                          );

                          if (idPaciente == null || idOdontologo == null) {
                            setState(() {
                              localError =
                                  'ID do paciente e do odontólogo devem ser numéricos.';
                            });
                            return;
                          }

                          final success = await _solicitarConsulta(
                            idPaciente: idPaciente,
                            idOdontologo: idOdontologo,
                            dataHora: dataHora,
                            motivo: motivo,
                            valor: valor,
                            prioridade: prioridade,
                          );

                          if (success) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _solicitarConsulta({
    required int idPaciente,
    required int idOdontologo,
    required String dataHora,
    required String motivo,
    required String valor,
    required String prioridade,
  }) async {
    setState(() => _isSubmittingConsulta = true);

    try {
      final idUsuarioResponsavel = await _getCurrentUserId();
      if (idUsuarioResponsavel == null) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível identificar o usuário responsável.',
            ),
          ),
        );
        return false;
      }

      final uri = Uri.parse('${BackendService.baseUrl}/consultas');
      final headers = await _getAuthHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'id_paciente': idPaciente,
          'id_odontologo': idOdontologo,
          'id_usuario_responsavel': idUsuarioResponsavel,
          'data_hora': dataHora,
          'motivo': motivo,
          'valor': valor,
          'prioridade': prioridade,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ??
                  'Consulta solicitada com sucesso.'
            : 'Consulta solicitada com sucesso.';
        if (!mounted) return false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        await _fetchConsultas();
        return true;
      }

      String errorMsg = 'Falha ao solicitar consulta.';
      if (decoded is Map<String, dynamic>) {
        errorMsg =
            decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            'Falha ao solicitar consulta.';
        if (decoded['data'] is Map<String, dynamic>) {
          final dataErr =
              decoded['data']['error']?.toString() ??
              decoded['data']['message']?.toString();
          if (dataErr != null) {
            errorMsg = dataErr;
          }
        }
      }

      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao solicitar consulta: $e')));
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSubmittingConsulta = false);
      }
    }
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
          style: TextStyle(
            color: colorText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: colorPrimary,
              size: 26,
            ),
            tooltip: 'Atualizar',
            onPressed: _fetchConsultas,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_sharp),
        label: const Text('Solicitar Consulta'),
        onPressed: _showSolicitarConsultaDialog,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLoading
                                  ? 'Buscando consultas no servidor...'
                                  : 'Você tem ${_consultas.length} consultas cadastradas.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildBody(
                    context,
                    colorPrimary,
                    colorSecondary,
                    colorText,
                    colorMuted,
                  ),
                ),
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
    Color colorMuted,
  ) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colorPrimary));
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
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorSecondary,
                size: 50,
              ),
              const SizedBox(height: 14),
              const Text(
                'Falha de Carregamento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: colorPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nenhuma Consulta Agendada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você não possui consultas marcadas em sua agenda clínica no momento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorMuted, fontSize: 13, height: 1.4),
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
        final dentistInitials = consulta.odontologo
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase();

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
                            style: TextStyle(fontSize: 12, color: colorMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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

                _buildRowInfo(
                  Icons.calendar_today_rounded,
                  "Data & Hora",
                  consulta.dataHora,
                  colorPrimary,
                ),
                const SizedBox(height: 10),
                _buildRowInfo(
                  Icons.payments_outlined,
                  "Valor do Serviço",
                  consulta.valor,
                  colorPrimary,
                ),
                const SizedBox(height: 10),
                _buildRowInfo(
                  Icons.assignment_outlined,
                  "Motivo / Descrição",
                  consulta.motivo,
                  colorPrimary,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 14),

                Text(
                  'Agendado por: ${consulta.usuarioResponsavel}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorMuted,
                    fontStyle: FontStyle.italic,
                  ),
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
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF212529),
                height: 1.3,
              ),
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
  }) : corStatus = _colorFromPrioridade(prioridade),
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
