import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

class OdontologosScreen extends StatefulWidget {
  const OdontologosScreen({super.key});

  @override
  State<OdontologosScreen> createState() => _OdontologosScreenState();
}

class _OdontologosScreenState extends State<OdontologosScreen> {
  final List<Map<String, dynamic>> _odontologos = [];
  final List<Map<String, dynamic>> _especialidades = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.wait([_fetchCurrentUserId(), _fetchEspecialidades()]);
    await _fetchOdontologos();
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final headers = await BackendService.authHeaders();
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/usuarios/perfil'),
        headers: headers,
      );
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> && decoded['data'] != null
          ? decoded['data']
          : decoded;
      final id = data is Map<String, dynamic> ? data['id'] : null;
      if (id is int) {
        _currentUserId = id;
      } else if (id is String) {
        _currentUserId = int.tryParse(id);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchOdontologos() async {
    try {
      final headers = await BackendService.authHeaders();
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/odontologos'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map<String, dynamic> && decoded['data'] != null
          ? decoded['data']
          : decoded;
      final List<dynamic> items = rawList is List ? rawList : [];

      if (!mounted) return;
      setState(() {
        _odontologos
          ..clear()
          ..addAll(items.whereType<Map<String, dynamic>>());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Falha ao carregar odontólogos: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEspecialidades() async {
    try {
      final headers = await BackendService.authHeaders();
      final uri = Uri.parse('${BackendService.baseUrl}/especialidades');
      developer.log(
        'Fetching especialidades from $uri',
        name: 'OdontologosScreen',
      );
      final response = await http.get(uri, headers: headers);
      developer.log(
        'Especialidades response: ${response.statusCode}, body length: ${response.body.length}',
        name: 'OdontologosScreen',
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList =
            decoded is Map<String, dynamic> && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final List<dynamic> items = rawList is List ? rawList : [];
        developer.log(
          'Parsed ${items.length} especialidades',
          name: 'OdontologosScreen',
        );
        if (!mounted) return;
        setState(() {
          _especialidades
            ..clear()
            ..addAll(items.whereType<Map<String, dynamic>>());
        });
      } else {
        developer.log(
          'Especialidades fetch failed: ${response.statusCode}',
          name: 'OdontologosScreen',
        );
      }
    } catch (e) {
      developer.log(
        'Error fetching especialidades: $e',
        name: 'OdontologosScreen',
        error: e,
      );
    }
  }

  Future<void> _showOdontologoDialog([Map<String, dynamic>? odontologo]) async {
    final isEdit = odontologo != null;
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(
      text: odontologo?['nome']?.toString() ?? '',
    );
    final croController = TextEditingController(
      text: odontologo?['cro']?.toString() ?? '',
    );
    final salarioController = TextEditingController(
      text: odontologo?['salario']?.toString() ?? '',
    );
    int? selectedEspecialidadeId = odontologo?['id_especialidade'] is int
        ? odontologo!['id_especialidade'] as int
        : null;

    if (selectedEspecialidadeId == null && odontologo != null) {
      selectedEspecialidadeId =
          _especialidades.firstWhere(
                (item) => item['nome'] == odontologo['especialidade'],
                orElse: () => {},
              )['id']
              as int?;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Editar Odontólogo' : 'Novo Odontólogo'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nomeController, 'Nome', Icons.person_outline),
                  const SizedBox(height: 10),
                  _buildTextField(croController, 'CRO', Icons.badge_outlined),
                  const SizedBox(height: 10),
                  _buildTextField(
                    salarioController,
                    'Salário',
                    Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedEspecialidadeId,
                    decoration: _fieldDecoration(
                      'Especialidade',
                      Icons.medical_services,
                    ),
                    items: _especialidades
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item['id'] is int
                                ? item['id'] as int
                                : int.tryParse('${item['id']}'),
                            child: Text(item['nome']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      selectedEspecialidadeId = value;
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Escolha uma especialidade';
                      }
                      return null;
                    },
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
                      if (!formKey.currentState!.validate()) return;
                      if (_currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível obter o usuário atual.',
                            ),
                          ),
                        );
                        return;
                      }

                      final payload = {
                        'nome': nomeController.text.trim(),
                        'cro': croController.text.trim(),
                        'salario':
                            double.tryParse(
                              salarioController.text.replaceAll(',', '.'),
                            ) ??
                            0,
                        'id_especialidade': selectedEspecialidadeId,
                        'id_usuario': _currentUserId,
                      };

                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        final headers = await BackendService.authHeaders();
                        final uri = isEdit
                            ? Uri.parse(
                                '${BackendService.baseUrl}/odontologos/${odontologo!['id']}',
                              )
                            : Uri.parse(
                                '${BackendService.baseUrl}/odontologos',
                              );
                        final response = isEdit
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

                        if (!mounted) return;
                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Navigator.of(context).pop();
                          await _fetchOdontologos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'Odontólogo atualizado com sucesso.'
                                    : 'Odontólogo criado com sucesso.',
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
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message!)));
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro de rede: $e')),
                        );
                      } finally {
                        if (!mounted) return;
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    },
              child: Text(isEdit ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOdontologo(Map<String, dynamic> odontologo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir odontólogo'),
          content: Text('Deseja excluir o odontólogo ${odontologo['nome']}?'),
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
    if (confirmed != true) return;
    try {
      final headers = await BackendService.authHeaders();
      final response = await http.delete(
        Uri.parse('${BackendService.baseUrl}/odontologos/${odontologo['id']}'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchOdontologos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Odontólogo excluído com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final decoded = jsonDecode(response.body);
        final message = decoded is Map<String, dynamic>
            ? decoded['error']?.toString() ?? decoded['message']?.toString()
            : 'Falha ao excluir';
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

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(label, icon),
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
        title: const Text('Odontólogos'),
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
            : _odontologos.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 18),
                    Text('Nenhum odontólogo cadastrado ainda.'),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _odontologos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final odontologo = _odontologos[index];
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
                                  odontologo['nome']?.toString() ?? 'Sem nome',
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
                                onPressed: () =>
                                    _showOdontologoDialog(odontologo),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFF50057),
                                ),
                                onPressed: () => _deleteOdontologo(odontologo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Especialidade: ${odontologo['especialidade'] ?? '-'}',
                          ),
                          const SizedBox(height: 4),
                          Text('CRO: ${odontologo['cro'] ?? '-'}'),
                          const SizedBox(height: 4),
                          Text(
                            'Salário: R\$ ${odontologo['salario']?.toString() ?? '0.00'}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOdontologoDialog(),
        icon: const Icon(Icons.add_sharp),
        label: const Text('Novo odontólogo'),
      ),
    );
  }
}
