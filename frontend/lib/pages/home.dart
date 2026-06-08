import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

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

  Map<String, dynamic>? _normalizeApiData(dynamic responseJson) {
    if (responseJson is Map<String, dynamic>) {
      if (responseJson['data'] is Map<String, dynamic>) {
        return responseJson['data'] as Map<String, dynamic>;
      }
      if (responseJson['success'] == true &&
          responseJson['data'] is Map<String, dynamic>) {
        return responseJson['data'] as Map<String, dynamic>;
      }
    }
    return responseJson is Map<String, dynamic> ? responseJson : null;
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
        final payload = jsonDecode(response.body);
        final data = _normalizeApiData(payload);
        setState(() {
          _profileData = data;
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

  String _getAvatarInitials() {
    final nome = _profileData?['nome']?.toString().trim() ?? '';
    if (nome.isEmpty) return 'U';
    final partes = nome
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'U';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes[0][0] + partes.last[0]).toUpperCase();
  }

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
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.network(
                    'https://ui-avatars.com/api/?name=${_getAvatarInitials()}&size=128&background=E6F0FF&color=00B4D8&bold=true',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        _getAvatarInitials(),
                        style: const TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
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
                _sessaoAtiva
                    ? (_profileData?['email']?.toString() ??
                          '${_roleLabel()} conectado')
                    : 'Acesse para mais opções',
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
            _buildDrawerItem(
              icon: Icons.attach_money_outlined,
              label: 'Tabela de Preços',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/procedimentos');
              },
            ),

            if (hasRole('ADMIN'))
              _buildDrawerItem(
                icon: Icons.admin_panel_settings,
                label: 'Paínel ADMIN',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/admin');
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
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Sorriso Perfeito',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner / Hero card with linear gradient and shadow
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0077B6).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: ClipOval(
                        child: Image.network(
                          'https://ui-avatars.com/api/?name=${_getAvatarInitials()}&size=128&background=E6F0FF&color=00B4D8&bold=true',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              _getAvatarInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $_userName',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Painel do ${_roleLabel()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildModernBadge(
                      icon: Icons.verified_user,
                      label: _userRole,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(width: 10),
                    _buildModernBadge(
                      icon: _sessaoAtiva ? Icons.lock_open : Icons.lock,
                      label: _sessaoAtiva ? 'Sessão ativa' : 'Pendente',
                      color: _sessaoAtiva
                          ? Colors.green.shade400.withOpacity(0.25)
                          : Colors.orange.shade400.withOpacity(0.25),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Principais ações'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double gridWidth = constraints.maxWidth;
              final int cols = gridWidth < 600 ? 1 : (gridWidth < 900 ? 2 : 3);
              const double spacing = 16.0;
              final double itemWidth =
                  (gridWidth - (cols - 1) * spacing) / cols;
              const double itemHeight = 100.0;
              final double aspectRatio = itemWidth / itemHeight;
              final actions = _buildQuickActions(context);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) => actions[index],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Painel informativo'),
          const SizedBox(height: 16),
          _buildRoleSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildModernBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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

    return actions;
  }

  Widget _buildRoleSummaryCard() {
    final summaryText = _roleSummaryText();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF00B4D8), width: 5),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF00B4D8),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo do Perfil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summaryText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00B4D8)),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF2B2D42),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: const Color(0xFF00B4D8).withOpacity(0.05),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B4D8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF00B4D8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2D42),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF00B4D8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2D42),
          ),
        ),
      ],
    );
  }
}
