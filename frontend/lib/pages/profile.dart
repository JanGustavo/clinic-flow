import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _sessionToken;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _userId;
  String _userName = 'Paciente Sorriso';
  String _userEmail = 'paciente@sorrisoperfeito.com';
  String _userRole = 'PACIENTE';

  // Campos extras do paciente vindos do backend
  String _pacienteCpf = '';
  String _pacienteTelefone = '';
  String _pacienteCep = '';
  String _pacienteLogradouro = '';
  String _pacienteNumero = '';
  String _pacienteBairro = '';
  String _pacienteCidade = '';
  String _pacienteEstado = '';
  String _pacienteDataNascimento = '';

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers para edição
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cpfController;
  late TextEditingController _birthDateController;
  late TextEditingController _cepController;
  late TextEditingController _addressController;
  late TextEditingController _numberController;
  late TextEditingController _bairroController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cpfController = TextEditingController();
    _birthDateController = TextEditingController();
    _cepController = TextEditingController();
    _addressController = TextEditingController();
    _numberController = TextEditingController();
    _bairroController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();

    _carregarSessaoETabular();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _bairroController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _carregarSessaoETabular() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('session_token');
      if (token != null && token.isNotEmpty) {
        _sessionToken = token;
        _decodeJWT(token);
        await _buscarDadosDoBackend();
      }
    } catch (e) {
      debugPrint('Failed to load profile session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        final parsedId = int.tryParse(token);
        if (parsedId != null) {
          setState(() {
            _userId = parsedId;
          });
          debugPrint('Token parsed directly as user ID: $_userId');
        } else {
          debugPrint('Token is not a 3-part string and not an integer');
        }
        return;
      }

      Map<String, dynamic>? data;

      // 1. Tentar decodificar parte 0 (itsdangerous / URLSafeTimedSerializer do Flask)
      try {
        final decoded = _decodeBase64(parts[0]);
        if (decoded != null && decoded.startsWith('{') && decoded.endsWith('}')) {
          data = jsonDecode(decoded);
          debugPrint('Token parsed successfully as itsdangerous token!');
        }
      } catch (_) {}

      // 2. Tentar decodificar parte 1 (JWT padrão)
      if (data == null) {
        try {
          final decoded = _decodeBase64(parts[1]);
          if (decoded != null && decoded.startsWith('{') && decoded.endsWith('}')) {
            data = jsonDecode(decoded);
            debugPrint('Token parsed successfully as standard JWT!');
          }
        } catch (_) {}
      }

      if (data == null) {
        debugPrint('Failed to decode token payload in both itsdangerous and JWT formats');
        return;
      }

      setState(() {
        final idVal = data?['id'] ?? data?['userId'] ?? data?['sub'];
        if (idVal != null) {
          _userId = int.tryParse(idVal.toString());
        }
        _userName = data?['name']?.toString() ?? data?['nome']?.toString() ?? 'Paciente Sorriso';
        _userEmail = data?['email']?.toString() ?? data?['sub']?.toString() ?? 'paciente@sorrisoperfeito.com';
        _userRole = data?['tipo']?.toString() ?? data?['role']?.toString() ?? 'PACIENTE';
      });
    } catch (_) {
      debugPrint('Error parsing session token');
    }
  }

  String? _decodeBase64(String input) {
    try {
      var normalized = input;
      switch (normalized.length % 4) {
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      List<int> bytes;
      try {
        bytes = base64Url.decode(normalized);
      } catch (_) {
        bytes = base64.decode(normalized);
      }
      return utf8.decode(bytes, allowMalformed: true).trim();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    return {
      'Authorization': 'Bearer $_sessionToken',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _buscarDadosDoBackend() async {
    if (_userId == null) return;
    
    final headers = await _getAuthHeaders();
    
    // 1. Buscar dados de usuário (GET /usuarios/<id>)
    try {
      final userUri = Uri.parse('$_backendBaseUrl/usuarios/$_userId');
      final userResponse = await http.get(userUri, headers: headers);
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        if (userData is Map<String, dynamic>) {
          setState(() {
            _userName = userData['nome']?.toString() ?? _userName;
            _userEmail = userData['email']?.toString() ?? _userEmail;
            _userRole = userData['tipo']?.toString() ?? _userRole;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do usuário: $e');
    }

    // 2. Buscar dados de paciente (GET /pacientes/<id>)
    try {
      final pacienteUri = Uri.parse('$_backendBaseUrl/pacientes/$_userId');
      final pacResponse = await http.get(pacienteUri, headers: headers);
      if (pacResponse.statusCode == 200) {
        final pacData = jsonDecode(pacResponse.body);
        if (pacData is Map<String, dynamic>) {
          setState(() {
            _pacienteCpf = pacData['cpf']?.toString() ?? '';
            _pacienteTelefone = pacData['telefone']?.toString() ?? '';
            _pacienteCep = pacData['cep']?.toString() ?? '';
            _pacienteLogradouro = pacData['logradouro']?.toString() ?? '';
            _pacienteNumero = pacData['numero_casa']?.toString() ?? '';
            _pacienteBairro = pacData['bairro']?.toString() ?? '';
            _pacienteCidade = pacData['cidade']?.toString() ?? '';
            _pacienteEstado = pacData['estado']?.toString() ?? '';
            _pacienteDataNascimento = pacData['data_nascimento']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados de paciente: $e');
    }

    // Inicializar controllers com dados atualizados
    _nameController.text = _userName;
    _emailController.text = _userEmail;
    _phoneController.text = _pacienteTelefone;
    _cpfController.text = _pacienteCpf;
    _cepController.text = _pacienteCep;
    _addressController.text = _pacienteLogradouro;
    _numberController.text = _pacienteNumero;
    _bairroController.text = _pacienteBairro;
    _cityController.text = _pacienteCidade;
    _stateController.text = _pacienteEstado;

    if (_pacienteDataNascimento.isNotEmpty) {
      _birthDateController.text = _pacienteDataNascimento.split('T')[0];
    } else {
      _birthDateController.text = '';
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() {
      _isSaving = true;
    });

    final headers = await _getAuthHeaders();
    bool sucessoUsuario = false;
    bool sucessoPaciente = false;

    // 1. Atualizar usuário (PUT /usuarios/<id>)
    try {
      final userUri = Uri.parse('$_backendBaseUrl/usuarios/$_userId');
      final userPayload = {
        "nome": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "tipo": _userRole.toUpperCase(),
      };

      final userResponse = await http.put(
        userUri,
        headers: headers,
        body: jsonEncode(userPayload),
      );

      if (userResponse.statusCode == 200) {
        sucessoUsuario = true;
        setState(() {
          _userName = _nameController.text.trim();
          _userEmail = _emailController.text.trim();
        });
      } else {
        final body = jsonDecode(userResponse.body);
        _mostrarErro(body['error']?.toString() ?? 'Erro ao atualizar usuário.');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
      _mostrarErro('Falha na comunicação com o servidor.');
    }

    // 2. Atualizar paciente (PUT /pacientes/<id>)
    try {
      final pacienteUri = Uri.parse('$_backendBaseUrl/pacientes/$_userId');
      final pacPayload = {
        "nome": _nameController.text.trim(),
        "data_nascimento": _birthDateController.text.trim().isNotEmpty
            ? _birthDateController.text.trim()
            : "1990-01-01",
        "cpf": _cpfController.text.trim().isNotEmpty
            ? _cpfController.text.trim()
            : "00000000000",
        "telefone": _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : "0000000000",
        "cep": _cepController.text.trim(),
        "logradouro": _addressController.text.trim(),
        "numero_casa": _numberController.text.trim(),
        "bairro": _bairroController.text.trim(),
        "cidade": _cityController.text.trim(),
        "estado": _stateController.text.trim(),
      };

      final pacResponse = await http.put(
        pacienteUri,
        headers: headers,
        body: jsonEncode(pacPayload),
      );

      if (pacResponse.statusCode == 200) {
        sucessoPaciente = true;
        setState(() {
          _pacienteTelefone = _phoneController.text.trim();
          _pacienteCpf = _cpfController.text.trim();
          _pacienteCep = _cepController.text.trim();
          _pacienteLogradouro = _addressController.text.trim();
          _pacienteNumero = _numberController.text.trim();
          _pacienteBairro = _bairroController.text.trim();
          _pacienteCidade = _cityController.text.trim();
          _pacienteEstado = _stateController.text.trim();
          _pacienteDataNascimento = _birthDateController.text.trim();
        });
      } else if (pacResponse.statusCode == 404) {
        // Se retornar 404, significa que é um usuário sem registro na tabela de pacientes ainda.
        // Como o update de paciente não cria se não existir, tratamos suavemente.
        sucessoPaciente = true;
      } else {
        final body = jsonDecode(pacResponse.body);
        _mostrarErro(body['error']?.toString() ?? 'Erro ao atualizar dados clínicos.');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar paciente: $e');
    }

    setState(() {
      _isSaving = false;
    });

    if (sucessoUsuario || sucessoPaciente) {
      setState(() {
        _isEditing = false;
      });
      _mostrarSucesso('Perfil atualizado com sucesso!');
      await _buscarDadosDoBackend();
    }
  }

  Future<void> _fazerLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_token');
      if (!mounted) return;
      _mostrarSucesso('Sessão encerrada.');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  Future<void> _selecionarDataNascimento(BuildContext context) async {
    final DateTime? selecionado = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_pacienteDataNascimento.split('T')[0]) ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00B4D8),
              onPrimary: Colors.white,
              onSurface: Color(0xFF212529),
            ),
          ),
          child: child!,
        );
      },
    );
    if (selecionado != null) {
      setState(() {
        _birthDateController.text =
            "${selecionado.year}-${selecionado.month.toString().padLeft(2, '0')}-${selecionado.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00B4D8)),
    );
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFF50057)),
    );
  }

  bool get _sessaoAtiva => _sessionToken != null && _sessionToken!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8F9FA);
    const colorPrimary = Color(0xFF00B4D8);
    const colorSecondary = Color(0xFFF50057);
    const colorText = Color(0xFF212529);
    const colorMuted = Color(0xFF6C757D);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: colorBg,
        body: Center(
          child: CircularProgressIndicator(color: colorPrimary),
        ),
      );
    }

    if (!_sessaoAtiva) {
      return Scaffold(
        backgroundColor: colorBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: colorPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F9FA), Color(0xFFEFF7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorSecondary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: colorSecondary,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Área Restrita",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Faça login ou crie uma conta para visualizar e gerenciar seu perfil bucal na Sorriso Perfeito.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorMuted, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [colorPrimary, colorSecondary],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Entrar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed('/register'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: colorPrimary, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Criar Conta",
                          style: TextStyle(
                            color: colorPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final initials = _userName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _isEditing ? 'Editar Perfil' : 'Meu Perfil',
          style: const TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: colorPrimary),
          onPressed: () {
            if (_isEditing) {
              setState(() => _isEditing = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: colorPrimary),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, color: colorSecondary),
              onPressed: () => setState(() => _isEditing = false),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Cartão do Perfil / Avatar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [colorPrimary, Color(0xFF0077B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimary.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: colorSecondary.withOpacity(0.1),
                            child: Text(
                              initials.isNotEmpty ? initials : 'P',
                              style: const TextStyle(
                                color: colorSecondary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userRole.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isEditing)
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Dados de Acesso",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              decoration: _buildInputDecoration("Nome Completo", Icons.person_outline, colorPrimary),
                              validator: (value) => value == null || value.trim().length < 3 ? "Nome deve ter 3+ letras" : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              keyboardType: TextInputType.emailAddress,
                              decoration: _buildInputDecoration("E-mail", Icons.mail_outline, colorPrimary),
                              validator: (value) => value == null || !value.contains('@') ? "E-mail inválido" : null,
                            ),
                            
                            const SizedBox(height: 24),
                            const Text(
                              "Dados Pessoais",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cpfController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration("CPF (somente números)", Icons.badge_outlined, colorPrimary),
                              validator: (value) {
                                if (value == null || value.isEmpty) return null; // opcional se vazio
                                final cleaned = value.replaceAll(RegExp(r'\D'), '');
                                if (cleaned.length != 11) return "CPF deve conter exatamente 11 dígitos";
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              keyboardType: TextInputType.phone,
                              decoration: _buildInputDecoration("Telefone / Celular", Icons.phone_android_outlined, colorPrimary),
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final cleaned = value.replaceAll(RegExp(r'\D'), '');
                                if (cleaned.length < 10) return "Telefone deve conter DDD + número";
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _birthDateController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              readOnly: true,
                              onTap: () => _selecionarDataNascimento(context),
                              decoration: _buildInputDecoration("Data de Nascimento", Icons.cake_outlined, colorPrimary).copyWith(
                                suffixIcon: const Icon(Icons.calendar_month_rounded, color: colorPrimary),
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Text(
                              "Endereço Residencial",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cepController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration("CEP", Icons.map_outlined, colorPrimary),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _addressController,
                                    style: const TextStyle(color: colorText, fontSize: 13.5),
                                    decoration: _buildInputDecoration("Logradouro", Icons.home_outlined, colorPrimary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _numberController,
                                    style: const TextStyle(color: colorText, fontSize: 13.5),
                                    decoration: _buildInputDecoration("Nº", Icons.tag_rounded, colorPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _bairroController,
                              style: const TextStyle(color: colorText, fontSize: 13.5),
                              decoration: _buildInputDecoration("Bairro", Icons.location_city_outlined, colorPrimary),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _cityController,
                                    style: const TextStyle(color: colorText, fontSize: 13.5),
                                    decoration: _buildInputDecoration("Cidade", Icons.location_on_outlined, colorPrimary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _stateController,
                                    style: const TextStyle(color: colorText, fontSize: 13.5),
                                    maxLength: 2,
                                    decoration: _buildInputDecoration("UF", Icons.flag_outlined, colorPrimary).copyWith(
                                      counterText: "",
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),
                            _isSaving
                                ? const Center(child: CircularProgressIndicator(color: colorSecondary))
                                : Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      gradient: const LinearGradient(
                                        colors: [colorPrimary, colorSecondary],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _salvarAlteracoes,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: const Text(
                                        "Salvar no Servidor",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Aba Dados Pessoais
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Dados Cadastrais",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(Icons.mail_outline_rounded, "E-mail de Contato", _userEmail, colorPrimary),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.phone_iphone_rounded, 
                            "Telefone", 
                            _pacienteTelefone.isNotEmpty ? _pacienteTelefone : "Não informado", 
                            colorPrimary
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.badge_outlined, 
                            "CPF", 
                            _pacienteCpf.isNotEmpty ? _pacienteCpf : "Não informado", 
                            colorPrimary
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.cake_outlined, 
                            "Data de Nascimento", 
                            _pacienteDataNascimento.isNotEmpty ? _pacienteDataNascimento.split('T')[0] : "Não informada", 
                            colorPrimary
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Aba Endereço Residencial
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Endereço Residencial",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            Icons.home_outlined, 
                            "Logradouro", 
                            _pacienteLogradouro.isNotEmpty 
                                ? "$_pacienteLogradouro, nº $_pacienteNumero" 
                                : "Não informado", 
                            colorSecondary
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.location_city_outlined, 
                            "Bairro", 
                            _pacienteBairro.isNotEmpty ? _pacienteBairro : "Não informado", 
                            colorSecondary
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.location_on_outlined, 
                            "Cidade / UF", 
                            _pacienteCidade.isNotEmpty 
                                ? "$_pacienteCidade - $_pacienteEstado" 
                                : "Não informado", 
                            colorSecondary
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F3F5)),
                          _buildDetailRow(
                            Icons.map_outlined, 
                            "CEP", 
                            _pacienteCep.isNotEmpty ? _pacienteCep : "Não informado", 
                            colorSecondary
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Atalhos / Configurações
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Atalhos Rápidos",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorText),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF7FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_month_rounded, color: colorPrimary, size: 20),
                            ),
                            title: const Text("Minhas Consultas", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: const Text("Veja agendamentos e histórico", style: TextStyle(fontSize: 10.5)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorMuted),
                            onTap: () => Navigator.of(context).pushNamed('/exames'),
                          ),
                          const Divider(height: 16, color: Color(0xFFF1F3F5)),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_reset_rounded, color: colorSecondary, size: 20),
                            ),
                            title: const Text("Redefinir Senha", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: const Text("Altere a senha da sua conta", style: TextStyle(fontSize: 10.5)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorMuted),
                            onTap: () => Navigator.of(context).pushNamed('/forgot'),
                          ),
                          const Divider(height: 16, color: Color(0xFFF1F3F5)),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 20),
                            ),
                            title: const Text("Sair da Conta", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Colors.red)),
                            subtitle: const Text("Encerrar sessão ativa neste dispositivo", style: TextStyle(fontSize: 10.5)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.redAccent),
                            onTap: _fazerLogout,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF6C757D)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF212529)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, Color activeColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: activeColor, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: activeColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFFF50057)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFFF50057), width: 1.8),
      ),
    );
  }
}
