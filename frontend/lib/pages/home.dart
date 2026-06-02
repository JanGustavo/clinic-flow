import 'package:flutter/material.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Dicas de saúde para o card dinâmico (Saúde Bucal)
  final List<String> _dicasSaude = [
    "Escovar os dentes após cada refeição e usar o fio dental diariamente previne cáries e mantém o sorriso perfeito!",
    "Visite seu dentista a cada 6 meses para realizar uma limpeza preventiva e check-up completo.",
    "Troque sua escova de dentes a cada 3 meses ou assim que as cerdas começarem a deformar.",
    "Evite o consumo excessivo de doces e refrigerantes, pois o açúcar acelera a proliferação de bactérias.",
    "Beba bastante água! A água ajuda na salivação, que protege naturalmente seus dentes de cáries e mau hálito."
  ];
  int _dicaAtualIndex = 0;

  // Campanhas e serviços em destaque
  final List<Map<String, String>> _campanhas = [
    {
      "titulo": "Clareamento a Laser",
      "subtitulo": "Sorriso radiante e confiante",
      "desconto": "20% OFF neste mês",
      "cor": "0xFF00B4D8", // Cyan / Chiclete
    },
    {
      "titulo": "Alinhadores Invisíveis",
      "subtitulo": "Ortodontia moderna e discreta",
      "desconto": "Avaliação Cortesia",
      "cor": "0xFFF50057", // Neon Pink
    },
    {
      "titulo": "Implantes Dentários",
      "subtitulo": "Sua autoestima de volta",
      "desconto": "Condições especiais",
      "cor": "0xFF7209B7", // Deep Purple
    }
  ];

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
        _sessionError = 'Sessão indisponível';
        _isLoadingSession = false;
      });
      debugPrint('Session load failed: $e');
    }
  }

  Future<void> _fazerLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_token');
      if (!mounted) return;
      setState(() {
        _sessionToken = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão encerrada com sucesso!'),
          backgroundColor: Color(0xFF00B4D8),
        ),
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  bool get _sessaoAtiva => _sessionToken != null && _sessionToken!.isNotEmpty;

  void _proximaDica() {
    setState(() {
      _dicaAtualIndex = (_dicaAtualIndex + 1) % _dicasSaude.length;
    });
  }

  void _mostrarContatoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 10),
            const Text("Falar Conosco", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Deseja iniciar um atendimento exclusivo via WhatsApp com nossa equipe para tirar dúvidas ou fazer agendamentos?",
          style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redirecionando para o suporte...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Conversar"),
          ),
        ],
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
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorPrimary, colorSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
              accountName: const Text(
                'Sorriso Perfeito',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(
                _sessaoAtiva ? 'Paciente Conectado' : 'Acesse para mais opções',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: colorPrimary),
                    title: const Text('Início', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.medical_services_outlined, color: colorPrimary),
                    title: const Text('Minhas Consultas', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/exames');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.healing_outlined, color: colorPrimary),
                    title: const Text('Nossos Procedimentos', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/procedimentos');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: colorPrimary),
                    title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                  const Divider(),
                  if (_sessaoAtiva) ...[
                    ListTile(
                      leading: const Icon(Icons.exit_to_app_outlined, color: colorSecondary),
                      title: const Text(
                        'Sair da Conta',
                        style: TextStyle(fontWeight: FontWeight.w600, color: colorSecondary),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _fazerLogout();
                      },
                    ),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.login_outlined, color: colorPrimary),
                      title: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/login');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_outlined, color: colorPrimary),
                      title: const Text('Cadastrar-se', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/register');
                      },
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'v1.0.0 • Sorriso Perfeito',
                style: TextStyle(color: colorMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/branding/sorriso_perfeito.svg',
          height: 48,
          fit: BoxFit.contain,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: colorPrimary, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sessaoAtiva ? Icons.account_circle_rounded : Icons.login_rounded,
              color: _sessaoAtiva ? colorPrimary : colorSecondary,
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Hero Principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [colorPrimary, Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Seu sorriso ideal",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                "começa aqui",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Cuidamos da sua saúde bucal com tecnologia de ponta, afeto e a excelência que você e sua família merecem.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Status da Sessão
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isLoadingSession
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              children: [
                                Icon(
                                  _sessaoAtiva ? Icons.verified_rounded : Icons.info_outline_rounded,
                                  color: _sessaoAtiva ? Colors.greenAccent : Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _sessaoAtiva
                                        ? "Sessão Ativa • Bem-vindo!"
                                        : "Nenhum paciente conectado",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                if (!_sessaoAtiva)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/login');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: colorPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      "Acessar",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Ações Rápidas",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorText,
                ),
              ),
              const SizedBox(height: 12),
              // Grid de Ações
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: "Agendar\nConsulta",
                      subtitle: "Marque seu horário",
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFEFF7FF),
                      iconColor: colorPrimary,
                      onTap: () => Navigator.of(context).pushNamed('/exames'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: "Nossos\nProcedimentos",
                      subtitle: "Tratamentos e valores",
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFFFFF0F5),
                      iconColor: colorSecondary,
                      onTap: () => Navigator.of(context).pushNamed('/procedimentos'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: "Minhas\nConsultas",
                      subtitle: "Veja seus exames",
                      icon: Icons.folder_shared_rounded,
                      color: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7209B7),
                      onTap: () => Navigator.of(context).pushNamed('/exames'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: "Falar com\nAtendente",
                      subtitle: "Suporte via WhatsApp",
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFFE8F5E9),
                      iconColor: Colors.green,
                      onTap: () => _mostrarContatoDialog(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),
              const Text(
                "Tratamentos em Destaque",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorText,
                ),
              ),
              const SizedBox(height: 12),
              // Campanhas Carousel
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _campanhas.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final campanha = _campanhas[index];
                    final cor = Color(int.parse(campanha["cor"]!));
                    return Container(
                      width: 240,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [cor, cor.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campanha["titulo"]!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                campanha["subtitulo"]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              campanha["desconto"]!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),
              // Card Dica de Saúde Bucal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorSecondary.withOpacity(0.12), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colorSecondary.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: colorSecondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Dica de Saúde Bucal",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colorText,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: colorSecondary, size: 16),
                          onPressed: _proximaDica,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Próxima dica",
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _dicasSaude[_dicaAtualIndex],
                        key: ValueKey<int>(_dicaAtualIndex),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: colorMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),
              // Unidade / Endereço da clínica
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                      "Nossa Clínica",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: colorText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, color: colorPrimary, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Epitácio Pessoa, 123 - João Pessoa, PB",
                            style: TextStyle(fontSize: 12.5, color: colorMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.phone_outlined, color: colorPrimary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "(83) 3254-7600",
                          style: TextStyle(fontSize: 12.5, color: colorMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: colorPrimary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Seg. a Sex. das 8h às 20h | Sáb. das 8h às 12h",
                          style: TextStyle(fontSize: 12.5, color: colorMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarContatoDialog(context),
        backgroundColor: colorSecondary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212529),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
