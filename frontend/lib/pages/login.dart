import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/pages/home.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para capturar os dados
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Função para enviar o POST para a API
  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Endpoint da sua API Flask (Ajuste o IP/URL conforme seu ambiente)
    final url = Uri.parse('http://127.0.0.1:5000/auth/login');

    final Map<String, dynamic> payload = {
      "email": _emailController.text.trim(),
      "senha": _senhaController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final body = _tryParseJson(response.body);

      if (!mounted) return;

      final sucesso =
          response.statusCode == 200 &&
          (body?['success'] == true || body?['data'] != null);

      if (sucesso) {
        final data = body?['data'];
        final mensagem = data is Map<String, dynamic>
            ? (data['message']?.toString() ?? 'Login realizado com sucesso!')
            : 'Login realizado com sucesso!';
        final token = data is Map<String, dynamic>
            ? data['token']?.toString()
            : null;

        if (token != null && token.isNotEmpty) {
          await _salvarToken(token);
        }

        if (!mounted) return;
        _mostrarSucesso(mensagem);

        // Redireciona para a página de home após login bem-sucedido
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomePage(sessionToken: token)),
          (route) => false,
        );
      } else {
        final mensagem =
            body?['error']?.toString() ??
            body?['message']?.toString() ??
            'Falha ao fazer login.';
        _mostrarErro(mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Login error: $e');
      _mostrarErro('Falha ao finalizar login: ${e.runtimeType}');
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

  Future<void> _salvarToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_token', token);
    } catch (e) {
      debugPrint('Session token not persisted: $e');
    }
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
                            "Login",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "Acesse sua conta e continue",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 32),

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
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _fazerLogin(),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pushNamed('/forgot'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Esqueci minha senha'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Botão de Login com gradiente Chiclete (Blue & Pink)
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
                              onPressed: _isLoading ? null : _fazerLogin,
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
                                      "Entrar",
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
                                "Ainda não tem conta?",
                                style: TextStyle(color: colorMuted),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(
                                        context,
                                      ).pushNamed('/register'),
                                child: const Text("Cadastre-se"),
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
