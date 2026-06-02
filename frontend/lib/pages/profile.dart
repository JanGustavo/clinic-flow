import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.sessionToken});

  final String? sessionToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static String get _backendBaseUrl {
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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _senhaRepeatController = TextEditingController();

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _sessionToken;

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
        final prefs = await SharedPreferences.getInstance();
        _sessionToken = prefs.getString('session_token');
      }

      if (_sessionToken == null || _sessionToken!.isEmpty) {
        setState(() {
          _errorMessage = 'Sessão expirada. Faça login novamente.';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('$_backendBaseUrl/usuarios/perfil');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _profileData = data is Map<String, dynamic> ? data : null;
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

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileData == null || _profileData!['id'] == null) {
      _mostrarMensagem('Dados do usuário não estão disponíveis.', false);
      return;
    }

    final id = _profileData!['id'];
    final tipo = _profileData!['tipo']?.toString() ?? 'PACIENTE';
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final senhaRepeat = _senhaRepeatController.text.trim();

    if (senha.isNotEmpty && senha != senhaRepeat) {
      _mostrarMensagem('As senhas não coincidem.', false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('$_backendBaseUrl/usuarios/$id');
      final body = {
        'nome': nome,
        'email': email,
        'tipo': tipo,
        if (senha.isNotEmpty) 'senha': senha,
        if (senha.isNotEmpty) 'senha_repeat': senhaRepeat,
      };

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        _mostrarMensagem('Dados atualizados com sucesso.', true);
        await _carregarPerfil();
      } else {
        final data = jsonDecode(response.body);
        final error =
            data['error'] ?? data['message'] ?? 'Erro ao salvar perfil.';
        _mostrarMensagem(error.toString(), false);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Falha ao atualizar perfil: $e', false);
      debugPrint('Profile update error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');

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
                    'Atualize seu cadastro sempre que necessário.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            label: 'Nome',
                            value:
                                _profileData?['nome']?.toString() ??
                                'Não informado',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            label: 'Tipo de conta',
                            value:
                                _profileData?['tipo']?.toString() ?? 'Paciente',
                            icon: Icons.verified_user,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildField(
                          label: 'Nome completo',
                          controller: _nomeController,
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Informe um nome válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'E-mail',
                          controller: _emailController,
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'E-mail inválido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Nova senha',
                          controller: _senhaController,
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Confirmar senha',
                          controller: _senhaRepeatController,
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _salvarPerfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Salvar alterações',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.logout,
                              color: Color(0xFF212529),
                            ),
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
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
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
