import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_service.dart';

class ProcedimentosScreen extends StatefulWidget {
  const ProcedimentosScreen({super.key, this.sessionToken, this.consultaId});

  final String? sessionToken;
  final int? consultaId;

  @override
  State<ProcedimentosScreen> createState() => _ProcedimentosScreenState();
}

class _ProcedimentosScreenState extends State<ProcedimentosScreen> {
  final List<ProcedimentoItem> _procedimentos = [];
  ProcedimentoItem? _procedimentoSelecionado;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  double _lerValor(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      final normalizado = valor.replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();
    _carregarProcedimentos();
  }

  Future<void> _carregarProcedimentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final url = Uri.parse('${BackendService.baseUrl}/procedimentos');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawList = decoded is Map<String, dynamic> && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final List<dynamic> listaJson = rawList is List ? rawList : [];
        final lista = listaJson
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => ProcedimentoItem(
                id: item['id'] is int
                    ? item['id'] as int
                    : int.tryParse('${item['id']}') ?? 0,
                nome: item['nome']?.toString() ?? '',
                valor: _lerValor(item['valor']),
              ),
            )
            .toList();

        if (!mounted) return;
        setState(() {
          _procedimentos
            ..clear()
            ..addAll(lista);
          if (lista.isNotEmpty) {
            _procedimentoSelecionado = lista.first;
          } else {
            _procedimentoSelecionado = null;
          }
          _carregando = false;
          _erro = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _erro =
              'Erro ao carregar procedimentos. Status code: ${response.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar procedimentos: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _vincularProcedimentoDireto() async {
    final consultaId = widget.consultaId;
    final procedimento = _procedimentoSelecionado;
    if (consultaId == null || procedimento == null) return;

    setState(() {
      _salvando = true;
    });

    final url = Uri.parse(
      '${BackendService.baseUrl}/consultas/$consultaId/procedimentos',
    );

    try {
      final headers = await BackendService.authHeaders();
      final body = jsonEncode({
        'id_procedimento': procedimento.id,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Procedimento "${procedimento.nome}" adicionado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg = decoded is Map<String, dynamic>
            ? decoded['error']?.toString() ?? decoded['message']?.toString()
            : null;

        setState(() {
          _erro = errorMsg ?? 'Falha ao vincular procedimento (${response.statusCode})';
          _salvando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro de rede: $e';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.consultaId != null) {
      return _buildAdicionarForm();
    }
    return _buildPrecosList();
  }

  Widget _buildAdicionarForm() {
    const colorBg = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B4D8),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Vincular Procedimento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8), // Card mais quadrado!
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4D8).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_task_outlined,
                          size: 32,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Adicionar Procedimento',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2D42),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Vincular à Consulta #${widget.consultaId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_carregando)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_erro != null) ...[
                      Text(
                        _erro!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarProcedimentos,
                        child: const Text('Recarregar'),
                      ),
                    ] else ...[
                      DropdownButtonFormField<ProcedimentoItem>(
                        value: _procedimentoSelecionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Selecione o Exame/Procedimento',
                          prefixIcon: const Icon(
                            Icons.medical_services_outlined,
                            color: Color(0xFF00B4D8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF00B4D8),
                              width: 2,
                            ),
                          ),
                        ),
                        items: _procedimentos.map((proc) {
                          return DropdownMenuItem<ProcedimentoItem>(
                            value: proc,
                            child: Text(
                              proc.nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _procedimentoSelecionado = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Valor do Serviço:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _procedimentoSelecionado != null
                                  ? 'R\$ ${_procedimentoSelecionado!.valor.toStringAsFixed(2)}'
                                  : 'R\$ 0,00',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _salvando || _procedimentoSelecionado == null
                            ? null
                            : _vincularProcedimentoDireto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _salvando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar e Vincular',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrecosList() {
    const colorBg = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: colorBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF00B4D8),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Tabela de Preços',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _carregarProcedimentos,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _carregarProcedimentos,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : _procedimentos.isEmpty
          ? const Center(child: Text('Nenhum procedimento encontrado.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _procedimentos.length,
              itemBuilder: (context, index) {
                final procedimento = _procedimentos[index];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            size: 24,
                            color: const Color(0xFF00B4D8),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                procedimento.nome,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2D42),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Código: #${procedimento.id}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'R\$ ${procedimento.valor.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF0077B6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF00B4D8),
                                size: 28,
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/consultas',
                                  arguments: {
                                    'id': procedimento.id,
                                    'nome': procedimento.nome,
                                    'valor': procedimento.valor,
                                  },
                                );
                              },
                              tooltip: 'Solicitar consulta com este exame',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProcedimentoItem {
  const ProcedimentoItem({
    required this.id,
    required this.nome,
    required this.valor,
  });

  final int id;
  final String nome;
  final double valor;
}
