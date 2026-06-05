import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/pages/login.dart';
import 'package:frontend/services/backend_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.sessionToken});

  final String? sessionToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _senhaRepeatController = TextEditingController();

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _sessionToken;

  // Controle de edição por campo
  bool _editingNome = false;
  bool _editingEmail = false;
  bool _editingSenha = false;
  bool _savingNome = false;
  bool _savingEmail = false;
  bool _savingSenha = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.sessionToken;
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _senhaRepeatController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_sessionToken == null || _sessionToken!.isEmpty) {
        _sessionToken = await BackendService.readToken();
      }

      if (_sessionToken == null || _sessionToken!.isEmpty) {
        setState(() {
          _errorMessage = 'Sessão expirada. Faça login novamente.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('${BackendService.baseUrl}/usuarios/perfil');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final data =
            payload is Map<String, dynamic> &&
                payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload is Map<String, dynamic>
            ? payload
            : null;
        _profileData = data;
        _nomeController.text = _profileData?['nome']?.toString() ?? '';
        _emailController.text = _profileData?['email']?.toString() ?? '';
        setState(() {
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sessão expirada. Faça login novamente.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar perfil: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _salvarCampo(String campo, String valor) async {
    if (_profileData == null || _profileData!['id'] == null) {
      _mostrarMensagem('Dados do usuário não estão disponíveis.', false);
      return;
    }

    final id = _profileData!['id'];
    final tipo = _profileData!['tipo']?.toString() ?? 'PACIENTE';

    setState(() {
      if (campo == 'nome') _savingNome = true;
      if (campo == 'email') _savingEmail = true;
      if (campo == 'senha') _savingSenha = true;
    });

    try {
      final uri = Uri.parse('${BackendService.baseUrl}/usuarios/$id');
      final Map<String, dynamic> body = {
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'tipo': tipo,
      };

      if (campo == 'senha' && valor.isNotEmpty) {
        body['senha'] = _senhaController.text.trim();
        body['senha_repeat'] = _senhaRepeatController.text.trim();
      }

      if (_sessionToken == null || _sessionToken!.isEmpty) {
        _sessionToken = await BackendService.readToken();
      }
      final headers = await BackendService.authHeaders(_sessionToken);
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        _mostrarMensagem('$campo atualizado com sucesso!', true);
        setState(() {
          _editingNome = false;
          _editingEmail = false;
          _editingSenha = false;
          if (campo == 'senha') {
            _senhaController.clear();
            _senhaRepeatController.clear();
          }
        });
      } else {
        final data = jsonDecode(response.body);
        final error =
            data['error'] ?? data['message'] ?? 'Erro ao salvar $campo.';
        _mostrarMensagem(error.toString(), false);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Falha ao atualizar $campo: $e', false);
      debugPrint('Update $campo error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingNome = false;
          _savingEmail = false;
          _savingSenha = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await BackendService.clearToken();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _mostrarMensagem(String mensagem, bool sucesso) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: sucesso
            ? const Color(0xFF00B4D8)
            : const Color(0xFFF50057),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8F9FA);
    const colorPrimary = Color(0xFF00B4D8);
    const colorSecondary = Color(0xFFF50057);
    const colorText = Color(0xFF212529);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Meu Perfil'),
        backgroundColor: colorPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorSecondary),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorSecondary,
                    ),
                    child: const Text(
                      'Fazer Login Novamente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorPrimary.withOpacity(0.18),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 56,
                        color: colorPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dados do perfil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no ícone de edição para atualizar seus dados.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  // Informações estáticas
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            label: 'Tipo de conta',
                            value:
                                _profileData?['tipo']?.toString() ?? 'Paciente',
                            icon: Icons.verified_user,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            label: 'ID do usuário',
                            value: _profileData?['id']?.toString() ?? '—',
                            icon: Icons.badge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Campos editáveis
                  _buildEditableField(
                    label: 'Nome completo',
                    icon: Icons.person,
                    isEditing: _editingNome,
                    isSaving: _savingNome,
                    controller: _nomeController,
                    onEdit: () => setState(() => _editingNome = !_editingNome),
                    onSave: () => _salvarCampo('nome', _nomeController.text),
                    onCancel: () {
                      setState(() => _editingNome = false);
                      _nomeController.text =
                          _profileData?['nome']?.toString() ?? '';
                    },
                    colorPrimary: colorPrimary,
                  ),
                  const SizedBox(height: 14),
                  _buildEditableField(
                    label: 'E-mail',
                    icon: Icons.email,
                    isEditing: _editingEmail,
                    isSaving: _savingEmail,
                    controller: _emailController,
                    onEdit: () =>
                        setState(() => _editingEmail = !_editingEmail),
                    onSave: () => _salvarCampo('email', _emailController.text),
                    onCancel: () {
                      setState(() => _editingEmail = false);
                      _emailController.text =
                          _profileData?['email']?.toString() ?? '';
                    },
                    colorPrimary: colorPrimary,
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    isEditing: _editingSenha,
                    isSaving: _savingSenha,
                    onEdit: () =>
                        setState(() => _editingSenha = !_editingSenha),
                    onSave: () => _salvarCampo('senha', _senhaController.text),
                    onCancel: () {
                      setState(() => _editingSenha = false);
                      _senhaController.clear();
                      _senhaRepeatController.clear();
                    },
                    colorPrimary: colorPrimary,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.logout, color: Color(0xFF212529)),
                      label: const Text(
                        'Sair',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF212529),
                        ),
                      ),
                      onPressed: _logout,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required bool isEditing,
    required bool isSaving,
    required TextEditingController controller,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required Color colorPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEditing ? colorPrimary : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isEditing)
                        Text(
                          controller.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF00B4D8)),
                    onPressed: onEdit,
                    tooltip: 'Editar $label',
                  ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required bool isEditing,
    required bool isSaving,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required Color colorPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEditing ? colorPrimary : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: colorPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alterar senha',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isEditing)
                        const Text(
                          '••••••••',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF00B4D8)),
                    onPressed: onEdit,
                    tooltip: 'Alterar senha',
                  ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _senhaRepeatController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF00B4D8).withOpacity(0.12),
          child: Icon(icon, color: const Color(0xFF00B4D8)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
