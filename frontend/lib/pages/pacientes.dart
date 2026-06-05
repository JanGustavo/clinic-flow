import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  final List<Map<String, dynamic>> _pacientes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPacientes();
  }

  Future<void> _fetchPacientes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = await BackendService.authHeaders();
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/pacientes'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map<String, dynamic> && decoded['data'] != null
          ? decoded['data']
          : decoded;
      final List<dynamic> pacientesJson = rawList is List ? rawList : [];

      setState(() {
        _pacientes
          ..clear()
          ..addAll(pacientesJson.whereType<Map<String, dynamic>>());
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao carregar pacientes: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _showPacienteDialog([Map<String, dynamic>? paciente]) async {
    final isEditing = paciente != null;
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(
      text: paciente?['nome']?.toString() ?? '',
    );
    final dataNascimentoController = TextEditingController(
      text: paciente != null
          ? _formatDate(paciente['data_nascimento']?.toString() ?? '')
          : '',
    );
    final cpfController = TextEditingController(
      text: paciente?['cpf']?.toString() ?? '',
    );
    final telefoneController = TextEditingController(
      text: paciente?['telefone']?.toString() ?? '',
    );
    final cepController = TextEditingController(
      text: paciente?['cep']?.toString() ?? '',
    );
    final logradouroController = TextEditingController(
      text: paciente?['logradouro']?.toString() ?? '',
    );
    final numeroCasaController = TextEditingController(
      text: paciente?['numero_casa']?.toString() ?? '',
    );
    final bairroController = TextEditingController(
      text: paciente?['bairro']?.toString() ?? '',
    );
    final cidadeController = TextEditingController(
      text: paciente?['cidade']?.toString() ?? '',
    );
    final estadoController = TextEditingController(
      text: paciente?['estado']?.toString() ?? '',
    );
    DateTime? selectedBirthDate;

    if (paciente != null) {
      final raw = paciente['data_nascimento']?.toString();
      if (raw != null && raw.isNotEmpty) {
        try {
          final partes = raw.split('-');
          if (partes.length == 3) {
            selectedBirthDate = DateTime(
              int.parse(partes[0]),
              int.parse(partes[1]),
              int.parse(partes[2]),
            );
          }
        } catch (_) {}
      }
    }

    Future<void> pickBirthDate() async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate:
            selectedBirthDate ?? now.subtract(const Duration(days: 3650)),
        firstDate: DateTime(1900),
        lastDate: now,
      );
      if (date == null) return;
      selectedBirthDate = date;
      dataNascimentoController.text =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Paciente' : 'Novo Paciente'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nomeController, 'Nome', Icons.person_outline),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: pickBirthDate,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        dataNascimentoController,
                        'Data de Nascimento',
                        Icons.cake_outlined,
                        hintText: 'DD/MM/AAAA',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    cpfController,
                    'CPF',
                    Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    telefoneController,
                    'Telefone',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    cepController,
                    'CEP',
                    Icons.location_on_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    logradouroController,
                    'Logradouro',
                    Icons.house_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    numeroCasaController,
                    'Número',
                    Icons.numbers,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    bairroController,
                    'Bairro',
                    Icons.map_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    cidadeController,
                    'Cidade',
                    Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    estadoController,
                    'Estado',
                    Icons.flag_outlined,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final birthText = dataNascimentoController.text.trim();
                      final birthParts = birthText.split('/');
                      if (birthParts.length != 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Informe uma data de nascimento válida.',
                            ),
                          ),
                        );
                        return;
                      }

                      final payload = {
                        'nome': nomeController.text.trim(),
                        'data_nascimento':
                            '${birthParts[2]}-${birthParts[1].padLeft(2, '0')}-${birthParts[0].padLeft(2, '0')}',
                        'cpf': cpfController.text.trim(),
                        'telefone': telefoneController.text.trim(),
                        'cep': cepController.text.trim(),
                        'logradouro': logradouroController.text.trim(),
                        'numero_casa': numeroCasaController.text.trim(),
                        'bairro': bairroController.text.trim(),
                        'cidade': cidadeController.text.trim(),
                        'estado': estadoController.text.trim(),
                      };

                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        final headers = await BackendService.authHeaders();
                        final uri = isEditing
                            ? Uri.parse(
                                '${BackendService.baseUrl}/pacientes/${paciente!['id']}',
                              )
                            : Uri.parse('${BackendService.baseUrl}/pacientes');

                        developer.log(
                          'POST Paciente - URL: $uri, Headers: ${headers.keys.toList()}',
                          name: 'PacientesScreen',
                        );

                        final response = isEditing
                            ? await http.put(
                                uri,
                                headers: headers,
                                body: jsonEncode(payload),
                              )
                            : await http.post(
                                uri,
                                headers: headers,
                                body: jsonEncode(payload),
                              );

                        developer.log(
                          'POST Response - Status: ${response.statusCode}, Body length: ${response.body.length}',
                          name: 'PacientesScreen',
                        );

                        if (!mounted) return;
                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Navigator.of(context).pop();
                          _fetchPacientes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Paciente atualizado com sucesso.'
                                    : 'Paciente criado com sucesso.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          final decoded = jsonDecode(response.body);
                          final message = decoded is Map<String, dynamic>
                              ? decoded['error']?.toString() ??
                                    decoded['message']?.toString()
                              : 'Erro desconhecido';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Falha: $message')),
                          );
                        }
                      } catch (e) {
                        developer.log(
                          'POST Error - Exception: $e, Type: ${e.runtimeType}',
                          name: 'PacientesScreen',
                        );
                        if (!mounted) return;
                        final errorMsg = e.toString();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro de rede: $errorMsg'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } finally {
                        if (!mounted) return;
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    },
              child: Text(isEditing ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePaciente(Map<String, dynamic> paciente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir paciente'),
          content: Text(
            'Deseja realmente excluir o paciente ${paciente['nome']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final headers = await BackendService.authHeaders();
      final response = await http.delete(
        Uri.parse('${BackendService.baseUrl}/pacientes/${paciente['id']}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _fetchPacientes();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente excluído com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded is Map<String, dynamic>
            ? decoded['error']?.toString() ?? decoded['message']?.toString()
            : 'Erro ao excluir paciente';
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message!)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro de rede: $e')));
    }
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(label, icon, hintText: hintText),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        backgroundColor: const Color(0xFF00B4D8),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : _pacientes.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 18),
                    Text('Nenhum paciente cadastrado ainda.'),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _pacientes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final paciente = _pacientes[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  paciente['nome']?.toString() ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF00B4D8),
                                ),
                                onPressed: () => _showPacienteDialog(paciente),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFF50057),
                                ),
                                onPressed: () => _deletePaciente(paciente),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('CPF: ${paciente['cpf'] ?? '-'}'),
                          const SizedBox(height: 4),
                          Text(
                            'Nascimento: ${_formatDate(paciente['data_nascimento']?.toString() ?? '')}',
                          ),
                          const SizedBox(height: 4),
                          Text('Telefone: ${paciente['telefone'] ?? '-'}'),
                          const SizedBox(height: 4),
                          Text(
                            'Endereço: ${paciente['logradouro'] ?? '-'}, ${paciente['numero_casa'] ?? '-'} - ${paciente['bairro'] ?? '-'}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cidade: ${paciente['cidade'] ?? '-'} / ${paciente['estado'] ?? '-'}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPacienteDialog(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Novo paciente'),
      ),
    );
  }
}
