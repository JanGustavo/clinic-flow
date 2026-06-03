import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _odontologos = [];
  List<Map<String, dynamic>> _procedimentos = [];
  bool _isLoading = true;
  bool _loadingDialogData = false;
  String? _errorMessage;
  bool _isSubmittingConsulta = false;
  String? _userRole;
  bool _checkedArguments = false;

  @override
  void initState() {
    super.initState();
    _fetchConsultas();
    _fetchProfileAndData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedArguments) {
      _checkedArguments = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSolicitarConsultaDialog(preselectedExame: args);
        });
      }
    }
  }

  Future<void> _fetchProfileAndData() async {
    await _getCurrentUserId();
    await _fetchDialogData();
  }

  Future<void> _fetchDialogData() async {
    setState(() {
      _loadingDialogData = true;
    });

    try {
      final headers = await BackendService.authHeaders();

      // Fetch Procedimentos (public endpoint)
      final resProcedimentos = await http.get(
        Uri.parse('${BackendService.baseUrl}/procedimentos'),
        headers: headers,
      );

      if (!mounted) return;

      List<Map<String, dynamic>> loadedProcedimentos = [];
      if (resProcedimentos.statusCode == 200) {
        final decoded = jsonDecode(resProcedimentos.body);
        final raw = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        if (raw is List) {
          for (var item in raw) {
            if (item is Map) {
              loadedProcedimentos.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }

      setState(() {
        _procedimentos = loadedProcedimentos;
        _loadingDialogData = false;
      });
    } catch (e) {
      debugPrint('Error fetching dialog data: $e');
      if (!mounted) return;
      setState(() {
        _loadingDialogData = false;
      });
    }
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

      final tipo = data['tipo']?.toString().toUpperCase();
      if (tipo != null) {
        _userRole = tipo;
      }

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

  String obterDiaSemana(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'SEGUNDA';
      case DateTime.tuesday:
        return 'TERCA';
      case DateTime.wednesday:
        return 'QUARTA';
      case DateTime.thursday:
        return 'QUINTA';
      case DateTime.friday:
        return 'SEXTA';
      case DateTime.saturday:
        return 'SABADO';
      case DateTime.sunday:
        return 'DOMINGO';
      default:
        return 'SEGUNDA';
    }
  }

  String obterTurno(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 6 && hour < 12) {
      return 'MANHA';
    } else if (hour >= 12 && hour < 18) {
      return 'TARDE';
    } else {
      return 'NOITE';
    }
  }

  // Padroniza a aparência dos inputs dentro do diálogo para combinar com
  // os cards de Login / Registro (bordas arredondadas, fill branco, paddings).
  InputDecoration _dialogInputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFF50057)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFF50057), width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableOdontologos(
    String diaSemana,
    String turno,
  ) async {
    try {
      final headers = await BackendService.authHeaders();
      final url = Uri.parse(
        '${BackendService.baseUrl}/odontologos/disponiveis/$diaSemana/$turno',
      );
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final raw = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        if (raw is List) {
          return raw.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching available dentists: $e');
    }
    return [];
  }

  Future<void> _showSolicitarConsultaDialog({Map<String, dynamic>? preselectedExame}) async {
    if (_loadingDialogData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Carregando informações da clínica... Tente novamente em instantes.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_procedimentos.isEmpty) {
      await _fetchDialogData();
    }

    if (!mounted) return;

    if (_procedimentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar o catálogo de exames.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    int? selectedPacienteId;
    int? selectedOdontologoId;
    int? selectedProcedimentoId;
    
    if (preselectedExame != null && _procedimentos.isNotEmpty) {
      try {
        final found = _procedimentos.firstWhere(
          (p) => p['id']?.toString() == preselectedExame['id']?.toString(),
          orElse: () => _procedimentos.first,
        );
        selectedProcedimentoId = found['id'] as int?;
      } catch (_) {
        selectedProcedimentoId = _procedimentos.first['id'] as int?;
      }
    } else {
      selectedProcedimentoId = _procedimentos.isNotEmpty ? _procedimentos.first['id'] as int? : null;
    }

    final initialProcedimento = _procedimentos.firstWhere(
      (p) => p['id'] == selectedProcedimentoId,
      orElse: () => {},
    );

    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));
    final dataHoraController = TextEditingController(
      text:
          '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
    );
    final cpfController = TextEditingController();
    final motivoController = TextEditingController(text: 'Consulta Geral');
    final valorController = TextEditingController(
      text: initialProcedimento['valor']?.toString() ?? '0.00',
    );
    final formKey = GlobalKey<FormState>();
    String prioridade = 'MEDIA';
    String? localError;
    bool submetendo = false;

    List<Map<String, dynamic>> availableDentists = [];
    bool loadingDentists = false;
    String? dentistError;

    bool checkingCpf = false;
    String? checkedPatientName;
    String? cpfVerificationError;

    Future<void> verificarCpfPaciente(
      String cpf,
      Function(void Function()) setDialogState,
    ) async {
      final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
      if (cleanCpf.length != 11) {
        setDialogState(() {
          checkedPatientName = null;
          cpfVerificationError = 'CPF deve conter 11 dígitos';
          selectedPacienteId = null;
        });
        return;
      }

      setDialogState(() {
        checkingCpf = true;
        cpfVerificationError = null;
        checkedPatientName = 'Verificando...';
      });

      try {
        final headers = await _getAuthHeaders();
        final response = await http.get(
          Uri.parse('${BackendService.baseUrl}/pacientes/cpf/$cleanCpf'),
          headers: headers,
        );

        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;

        if (response.statusCode == 200 && data is Map) {
          setDialogState(() {
            selectedPacienteId = data['id'] as int?;
            checkedPatientName = 'Paciente: ${data['nome']}';
            cpfVerificationError = null;
            checkingCpf = false;
          });
        } else {
          setDialogState(() {
            selectedPacienteId = null;
            checkedPatientName = null;
            cpfVerificationError = 'Paciente não encontrado com este CPF';
            checkingCpf = false;
          });
        }
      } catch (e) {
        setDialogState(() {
          selectedPacienteId = null;
          checkedPatientName = null;
          cpfVerificationError = 'Erro ao verificar CPF: $e';
          checkingCpf = false;
        });
      }
    }

    Future<void> atualizarDentistas(
      DateTime dt,
      Function(void Function()) setDialogState,
    ) async {
      setDialogState(() {
        loadingDentists = true;
        availableDentists = [];
        selectedOdontologoId = null;
        dentistError = null;
      });

      final diaSemana = obterDiaSemana(dt);
      final turno = obterTurno(dt);

      final list = await _fetchAvailableOdontologos(diaSemana, turno);

      setDialogState(() {
        availableDentists = list;
        if (list.isNotEmpty) {
          selectedOdontologoId = list.first['id'] as int?;
        } else {
          dentistError = 'Nenhum odontólogo disponível neste horário';
        }
        loadingDentists = false;
      });
    }

    Future<void> selectDateTime(
      BuildContext context,
      Function(void Function()) setDialogState,
    ) async {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: selectedDateTime,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null) return;

      if (!context.mounted) return;

      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );
      if (time == null) return;

      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      setDialogState(() {
        selectedDateTime = newDateTime;
        dataHoraController.text =
            '${newDateTime.day.toString().padLeft(2, '0')}/${newDateTime.month.toString().padLeft(2, '0')}/${newDateTime.year} ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
      });

      await atualizarDentistas(newDateTime, setDialogState);
    }

    bool initialized = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!initialized) {
              initialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                atualizarDentistas(selectedDateTime, setDialogState);
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 760
                      ? 720
                      : MediaQuery.of(context).size.width - 32,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF00B4D8,
                                ).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                size: 32,
                                color: Color(0xFF00B4D8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Solicitar Consulta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B2D42),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // CPF Input
                          TextFormField(
                            controller: cpfController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CpfInputFormatter()],
                            decoration: _dialogInputDecoration(
                              'CPF do Paciente',
                              Icons.badge_outlined,
                              hintText: '000.000.000-00',
                              suffixIcon: checkingCpf
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF00B4D8),
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF00B4D8),
                                      ),
                                      onPressed: () => verificarCpfPaciente(
                                        cpfController.text,
                                        setDialogState,
                                      ),
                                    ),
                            ),
                            onChanged: (val) {
                              final clean = val.replaceAll(RegExp(r'\D'), '');
                              if (clean.length == 11) {
                                verificarCpfPaciente(val, setDialogState);
                              } else {
                                setDialogState(() {
                                  selectedPacienteId = null;
                                  checkedPatientName = null;
                                  cpfVerificationError = 'Digite os 11 dígitos';
                                });
                              }
                            },
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Informe o CPF do paciente';
                              }
                              if (selectedPacienteId == null) {
                                return cpfVerificationError ??
                                    'CPF do paciente não verificado';
                              }
                              return null;
                            },
                          ),
                          if (checkedPatientName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              checkedPatientName!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Data/Hora Input
                          TextFormField(
                            controller: dataHoraController,
                            readOnly: true,
                            onTap: () =>
                                selectDateTime(context, setDialogState),
                            decoration: _dialogInputDecoration(
                              'Data e Hora',
                              Icons.access_time_outlined,
                              hintText: 'Toque para selecionar',
                              suffixIcon: const Icon(
                                Icons.calendar_month,
                                color: Color(0xFF00B4D8),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Informe a data e hora';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dropdown Odontólogo
                          DropdownButtonFormField<int>(
                            value: selectedOdontologoId,
                            decoration: _dialogInputDecoration(
                              'Selecione o Odontólogo',
                              Icons.medical_services_outlined,
                            ),
                            items: loadingDentists
                                ? [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text(
                                        'Carregando dentistas disponíveis...',
                                      ),
                                    ),
                                  ]
                                : availableDentists.isEmpty
                                ? [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text(
                                        'Nenhum dentista disponível',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ]
                                : availableDentists.map((o) {
                                    final id = o['id'] as int;
                                    final nome =
                                        o['odontologo']?.toString() ??
                                        o['nome']?.toString() ??
                                        'Sem Nome';
                                    final especialidade =
                                        o['especialidade']?.toString() ?? '';
                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        '$nome ($especialidade)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                            onChanged:
                                loadingDentists || availableDentists.isEmpty
                                ? null
                                : (val) {
                                    setDialogState(() {
                                      selectedOdontologoId = val;
                                    });
                                  },
                            validator: (val) {
                              if (val == null) {
                                return dentistError ?? 'Selecione o odontólogo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dropdown Exame
                          DropdownButtonFormField<int>(
                            value: selectedProcedimentoId,
                            decoration: _dialogInputDecoration(
                              'Selecione o Exame',
                              Icons.assignment_outlined,
                            ),
                            items: _procedimentos.map((proc) {
                              final id = proc['id'] as int;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  proc['nome']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedProcedimentoId = val;
                                if (val != null) {
                                  final proc = _procedimentos.firstWhere((p) => p['id'] == val);
                                  final double price =
                                      double.tryParse(
                                        proc['valor']?.toString() ?? '0',
                                      ) ??
                                      0.0;
                                  valorController.text = price.toStringAsFixed(2);
                                }
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Selecione o exame' : null,
                          ),
                          const SizedBox(height: 16),

                          // Valor (Pre-setado, read-only)
                          TextFormField(
                            controller: valorController,
                            readOnly: true,
                            decoration: _dialogInputDecoration(
                              'Valor do Exame (R\$)',
                              Icons.attach_money_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Motivo
                          TextFormField(
                            controller: motivoController,
                            decoration: _dialogInputDecoration(
                              'Motivo da Consulta',
                              Icons.notes_outlined,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Informe o motivo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Prioridade Dropdown
                          DropdownButtonFormField<String>(
                            value: prioridade,
                            decoration: _dialogInputDecoration(
                              'Prioridade',
                              Icons.flag_outlined,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'BAIXA',
                                child: Text('Baixa'),
                              ),
                              DropdownMenuItem(
                                value: 'MEDIA',
                                child: Text('Média'),
                              ),
                              DropdownMenuItem(
                                value: 'ALTA',
                                child: Text('Alta'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  prioridade = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          if (localError != null) ...[
                            Text(
                              localError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00B4D8),
                                      Color(0xFFF50057),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00B4D8,
                                      ).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: submetendo
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!.validate())
                                            return;

                                          setDialogState(() {
                                            submetendo = true;
                                            localError = null;
                                          });

                                          final currentUserId =
                                              await _getCurrentUserId();
                                          if (currentUserId == null) {
                                            setDialogState(() {
                                              localError =
                                                  'Usuário responsável não identificado.';
                                              submetendo = false;
                                            });
                                            return;
                                          }

                                          final formattedDateStr =
                                              '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}:00';

                                          final body = {
                                            'id_paciente': selectedPacienteId,
                                            'id_odontologo':
                                                selectedOdontologoId,
                                            'id_usuario_responsavel':
                                                currentUserId,
                                            'data_hora': formattedDateStr,
                                            'motivo': motivoController.text
                                                .trim(),
                                            'valor':
                                                double.tryParse(
                                                  valorController.text,
                                                ) ??
                                                0.0,
                                            'prioridade': prioridade,
                                          };

                                          try {
                                            final headers =
                                                await _getAuthHeaders();
                                            final response = await http.post(
                                              Uri.parse(
                                                '${BackendService.baseUrl}/consultas',
                                              ),
                                              headers: headers,
                                              body: jsonEncode(body),
                                            );

                                            if (response.statusCode == 201 ||
                                                response.statusCode == 200) {
                                              final decoded = jsonDecode(
                                                response.body,
                                              );
                                              final data =
                                                  decoded is Map &&
                                                      decoded['data'] != null
                                                  ? decoded['data']
                                                  : decoded;
                                              final consultaId = data is Map
                                                  ? data['id']
                                                  : null;

                                              if (consultaId != null &&
                                                  selectedProcedimentoId !=
                                                      null) {
                                                await http.post(
                                                  Uri.parse(
                                                    '${BackendService.baseUrl}/consultas/$consultaId/procedimentos',
                                                  ),
                                                  headers: headers,
                                                  body: jsonEncode({
                                                    'id_procedimento': selectedProcedimentoId,
                                                  }),
                                                );
                                              }

                                              if (!context.mounted) return;
                                              Navigator.of(context).pop();
                                              _fetchConsultas();

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Consulta solicitada e exame vinculado com sucesso!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              final decoded = jsonDecode(
                                                response.body,
                                              );
                                              final errorMsg = decoded is Map
                                                  ? (decoded['error'] ??
                                                            decoded['message'] ??
                                                            (decoded['data']
                                                                    is Map
                                                                ? (decoded['data']['error'] ??
                                                                      decoded['data']['message'])
                                                                : null))
                                                        ?.toString()
                                                  : null;
                                              setDialogState(() {
                                                localError =
                                                    errorMsg ??
                                                    'Erro no servidor (${response.statusCode}).';
                                                submetendo = false;
                                              });
                                            }
                                          } catch (e) {
                                            setDialogState(() {
                                              localError =
                                                  'Erro de conexão: $e';
                                              submetendo = false;
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: submetendo
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Solicitar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) {
      return oldValue;
    }

    var formatted = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) {
        formatted += '.';
      } else if (i == 9) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
