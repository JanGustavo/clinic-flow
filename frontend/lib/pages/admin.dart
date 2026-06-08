import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';
import 'package:frontend/pages/consultas.dart'; // For CpfInputFormatter

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _odontologos = [];
  List<Map<String, dynamic>> _consultas = [];
  List<Map<String, dynamic>> _especialidades = [];
  List<Map<String, dynamic>> _usuariosDisponiveis = []; // Users that can be linked to Odontologos

  // Loading flags
  bool _isLoadingUsuarios = false;
  bool _isLoadingPacientes = false;
  bool _isLoadingOdontologos = false;
  bool _isLoadingConsultas = false;

  // Search queries
  String _searchUsuario = '';
  String _searchPaciente = '';
  String _searchOdontologo = '';
  String _searchConsulta = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadTabCachedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _loadTabCachedData();
  }

  void _loadTabCachedData() {
    switch (_tabController.index) {
      case 0:
        _fetchUsuarios();
        break;
      case 1:
        _fetchPacientes();
        break;
      case 2:
        _fetchOdontologos();
        _fetchEspecialidades();
        _fetchUsuariosDisponiveis();
        break;
      case 3:
        _fetchConsultas();
        break;
    }
  }

  // --- API CALLS ---

  Future<Map<String, String>> _headers() async {
    return await BackendService.authHeaders();
  }

  Future<void> _fetchUsuarios() async {
    if (mounted) setState(() => _isLoadingUsuarios = true);
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/usuarios'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            _usuarios = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingUsuarios = false);
  }

  Future<void> _fetchPacientes() async {
    if (mounted) setState(() => _isLoadingPacientes = true);
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/pacientes'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            _pacientes = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPacientes = false);
  }

  Future<void> _fetchOdontologos() async {
    if (mounted) setState(() => _isLoadingOdontologos = true);
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/odontologos'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            _odontologos = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingOdontologos = false);
  }

  Future<void> _fetchEspecialidades() async {
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/especialidades'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            _especialidades = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUsuariosDisponiveis() async {
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/usuarios'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            // Filter users who are ODONTOLOGO role (or ADMIN) and not already linked
            final allUsers = List<Map<String, dynamic>>.from(list);
            _usuariosDisponiveis = allUsers.where((u) {
              final type = u['tipo']?.toString().toUpperCase() ?? '';
              final isDoctorRole = type == 'ODONTOLOGO' || type == 'ADMIN';
              final alreadyLinked = _odontologos.any((o) => o['id_usuario'] == u['id']);
              return isDoctorRole && !alreadyLinked;
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchConsultas() async {
    if (mounted) setState(() => _isLoadingConsultas = true);
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/consultas'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        if (mounted && list is List) {
          setState(() {
            _consultas = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingConsultas = false);
  }

  // --- CRUD ACTIONS ---

  Future<void> _deleteItem(String endpoint, int id, VoidCallback onSuccess) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este registro permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF50057)),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await http.delete(
          Uri.parse('${BackendService.baseUrl}/$endpoint/$id'),
          headers: await _headers(),
        );
        if (res.statusCode == 200 || res.statusCode == 204) {
          _showToast('Registro excluído com sucesso!', true);
          onSuccess();
        } else {
          final body = jsonDecode(res.body);
          _showToast(body['error']?.toString() ?? 'Erro ao excluir.', false);
        }
      } catch (e) {
        _showToast('Erro de conexão: $e', false);
      }
    }
  }

  void _showToast(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : const Color(0xFFF50057),
      ),
    );
  }

  // --- INPUT DECORATION HELPER ---

  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
      ),
    );
  }

  // --- DIALOGS ---

  // 1. USUARIO DIALOG
  Future<void> _showUsuarioDialog([Map<String, dynamic>? user]) async {
    final isEdit = user != null;
    final nomeCtrl = TextEditingController(text: user?['nome'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final senhaCtrl = TextEditingController();
    final senhaRepeatCtrl = TextEditingController();
    String tipo = user?['tipo']?.toString().toUpperCase() ?? 'PACIENTE';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Usuário' : 'Novo Usuário'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeCtrl,
                    decoration: _inputDeco('Nome', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: _inputDeco('E-mail', Icons.email_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    decoration: _inputDeco('Tipo de Acesso', Icons.admin_panel_settings_outlined),
                    items: const [
                      DropdownMenuItem(value: 'PACIENTE', child: Text('Paciente')),
                      DropdownMenuItem(value: 'ODONTOLOGO', child: Text('Odontólogo')),
                      DropdownMenuItem(value: 'RECEPCIONISTA', child: Text('Recepcionista')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (val) {
                      if (val != null) tipo = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: senhaCtrl,
                    obscureText: true,
                    decoration: _inputDeco('Senha', Icons.lock_outline, hint: isEdit ? 'Deixe em branco para manter' : null),
                    validator: (v) {
                      if (!isEdit && (v == null || v.isEmpty)) return 'Informe a senha';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: senhaRepeatCtrl,
                    obscureText: true,
                    decoration: _inputDeco('Confirmar Senha', Icons.lock_clock_outlined),
                    validator: (v) {
                      if (senhaCtrl.text.isNotEmpty && v != senhaCtrl.text) {
                        return 'As senhas não coincidem';
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
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);

                      final payload = {
                        'nome': nomeCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'tipo': tipo,
                      };
                      if (senhaCtrl.text.isNotEmpty) {
                        payload['senha'] = senhaCtrl.text;
                        payload['senha_repeat'] = senhaRepeatCtrl.text;
                      }

                      try {
                        final res = isEdit
                            ? await http.put(
                                Uri.parse('${BackendService.baseUrl}/usuarios/${user['id']}'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              )
                            : await http.post(
                                Uri.parse('${BackendService.baseUrl}/usuarios'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          _showToast(isEdit ? 'Atualizado!' : 'Criado!', true);
                          Navigator.of(ctx).pop();
                          _fetchUsuarios();
                        } else {
                          final body = jsonDecode(res.body);
                          _showToast(body['error']?.toString() ?? 'Ocorreu um erro.', false);
                        }
                      } catch (e) {
                        _showToast('Conexão falhou: $e', false);
                      }
                      setDialogState(() => saving = false);
                    },
              child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // 2. PACIENTE DIALOG
  Future<void> _showPacienteDialog([Map<String, dynamic>? paciente]) async {
    final isEdit = paciente != null;
    final nomeCtrl = TextEditingController(text: paciente?['nome'] ?? '');
    final dataNascCtrl = TextEditingController();
    final cpfCtrl = TextEditingController(text: paciente?['cpf'] ?? '');
    final telefoneCtrl = TextEditingController(text: paciente?['telefone'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    if (isEdit && paciente?['data_nascimento'] != null) {
      final raw = paciente?['data_nascimento']?.toString() ?? '';
      try {
        final parts = raw.split('-');
        if (parts.length == 3) {
          dataNascCtrl.text = '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Paciente' : 'Novo Paciente'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeCtrl,
                    decoration: _inputDeco('Nome Completo', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dataNascCtrl,
                    readOnly: true,
                    decoration: _inputDeco('Data de Nascimento', Icons.cake_outlined, hint: 'dd/mm/aaaa'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 3650)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        dataNascCtrl.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                    },
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe a data' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cpfCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfInputFormatter()],
                    decoration: _inputDeco('CPF', Icons.badge_outlined, hint: '000.000.000-00'),
                    validator: (v) => v == null || v.replaceAll(RegExp(r'\D'), '').length != 11 ? 'CPF inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco('Telefone', Icons.phone_outlined, hint: 'DDD + Número'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o telefone' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);

                      final birthText = dataNascCtrl.text.trim();
                      final birthParts = birthText.split('/');
                      final formattedBirth = '${birthParts[2]}-${birthParts[1].padLeft(2, '0')}-${birthParts[0].padLeft(2, '0')}';

                      final payload = {
                        'nome': nomeCtrl.text.trim(),
                        'data_nascimento': formattedBirth,
                        'cpf': cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
                        'telefone': telefoneCtrl.text.trim(),
                      };

                      try {
                        final res = isEdit
                            ? await http.put(
                                Uri.parse('${BackendService.baseUrl}/pacientes/${paciente['id']}'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              )
                            : await http.post(
                                Uri.parse('${BackendService.baseUrl}/pacientes'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          _showToast(isEdit ? 'Atualizado!' : 'Criado!', true);
                          Navigator.of(ctx).pop();
                          _fetchPacientes();
                        } else {
                          final body = jsonDecode(res.body);
                          _showToast(body['error']?.toString() ?? 'Ocorreu um erro.', false);
                        }
                      } catch (e) {
                        _showToast('Conexão falhou: $e', false);
                      }
                      setDialogState(() => saving = false);
                    },
              child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. ODONTOLOGO DIALOG
  Future<void> _showOdontologoDialog([Map<String, dynamic>? odontologo]) async {
    final isEdit = odontologo != null;
    final nomeCtrl = TextEditingController(text: odontologo?['nome'] ?? '');
    final croCtrl = TextEditingController(text: odontologo?['cro'] ?? '');
    final salarioCtrl = TextEditingController(
      text: odontologo?['salario']?.toString() ?? '5000.00',
    );
    int? specId = odontologo?['id_especialidade'];
    int? userId = odontologo?['id_usuario'];
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    // Set initial value for specId if not null and matches list
    if (specId != null && !_especialidades.any((s) => s['id'] == specId)) {
      specId = null;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Dentista' : 'Novo Dentista'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeCtrl,
                    decoration: _inputDeco('Nome do Odontólogo', Icons.medical_services_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: croCtrl,
                    decoration: _inputDeco('CRO', Icons.badge_outlined, hint: 'Ex: 12345-UF'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o CRO' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: salarioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Salário (R\$)', Icons.attach_money_outlined),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Valor inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: specId,
                    decoration: _inputDeco('Especialidade', Icons.star_border_outlined),
                    items: _especialidades.map((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(s['nome']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => specId = val),
                    validator: (v) => v == null ? 'Selecione uma especialidade' : null,
                  ),
                  const SizedBox(height: 12),
                  if (!isEdit)
                    DropdownButtonFormField<int>(
                      value: userId,
                      decoration: _inputDeco('Usuário de Link', Icons.link_outlined),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Sem link de usuário')),
                        ..._usuariosDisponiveis.map((u) {
                          return DropdownMenuItem<int>(
                            value: u['id'] as int,
                            child: Text('${u['nome']} (${u['email']})'),
                          );
                        }),
                      ],
                      onChanged: (val) => setDialogState(() => userId = val),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);

                      final payload = {
                        'nome': nomeCtrl.text.trim(),
                        'cro': croCtrl.text.trim(),
                        'salario': double.parse(salarioCtrl.text),
                        'id_especialidade': specId,
                      };
                      if (!isEdit && userId != null) {
                        payload['id_usuario'] = userId;
                      }

                      try {
                        final res = isEdit
                            ? await http.put(
                                Uri.parse('${BackendService.baseUrl}/odontologos/${odontologo['id']}'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              )
                            : await http.post(
                                Uri.parse('${BackendService.baseUrl}/odontologos'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          _showToast(isEdit ? 'Atualizado!' : 'Criado!', true);
                          Navigator.of(ctx).pop();
                          _fetchOdontologos();
                        } else {
                          final body = jsonDecode(res.body);
                          _showToast(body['error']?.toString() ?? 'Ocorreu um erro.', false);
                        }
                      } catch (e) {
                        _showToast('Conexão falhou: $e', false);
                      }
                      setDialogState(() => saving = false);
                    },
              child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // 4. CONSULTA DIALOG
  Future<void> _showConsultaDialog([Map<String, dynamic>? consulta]) async {
    final isEdit = consulta != null;
    final motivoCtrl = TextEditingController(text: consulta?['motivo'] ?? 'Consulta Geral');
    final valorCtrl = TextEditingController(
      text: consulta?['valor']?.toString() ?? '150.00',
    );
    final dataHoraCtrl = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));
    int? pacienteId = consulta?['id_paciente'];
    int? odontologoId = consulta?['id_odontologo'];
    int? responsavelId = consulta?['id_usuario_responsavel'] ?? 1; // Default fallback to system root/admin user
    String prioridade = consulta?['prioridade']?.toString().toUpperCase() ?? 'MEDIA';
    String status = consulta?['status']?.toString().toUpperCase() ?? 'PENDENTE';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    if (isEdit && consulta?['data_hora'] != null) {
      final raw = consulta?['data_hora']?.toString() ?? '';
      try {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          selectedDateTime = parsed;
          dataHoraCtrl.text =
              '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        }
      } catch (_) {}
    } else {
      dataHoraCtrl.text =
          '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Consulta' : 'Nova Consulta'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: pacienteId,
                    decoration: _inputDeco('Paciente', Icons.person_outline),
                    items: _pacientes.map((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['nome']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => pacienteId = val),
                    validator: (v) => v == null ? 'Selecione um paciente' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: odontologoId,
                    decoration: _inputDeco('Odontólogo', Icons.medical_services_outlined),
                    items: _odontologos.map((o) {
                      return DropdownMenuItem<int>(
                        value: o['id'] as int,
                        child: Text(o['nome']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => odontologoId = val),
                    validator: (v) => v == null ? 'Selecione um odontólogo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dataHoraCtrl,
                    readOnly: true,
                    decoration: _inputDeco('Data e Hora', Icons.access_time_outlined),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      if (!ctx.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time == null) return;

                      final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      setDialogState(() {
                        selectedDateTime = newDt;
                        dataHoraCtrl.text =
                            '${newDt.day.toString().padLeft(2, '0')}/${newDt.month.toString().padLeft(2, '0')}/${newDt.year} ${newDt.hour.toString().padLeft(2, '0')}:${newDt.minute.toString().padLeft(2, '0')}';
                      });
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Selecione data/hora' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: motivoCtrl,
                    decoration: _inputDeco('Motivo/Sintomas', Icons.comment_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o motivo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Valor (R\$)', Icons.attach_money_outlined),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Valor inválido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: prioridade,
                    decoration: _inputDeco('Prioridade', Icons.priority_high_outlined),
                    items: const [
                      DropdownMenuItem(value: 'BAIXA', child: Text('Baixa')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                      DropdownMenuItem(value: 'URGENTE', child: Text('Urgente')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => prioridade = val);
                    },
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: _inputDeco('Status', Icons.check_circle_outline),
                      items: const [
                        DropdownMenuItem(value: 'PENDENTE', child: Text('Pendente')),
                        DropdownMenuItem(value: 'CONFIRMADA', child: Text('Confirmada')),
                        DropdownMenuItem(value: 'CANCELADA', child: Text('Cancelada')),
                        DropdownMenuItem(value: 'CONCLUIDA', child: Text('Concluída')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);

                      final formattedDate =
                          '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}:00';

                      final payload = {
                        'id_paciente': pacienteId,
                        'id_odontologo': odontologoId,
                        'id_usuario_responsavel': responsavelId,
                        'data_hora': formattedDate,
                        'motivo': motivoCtrl.text.trim(),
                        'valor': double.parse(valorCtrl.text),
                        'prioridade': prioridade,
                      };
                      if (isEdit) {
                        payload['status'] = status;
                      }

                      try {
                        final res = isEdit
                            ? await http.put(
                                Uri.parse('${BackendService.baseUrl}/consultas/${consulta['id']}'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              )
                            : await http.post(
                                Uri.parse('${BackendService.baseUrl}/consultas'),
                                headers: await _headers(),
                                body: jsonEncode(payload),
                              );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          _showToast(isEdit ? 'Atualizado!' : 'Criado!', true);
                          Navigator.of(ctx).pop();
                          _fetchConsultas();
                        } else {
                          final body = jsonDecode(res.body);
                          _showToast(body['error']?.toString() ?? 'Ocorreu um erro.', false);
                        }
                      } catch (e) {
                        _showToast('Conexão falhou: $e', false);
                      }
                      setDialogState(() => saving = false);
                    },
              child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB-WIDGET LIST RENDERERS ---

  Widget _buildSearchBar(String hint, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00B4D8)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTabUsuarios() {
    final filtered = _usuarios.where((u) {
      final text = '${u['nome']} ${u['email']} ${u['tipo']}'.toLowerCase();
      return text.contains(_searchUsuario.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Buscar usuários por nome, email ou perfil...', (val) {
          setState(() => _searchUsuario = val);
        }),
        Expanded(
          child: _isLoadingUsuarios
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, idx) {
                        final u = filtered[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF00B4D8).withOpacity(0.12),
                              child: Text(
                                (u['nome']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4D8)),
                              ),
                            ),
                            title: Text(u['nome']?.toString() ?? 'Usuário Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(u['email']?.toString() ?? ''),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B4D8).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    u['tipo']?.toString().toUpperCase() ?? 'PACIENTE',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8)),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showUsuarioDialog(u)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('usuarios', u['id'], _fetchUsuarios)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTabPacientes() {
    final filtered = _pacientes.where((p) {
      final text = '${p['nome']} ${p['cpf']}'.toLowerCase();
      return text.contains(_searchPaciente.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Buscar pacientes por nome ou CPF...', (val) {
          setState(() => _searchPaciente = val);
        }),
        Expanded(
          child: _isLoadingPacientes
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Nenhum paciente encontrado.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, idx) {
                        final p = filtered[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withOpacity(0.12),
                              child: const Icon(Icons.person, color: Colors.purple),
                            ),
                            title: Text(p['nome']?.toString() ?? 'Paciente Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('CPF: ${p['cpf']?.toString() ?? ''}'),
                                Text('Tel: ${p['telefone']?.toString() ?? ''}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showPacienteDialog(p)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('pacientes', p['id'], _fetchPacientes)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTabOdontologos() {
    final filtered = _odontologos.where((o) {
      final text = '${o['nome']} ${o['cro']} ${o['especialidade']}'.toLowerCase();
      return text.contains(_searchOdontologo.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Buscar dentistas por nome, CRO ou especialidade...', (val) {
          setState(() => _searchOdontologo = val);
        }),
        Expanded(
          child: _isLoadingOdontologos
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Nenhum odontólogo encontrado.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, idx) {
                        final o = filtered[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withOpacity(0.12),
                              child: const Icon(Icons.medical_services_outlined, color: Colors.teal),
                            ),
                            title: Text(o['nome']?.toString() ?? 'Dentista Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('CRO: ${o['cro']?.toString() ?? ''}'),
                                Text('Especialidade: ${o['especialidade']?.toString() ?? 'Geral'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showOdontologoDialog(o)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('odontologos', o['id'], _fetchOdontologos)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTabConsultas() {
    final filtered = _consultas.where((c) {
      final text = '${c['paciente']} ${c['odontologo']} ${c['motivo']} ${c['status']}'.toLowerCase();
      return text.contains(_searchConsulta.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchBar('Buscar consultas por paciente, dentista ou motivo...', (val) {
          setState(() => _searchConsulta = val);
        }),
        Expanded(
          child: _isLoadingConsultas
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('Nenhuma consulta encontrada.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, idx) {
                        final c = filtered[idx];

                        // Parse date
                        String rawDt = c['data_hora']?.toString() ?? '';
                        String displayDate = rawDt;
                        try {
                          final parsed = DateTime.tryParse(rawDt);
                          if (parsed != null) {
                            displayDate =
                                '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
                          }
                        } catch (_) {}

                        // Status Color
                        Color statusColor = Colors.grey;
                        switch (c['status']?.toString().toUpperCase()) {
                          case 'CONFIRMADA':
                            statusColor = Colors.green;
                            break;
                          case 'CANCELADA':
                            statusColor = Colors.red;
                            break;
                          case 'CONCLUIDA':
                            statusColor = Colors.blue;
                            break;
                          default:
                            statusColor = Colors.orange;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.12),
                              child: Icon(Icons.calendar_month, color: statusColor),
                            ),
                            title: Text(
                              '${c['paciente']?.toString() ?? 'Paciente'} c/ Dr(a). ${c['odontologo']?.toString() ?? 'Dentista'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Data: $displayDate', style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('Motivo: ${c['motivo']?.toString() ?? ''}'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    c['status']?.toString().toUpperCase() ?? 'PENDENTE',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showConsultaDialog(c)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('consultas', c['id'], _fetchConsultas)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // --- FLOATING ACTION BUTTON ---

  Widget? _buildFab() {
    VoidCallback? onPressed;
    String tooltip = '';

    switch (_tabController.index) {
      case 0:
        onPressed = () => _showUsuarioDialog();
        tooltip = 'Adicionar Usuário';
        break;
      case 1:
        onPressed = () => _showPacienteDialog();
        tooltip = 'Adicionar Paciente';
        break;
      case 2:
        onPressed = () => _showOdontologoDialog();
        tooltip = 'Adicionar Dentista';
        break;
      case 3:
        onPressed = () => _showConsultaDialog();
        tooltip = 'Adicionar Consulta';
        break;
    }

    if (onPressed == null) return null;

    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: const Color(0xFF00B4D8),
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(tooltip.split(' ').last, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      appBar: AppBar(
        title: const Text('Painel de Controle Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00B4D8),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Usuários'),
            Tab(icon: Icon(Icons.person_outline), text: 'Pacientes'),
            Tab(icon: Icon(Icons.medical_services_outlined), text: 'Dentistas'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Consultas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabUsuarios(),
          _buildTabPacientes(),
          _buildTabOdontologos(),
          _buildTabConsultas(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}
