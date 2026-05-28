import 'package:flutter/material.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.sessionToken});

  final String? sessionToken;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _sessionToken;
  String? _sessionError;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    if (widget.sessionToken != null && widget.sessionToken!.isNotEmpty) {
      _sessionToken = widget.sessionToken;
      _isLoadingSession = false;
      return;
    }
    _carregarSessao();
  }

  Future<void> _carregarSessao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('session_token');
      if (!mounted) return;
      setState(() {
        _sessionToken = token;
        _isLoadingSession = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionError = 'Sessao indisponivel';
        _isLoadingSession = false;
      });
      debugPrint('Session load failed: $e');
    }
  }

  bool get _sessaoAtiva => _sessionToken != null && _sessionToken!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final sessionColor = _sessaoAtiva ? Colors.green : Colors.grey;
    final sessionText = _sessaoAtiva ? 'Sessao ativa' : 'Sem sessao';
    final errorText = _sessionError ?? 'Sessao indisponivel';

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlueAccent),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Exames'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/exames');
              },
            ),
            ListTile(
              leading: const Icon(Icons.healing_outlined),
              title: const Text('Procedimentos'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/procedimentos');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Sorriso Perfeito',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlueAccent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Olá, Flutter!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            if (_isLoadingSession)
              const CircularProgressIndicator()
            else if (_sessionError != null)
              Chip(
                avatar: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                label: Text(errorText),
              )
            else
              Chip(
                avatar: Icon(
                  _sessaoAtiva ? Icons.verified_rounded : Icons.info_outline,
                  color: sessionColor,
                ),
                label: Text(sessionText),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Login (debug)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Register (debug)'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
