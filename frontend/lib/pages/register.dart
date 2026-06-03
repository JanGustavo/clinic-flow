import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/backend_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para capturar os dados
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _senhaRepeatController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureSenhaRepeat = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _senhaRepeatController.dispose();
    super.dispose();
  }

  // Função para enviar o POST para a API
  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('${BackendService.baseUrl}/usuarios/registrar');

    // Payload idêntico ao solicitado, injetando PACIENTE implicitamente
    final Map<String, dynamic> payload = {
      "nome": _nomeController.text.trim(),
      "email": _emailController.text.trim(),
      "senha": _senhaController.text.trim(),
      "senha_repeat": _senhaRepeatController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final body = _tryParseJson(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        final mensagem =
            body?['message']?.toString() ??
            body?['data']?.toString() ??
            'Conta criada com sucesso!';
        _mostrarSucesso(mensagem);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        final mensagem =
            body?['error']?.toString() ??
            body?['message']?.toString() ??
            'Falha ao cadastrar.';
        _mostrarErro(mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro de conexão com o servidor.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _tryParseJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF00B4D8),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFFF50057),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cores da paleta Neo-Pastel Chiclete
    const colorBg = Color(0xFFF8F9FA); // Off-white clínico
    const colorPrimary = Color(0xFF00B4D8); // Azul Ciano/Chiclete
    const colorSecondary = Color(0xFFF50057); // Rosa Neon/Magenta (Acentos)
    const colorText = Color(0xFF212529); // Grafite Escuro
    const colorMuted = Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F9FA), Color(0xFFEFF7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header / Logo estilizado
                          Center(
                            child: Semantics(
                              label: 'Sorriso Perfeito',
                              child: SvgPicture.asset(
                                'assets/branding/sorriso_perfeito.svg',
                                height: 110,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Criar Conta",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Crie sua conta e comece agora",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 32),

                          // Campo: Nome
                          TextFormField(
                            controller: _nomeController,
                            style: const TextStyle(color: colorText),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: _buildInputDecoration(
                              "Nome Completo",
                              Icons.person_outline,
                              colorPrimary,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? "Digite seu nome"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Campo: Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: colorText),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _buildInputDecoration(
                              "E-mail",
                              Icons.mail_outline,
                              colorPrimary,
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? "E-mail inválido"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Campo: Senha
                          TextFormField(
                            controller: _senhaController,
                            style: const TextStyle(color: colorText),
                            obscureText: _obscureSenha,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration:
                                _buildInputDecoration(
                                  "Senha",
                                  Icons.lock_outline,
                                  colorPrimary,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSenha
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: colorPrimary,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureSenha = !_obscureSenha,
                                    ),
                                  ),
                                ),
                            validator: (value) =>
                                value == null || value.length < 6
                                ? "A senha deve ter 6+ caracteres"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Campo: Confirmar Senha
                          TextFormField(
                            controller: _senhaRepeatController,
                            style: const TextStyle(color: colorText),
                            obscureText: _obscureSenhaRepeat,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _cadastrarUsuario(),
                            decoration:
                                _buildInputDecoration(
                                  "Confirmar Senha",
                                  Icons.lock_reset,
                                  colorPrimary,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSenhaRepeat
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: colorPrimary,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureSenhaRepeat =
                                          !_obscureSenhaRepeat,
                                    ),
                                  ),
                                ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirme sua senha";
                              }
                              if (value != _senhaController.text) {
                                return "As senhas não conferem";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Botão de Cadastro com gradiente Chiclete (Blue & Pink)
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [colorPrimary, colorSecondary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorPrimary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _cadastrarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "CADASTRAR",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Já tem conta?",
                                style: TextStyle(color: colorMuted),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/login'),
                                child: const Text("Entrar"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper para manter o design clean e padronizado dos inputs
  InputDecoration _buildInputDecoration(
    String label,
    IconData icon,
    Color activeColor,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: activeColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: activeColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFF50057)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFF50057), width: 2),
      ),
    );
  }
}
