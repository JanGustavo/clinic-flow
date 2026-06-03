import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _isLoadingProfile = true;
  String? _profileError;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    if (widget.sessionToken != null && widget.sessionToken!.isNotEmpty) {
      _sessionToken = widget.sessionToken;
      _isLoadingSession = false;
      _carregarPerfil();
      return;
    }
    _carregarSessao();
  }

  Future<void> _carregarSessao() async {
    try {
      final token = await BackendService.readToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        setState(() {
          _sessionToken = token;
          _sessionError = 'Sessão não encontrada. Faça login novamente.';
          _isLoadingSession = false;
          _isLoadingProfile = false;
        });
        return;
      }

      setState(() {
        _sessionToken = token;
        _isLoadingSession = false;
      });

      await _carregarPerfil();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionError = 'Sessão indisponível';
        _isLoadingSession = false;
        _isLoadingProfile = false;
      });
      debugPrint('Session load failed: $e');
    }
  }

  Future<void> _carregarPerfil() async {
    if (_sessionToken == null || _sessionToken!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Sessão não encontrada. Faça login novamente.';
        _isLoadingProfile = false;
      });
      return;
    }

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
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
        final data = jsonDecode(response.body);
        setState(() {
          _profileData = data is Map<String, dynamic> ? data : null;
          _profileError = null;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _profileError = 'Falha ao carregar perfil (${response.statusCode})';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Erro ao carregar perfil: $e';
        _isLoadingProfile = false;
      });
      debugPrint('Profile load error: $e');
    }
  }

  bool get _sessaoAtiva => _sessionToken != null && _sessionToken!.isNotEmpty;

  String get _userName => _profileData?['nome']?.toString() ?? 'Usuário';
  String get _userRole =>
      _profileData?['tipo']?.toString().toUpperCase() ?? 'PACIENTE';

  bool hasRole(String role) => _userRole == role.toUpperCase();

  Future<void> _logout() async {
    await BackendService.clearToken();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8F9FA);
    const colorPrimary = Color(0xFF00B4D8);
    final errorText = _sessionError ?? 'Sessão indisponível';

    return Scaffold(
      backgroundColor: colorBg,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: colorPrimary),
              currentAccountPicture: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/branding/sorriso_perfeito.svg',
                  fit: BoxFit.contain,
                ),
              ),
              accountName: Text(
                _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                _sessaoAtiva ? 'Paciente conectado' : 'Acesse para mais opções',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home_outlined,
              label: 'Início',
              onTap: () => Navigator.of(context).pop(),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/perfil');
              },
            ),
            _buildDrawerItem(
              icon: Icons.calendar_month_outlined,
              label: 'Consultas',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/consultas');
              },
            ),
            if (!hasRole('PACIENTE'))
              _buildDrawerItem(
                icon: Icons.healing_outlined,
                label: 'Procedimentos',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/procedimentos');
                },
              ),
            if (hasRole('ADMIN'))
              _buildDrawerItem(
                icon: Icons.group_outlined,
                label: 'Usuários',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidade de gestão de usuários ainda em implantação.',
                      ),
                    ),
                  );
                },
              ),
            const Divider(),
            _buildDrawerItem(icon: Icons.logout, label: 'Sair', onTap: _logout),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B4D8),
        centerTitle: true,
        title: const Text(
          'Sorriso Perfeito',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingSession || _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : _sessionError != null
            ? _buildStatusMessage(errorText, Colors.orange)
            : _profileError != null
            ? _buildStatusMessage(_profileError!, Colors.redAccent)
            : _buildDashboard(context),
      ),
    );
  }

  Widget _buildStatusMessage(String message, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 68, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
              ),
              child: const Text('Voltar ao login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_userName',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Bem-vindo ao painel do ${_roleLabel()}.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildChip('Perfil', Icons.person, const Color(0xFF00B4D8)),
              _buildChip(
                _userRole,
                Icons.verified_user,
                const Color(0xFF2196F3),
              ),
              _buildChip(
                _sessaoAtiva ? 'Sessão ativa' : 'Sessão pendente',
                _sessaoAtiva ? Icons.lock_open : Icons.lock,
                _sessaoAtiva ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Principais ações'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _buildQuickActions(context),
          ),
          const SizedBox(height: 28),
          _buildSectionTitle('Painel inicial'),
          const SizedBox(height: 12),
          _buildRoleSummaryCard(),
        ],
      ),
    );
  }

  String _roleLabel() {
    switch (_userRole) {
      case 'ADMIN':
        return 'Administrador';
      case 'RECEPCIONISTA':
        return 'Recepcionista';
      case 'ODONTOLOGO':
        return 'Odontólogo';
      default:
        return 'Paciente';
    }
  }

  List<Widget> _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];

    actions.add(
      _buildFeatureCard(
        title: 'Meu Perfil',
        subtitle: 'Atualize seus dados e verifique seu cadastro',
        icon: Icons.person,
        onTap: () => Navigator.of(context).pushNamed('/perfil'),
      ),
    );

    actions.add(
      _buildFeatureCard(
        title: 'Consultas',
        subtitle: 'Veja suas consultas marcadas',
        icon: Icons.calendar_month,
        onTap: () => Navigator.of(context).pushNamed('/consultas'),
      ),
    );

    if (!hasRole('PACIENTE')) {
      actions.add(
        _buildFeatureCard(
          title: 'Procedimentos',
          subtitle: 'Conheça os procedimentos disponíveis',
          icon: Icons.healing,
          onTap: () => Navigator.of(context).pushNamed('/procedimentos'),
        ),
      );
    }

    if (hasRole('PACIENTE')) {
      actions.add(
        _buildFeatureCard(
          title: 'Procedimentos Recomendados',
          subtitle: 'Veja os procedimentos do seu último atendimento',
          icon: Icons.medical_services,
          onTap: () =>
              Navigator.of(context).pushNamed('/procedimentos_recomendados'),
        ),
      );
    }

    if (hasRole('ADMIN')) {
      actions.add(
        _buildFeatureCard(
          title: 'Gestão de usuários',
          subtitle: 'Perfis, acesso e permissões',
          icon: Icons.group,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gestão de usuários será liberada em breve.'),
              ),
            );
          },
        ),
      );
    }

    if (hasRole('RECEPCIONISTA')) {
      actions.add(
        _buildFeatureCard(
          title: 'Cadastrar paciente',
          subtitle: 'Registre novos pacientes com facilidade',
          icon: Icons.person_add,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastro de paciente ainda não implementado.'),
              ),
            );
          },
        ),
      );
    }

    if (hasRole('ODONTOLOGO')) {
      actions.add(
        _buildFeatureCard(
          title: 'Agenda do dia',
          subtitle: 'Acesse rapidamente sua agenda clínico',
          icon: Icons.schedule,
          onTap: () => Navigator.of(context).pushNamed('/consultas'),
        ),
      );
    }

    if (hasRole('PACIENTE')) {
      actions.add(
        _buildFeatureCard(
          title: 'Meus procedimentos',
          subtitle: 'Consulte os procedimentos recomendados',
          icon: Icons.medical_information,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Procedimentos pessoais em breve.')),
            );
          },
        ),
      );
    }

    return actions;
  }

  Widget _buildRoleSummaryCard() {
    final summaryText = _roleSummaryText();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          summaryText,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      ),
    );
  }

  String _roleSummaryText() {
    switch (_userRole) {
      case 'ADMIN':
        return 'Como administrador, você pode supervisionar usuários, consultar a agenda clínica e validar procedimentos. O painel mostra somente as operações autorizadas ao seu perfil.';
      case 'RECEPCIONISTA':
        return 'Como recepcionista, você tem acesso rápido às consultas, ao cadastro de pacientes e ao suporte para agendamentos. Apenas funcionalidades permitidas aparecem neste menu.';
      case 'ODONTOLOGO':
        return 'Como odontólogo, você tem acesso à sua agenda, procedimentos e perfil profissional. Use este painel para acessar rapidamente as informações clínicas mais relevantes.';
      default:
        return 'Como paciente, você pode ver suas consultas, atualizar seu perfil e acompanhar as informações do seu atendimento. Funcionalidades administrativas foram ocultadas para seu perfil.';
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: const Color(0xFF00B4D8)),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChip(String text, IconData icon, Color background) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      backgroundColor: background,
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
