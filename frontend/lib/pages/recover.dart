import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _senhaRepeatController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSenha = true;
  static const Color colorBgPastelStart = Color(0xFFE0F2FE); // Soft pastel blue
  static const Color colorBgPastelEnd = Color(0xFFFCE4EC);   // Soft pastel pink

  @override
  void dispose() {
    _tokenController.dispose();
    _senhaController.dispose();
    _senhaRepeatController.dispose();
    super.dispose();
  }

  Future<void> _fazerRecuperacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('${BackendService.baseUrl}/auth/redefinir-senha');
    final payload = {
      'senha': _senhaController.text.trim(),
      'senha_repeat': _senhaRepeatController.text.trim(),
      'token': _tokenController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = _tryParseJson(response.body);

      if (!mounted) return;

      final sucesso = response.statusCode == 200 || response.statusCode == 201;
      if (sucesso) {
        final mensagem =
            body?['message']?.toString() ?? 'Senha redefinida com sucesso.';
        _mostrarSucesso(mensagem);
        Navigator.of(context).pop();
      } else {
        final mensagem =
            body?['error']?.toString() ??
            body?['message']?.toString() ??
            'Falha ao redefinir senha.';
        _mostrarErro(mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Redefinição de senha error: $e');
      _mostrarErro('Falha ao finalizar redefinição de senha: ${e.runtimeType}');
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
    const colorPrimary = Color(0xFF00B4D8);
    const colorSecondary = Color(0xFFF50057);
    const colorText = Color(0xFF212529);
    const colorMuted = Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: colorBgPastelStart,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [colorBgPastelStart, colorBgPastelEnd],
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            'Redefinir Senha',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorText,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Use o token recebido por e-mail para definir uma nova senha.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _tokenController,
                            style: const TextStyle(color: colorText),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: _buildInputDecoration(
                              'Token',
                              Icons.vpn_key_outlined,
                              colorPrimary,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Token obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _senhaController,
                            style: const TextStyle(color: colorText),
                            obscureText: _obscureSenha,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration:
                                _buildInputDecoration(
                                  'Nova senha',
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
                                ? 'A senha deve ter 6+ caracteres'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _senhaRepeatController,
                            style: const TextStyle(color: colorText),
                            obscureText: _obscureSenha,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _fazerRecuperacao(),
                            decoration: _buildInputDecoration(
                              'Confirmar nova senha',
                              Icons.lock_reset_outlined,
                              colorPrimary,
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'A confirmação deve ter 6+ caracteres';
                              }

                              if (value != _senhaController.text) {
                                return 'As senhas não conferem';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
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
                              onPressed: _isLoading ? null : _fazerRecuperacao,
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
                                      'Redefinir senha',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Voltar para o login'),
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
      fillColor: const Color(0xFFF8F9FA),
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
