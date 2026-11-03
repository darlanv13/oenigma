import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';

class AdminGatewaysScreen extends StatefulWidget {
  const AdminGatewaysScreen({super.key});

  @override
  State<AdminGatewaysScreen> createState() => _AdminGatewaysScreenState();
}

class _AdminGatewaysScreenState extends State<AdminGatewaysScreen> {
  bool _isLoading = true;
  String _selectedFilter = 'todos'; // 'todos', 'ativos', 'pix', 'cartao'
  List<GatewayItem> _gateways = [];

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  // Lista padrão inicial com os 5 gateways mais populares
  List<GatewayItem> _getInitialGateways() {
    return [
      GatewayItem(
        id: 'mercadopago',
        name: 'Mercado Pago',
        subtitle: 'Líder em pagamentos na América Latina. Pix instantâneo e Cartão.',
        brandColor: const Color(0xFF009EE3),
        icon: FontAwesomeIcons.handshake,
        supportedMethods: ['PIX', 'CARTÃO', 'BOLETO'],
        isActive: true,
        isDefault: true,
        environment: 'production',
        keys: {
          'public_key': '',
          'access_token': '',
          'client_id': '',
          'client_secret': '',
          'webhook_secret': '',
        },
        keyLabels: {
          'public_key': 'Public Key (APP_USR-...)',
          'access_token': 'Access Token (APP_USR-...)',
          'client_id': 'Client ID',
          'client_secret': 'Client Secret',
          'webhook_secret': 'Webhook Signing Secret',
        },
        docUrl: 'https://www.mercadopago.com.br/developers',
      ),
      GatewayItem(
        id: 'stripe',
        name: 'Stripe',
        subtitle: 'Padrão mundial para pagamentos em Pix instantâneo, Cartão, Apple Pay e Google Pay.',
        brandColor: const Color(0xFF635BFF),
        icon: FontAwesomeIcons.stripeS,
        supportedMethods: ['PIX', 'CARTÃO', 'APPLE PAY', 'GOOGLE PAY'],
        isActive: false,
        isDefault: false,
        environment: 'sandbox',
        keys: {
          'publishable_key': '',
          'secret_key': '',
          'webhook_secret': '',
          'currency': 'brl',
        },
        keyLabels: {
          'publishable_key': 'Publishable Key (pk_live_... ou pk_test_...)',
          'secret_key': 'Secret Key (sk_live_... ou sk_test_...)',
          'webhook_secret': 'Webhook Signing Secret (whsec_...)',
          'currency': 'Moeda Padrão (ex: brl)',
        },
        docUrl: 'https://dashboard.stripe.com/apikeys',
      ),
      GatewayItem(
        id: 'asaas',
        name: 'Asaas',
        subtitle: 'Especialista em Pix dinâmico, boletos, split e automações financeiras.',
        brandColor: const Color(0xFF0030B8),
        icon: FontAwesomeIcons.buildingColumns,
        supportedMethods: ['PIX', 'BOLETO', 'CARTÃO', 'SPLIT'],
        isActive: false,
        isDefault: false,
        environment: 'sandbox',
        keys: {
          'api_key': '',
          'wallet_id': '',
          'webhook_token': '',
          'split_account_id': '',
        },
        keyLabels: {
          'api_key': 'API Key (\$aact_...)',
          'wallet_id': 'Wallet ID (ID da Carteira)',
          'webhook_token': 'Token de Autenticação do Webhook',
          'split_account_id': 'ID da Subconta para Split (Opcional)',
        },
        docUrl: 'https://docs.asaas.com',
      ),
      GatewayItem(
        id: 'efibank',
        name: 'Efi Bank (Gerencianet)',
        subtitle: 'Líder em Open Finance e Pix Direto com certificado mTLS do Bacen.',
        brandColor: const Color(0xFFF37021),
        icon: FontAwesomeIcons.qrcode,
        supportedMethods: ['PIX MTLS', 'BOLETO QR', 'OPEN FINANCE'],
        isActive: false,
        isDefault: false,
        environment: 'sandbox',
        keys: {
          'client_id': '',
          'client_secret': '',
          'pix_key': '',
          'certificate_name': '',
        },
        keyLabels: {
          'client_id': 'Client ID da Aplicação',
          'client_secret': 'Client Secret',
          'pix_key': 'Chave Pix (EVP / Aleatória)',
          'certificate_name': 'Nome do Certificado .p12 (ou Base64)',
        },
        docUrl: 'https://dev.efipay.com.br',
      ),
      GatewayItem(
        id: 'pagarme',
        name: 'Pagar.me (Stone)',
        subtitle: 'Infraestrutura da Stone para checkout transparente e antifraude nativo.',
        brandColor: const Color(0xFF00A868),
        icon: FontAwesomeIcons.shieldHalved,
        supportedMethods: ['CARTÃO', 'PIX', 'ANTIFRAUDE', 'SPLIT'],
        isActive: false,
        isDefault: false,
        environment: 'sandbox',
        keys: {
          'api_key': '',
          'encryption_key': '',
          'secret_key': '',
        },
        keyLabels: {
          'api_key': 'API Key (ak_...)',
          'encryption_key': 'Encryption Key (ek_...)',
          'secret_key': 'Secret Key (sk_...)',
        },
        docUrl: 'https://docs.pagar.me',
      ),
    ];
  }

  Future<void> _loadGateways() async {
    setState(() => _isLoading = true);
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('GatewayConfig'));
      final response = await query.query();

      final defaults = _getInitialGateways();

      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final serverList = response.results as List<ParseObject>;
        for (var d in defaults) {
          final found = serverList.where((obj) => obj.get<String>('gatewayId') == d.id).firstOrNull;
          if (found != null) {
            d.parseObjectId = found.objectId;
            d.isActive = found.get<bool>('isActive') ?? d.isActive;
            d.isDefault = found.get<bool>('isDefault') ?? d.isDefault;
            d.environment = found.get<String>('environment') ?? d.environment;
            final serverKeys = found.get<Map<String, dynamic>>('keys');
            if (serverKeys != null) {
              for (var k in d.keys.keys) {
                if (serverKeys.containsKey(k)) {
                  d.keys[k] = serverKeys[k]?.toString() ?? '';
                }
              }
            }
          }
        }
      }

      // Garante que há ao menos 1 padrão ativo
      if (!defaults.any((g) => g.isDefault)) {
        defaults.first.isDefault = true;
        defaults.first.isActive = true;
      }

      setState(() {
        _gateways = defaults;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _gateways = _getInitialGateways();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGateway(GatewayItem item) async {
    try {
      final obj = ParseObject('GatewayConfig');
      if (item.parseObjectId != null) {
        obj.objectId = item.parseObjectId;
      }
      obj.set<String>('gatewayId', item.id);
      obj.set<String>('name', item.name);
      obj.set<bool>('isActive', item.isActive);
      obj.set<bool>('isDefault', item.isDefault);
      obj.set<String>('environment', item.environment);
      obj.set<Map<String, dynamic>>('keys', item.keys);

      final res = await obj.save();
      if (res.success && res.result != null) {
        item.parseObjectId = (res.result as ParseObject).objectId;
      }
    } catch (e) {
      debugPrint('Erro ao persistir gateway: $e');
    }
  }

  Future<void> _setAsDefault(GatewayItem selected) async {
    setState(() {
      for (var g in _gateways) {
        if (g.id == selected.id) {
          g.isDefault = true;
          g.isActive = true; // Se é o padrão, precisa estar ativo
        } else {
          g.isDefault = false;
        }
      }
    });

    for (var g in _gateways) {
      await _saveGateway(g);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.name} agora é o Gateway Principal do sistema!'),
          backgroundColor: AppColors.verdeVale,
        ),
      );
    }
  }

  Future<void> _toggleActive(GatewayItem item, bool active) async {
    if (!active && item.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode desativar o Gateway Principal. Defina outro como principal antes.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      item.isActive = active;
    });
    await _saveGateway(item);
  }

  void _showConfigureModal(GatewayItem item) {
    final controllers = <String, TextEditingController>{};
    final obscureFields = <String, bool>{};

    for (var entry in item.keys.entries) {
      controllers[entry.key] = TextEditingController(text: entry.value);
      obscureFields[entry.key] = true;
    }

    String currentEnv = item.environment;
    bool currentActive = item.isActive;
    bool currentDefault = item.isDefault;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final webhookUrl = 'https://parseapi.back4app.com/parse/functions/paymentWebhook?gateway=${item.id}';

            return AdminModal(
              title: 'Configurar ${item.name}',
              maxWidth: 680,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Gateway no Modal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: item.brandColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.brandColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(item.icon, color: item.brandColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.inter(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ambiente (Produção vs Sandbox) & Status
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMBIENTE DE OPERAÇÃO *',
                              style: GoogleFonts.inter(
                                color: AppColors.cinzaMedio,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.darkCardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentEnv,
                                  isExpanded: true,
                                  dropdownColor: AppColors.darkCardColor,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'production',
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                                          SizedBox(width: 8),
                                          Text('Produção (Live Real)'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'sandbox',
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, size: 10, color: Colors.amberAccent),
                                          SizedBox(width: 8),
                                          Text('Ambiente de Testes (Sandbox)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => currentEnv = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS DO GATEWAY',
                              style: GoogleFonts.inter(
                                color: AppColors.cinzaMedio,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.darkCardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currentActive ? 'Ativado' : 'Desativado',
                                    style: GoogleFonts.inter(
                                      color: currentActive ? AppColors.verdeVale : AppColors.cinzaMedio,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Switch(
                                    value: currentActive,
                                    activeThumbColor: AppColors.verdeVale,
                                    onChanged: (val) {
                                      setModalState(() => currentActive = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Definir como Gateway Principal (Default)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: currentDefault ? AppColors.verdeVale.withValues(alpha: 0.1) : AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: currentDefault ? AppColors.verdeVale : Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.star,
                              size: 14,
                              color: currentDefault ? AppColors.amareloVale : AppColors.cinzaMedio,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Definir como Gateway Principal (Default)',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Provedor padrão utilizado pelo App para gerar depósitos Pix',
                                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: currentDefault,
                          activeThumbColor: AppColors.verdeVale,
                          onChanged: (val) {
                            setModalState(() {
                              currentDefault = val;
                              if (val) currentActive = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos de Credenciais
                  Text(
                    'CHAVES E CREDENCIAIS DE API',
                    style: GoogleFonts.inter(
                      color: AppColors.amareloVale,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'As credenciais são salvas com criptografia e usadas para gerar cobranças Pix e Cartão.',
                    style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  ...item.keys.keys.map((key) {
                    final label = item.keyLabels[key] ?? key;
                    final isObscure = obscureFields[key] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.cinzaMedio,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: controllers[key],
                            obscureText: isObscure,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            onChanged: (val) {
                              if (item.id == 'asaas' && key == 'api_key') {
                                if (val.trim().startsWith(r'$aact_prod_') && currentEnv != 'production') {
                                  setModalState(() => currentEnv = 'production');
                                } else if ((val.trim().startsWith(r'$aact_test_') || val.trim().startsWith(r'$aact_uat_')) && currentEnv != 'sandbox') {
                                  setModalState(() => currentEnv = 'sandbox');
                                }
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Digite o valor para $label',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppColors.darkCardColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.verdeVale),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.cinzaMedio,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    obscureFields[key] = !isObscure;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (item.id == 'asaas' && key == 'api_key' && controllers[key]!.text.trim().startsWith(r'$aact_prod_'))
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 13, color: Colors.greenAccent),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chave de Produção Asaas detectada (https://api.asaas.com)',
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Seção de Webhook / Notificações
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.bolt, size: 12, color: AppColors.amareloVale),
                            const SizedBox(width: 8),
                            Text(
                              'URL de Webhook (Notificação Instantânea)',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cadastre esta URL no painel do desenvolvedor do ${item.name} para confirmação imediata de pagamentos Pix.',
                          style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  webhookUrl,
                                  style: GoogleFonts.robotoMono(
                                    color: AppColors.verdeVale,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.copy, size: 14, color: AppColors.amareloVale),
                                tooltip: 'Copiar Webhook URL',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: webhookUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('URL do Webhook copiada para a área de transferência!'),
                                      backgroundColor: AppColors.verdeVale,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões de Ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.plug, size: 14),
                        label: const Text('Testar Conexão'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.amareloVale,
                        ),
                        onPressed: () {
                          _testGatewayConnection(item, controllers, currentEnv);
                        },
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
                            label: const Text('Salvar Credenciais'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.verdeVale,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () async {
                              for (var entry in controllers.entries) {
                                item.keys[entry.key] = entry.value.text.trim();
                              }
                              item.environment = currentEnv;
                              item.isActive = currentActive;

                              if (currentDefault) {
                                for (var g in _gateways) {
                                  if (g.id == item.id) {
                                    g.isDefault = true;
                                    g.isActive = true;
                                  } else {
                                    g.isDefault = false;
                                  }
                                  await _saveGateway(g);
                                }
                              } else {
                                await _saveGateway(item);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Configurações de ${item.name} salvas com sucesso!'),
                                    backgroundColor: AppColors.verdeVale,
                                  ),
                                );
                              }
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _testGatewayConnection(
    GatewayItem item,
    Map<String, TextEditingController> controllers,
    String environment,
  ) async {
    final keys = {
      for (var entry in controllers.entries) entry.key: entry.value.text.trim(),
    };

    if (item.id == 'asaas' && (keys['api_key'] ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a API Key do Asaas antes de testar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Testando conexão com a API do ${item.name}...'),
          ],
        ),
        backgroundColor: AppColors.darkCardColor,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final res = await ParseCloudFunction('testGatewayConnection').execute(
        parameters: {
          'gatewayId': item.id,
          'keys': keys,
          'environment': environment,
        },
      );

      if (res.success && res.result != null) {
        final data = Map<String, dynamic>.from(res.result as Map);
        final bool ok = data['success'] == true;
        final String msg = data['message'] ?? (ok ? 'Conexão validada com sucesso!' : 'Falha na conexão');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: ok ? AppColors.verdeVale : Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao testar: ${res.error?.message ?? "Falha na comunicação"}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao testar conexão: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verdeVale),
      );
    }

    final defaultGateway = _gateways.where((g) => g.isDefault).firstOrNull ?? _gateways.first;

    final filteredGateways = _gateways.where((g) {
      if (_selectedFilter == 'ativos') return g.isActive;
      if (_selectedFilter == 'pix') return g.supportedMethods.any((m) => m.contains('PIX'));
      if (_selectedFilter == 'cartao') return g.supportedMethods.any((m) => m.contains('CARTÃO'));
      return true;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BANNER DO GATEWAY ATIVO PRINCIPAL
          _buildActiveGatewayBanner(defaultGateway),
          const SizedBox(height: 24),

          // 2. FILTROS E CONTAGEM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROVEDORES DISPONÍVEIS (${_gateways.length})',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Todos', 'todos'),
                  _buildFilterChip('Ativos', 'ativos'),
                  _buildFilterChip('Pix Instantâneo', 'pix'),
                  _buildFilterChip('Cartão de Crédito', 'cartao'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. GRID DE CARDS DOS GATEWAYS
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGateways.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 260,
                ),
                itemBuilder: (context, index) {
                  return _buildGatewayCard(filteredGateways[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGatewayBanner(GatewayItem defaultGateway) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: defaultGateway.brandColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: defaultGateway.brandColor.withValues(alpha: 0.5)),
            ),
            child: FaIcon(defaultGateway.icon, color: defaultGateway.brandColor, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.amareloVale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.star, color: AppColors.amareloVale, size: 10),
                          const SizedBox(width: 5),
                          Text(
                            'GATEWAY PRINCIPAL EM OPERAÇÃO',
                            style: GoogleFonts.inter(
                              color: AppColors.amareloVale,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: defaultGateway.environment == 'production'
                            ? Colors.greenAccent.withValues(alpha: 0.12)
                            : Colors.amberAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: defaultGateway.environment == 'production'
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                        ),
                      ),
                      child: Text(
                        defaultGateway.environment == 'production' ? 'PRODUÇÃO (LIVE)' : 'SANDBOX (TESTES)',
                        style: GoogleFonts.inter(
                          color: defaultGateway.environment == 'production'
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  defaultGateway.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Todas as cobranças Pix geradas pelo App Cliente estão sendo direcionadas para este provedor.',
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.gear, size: 14),
            label: const Text('Configurar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeVale,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: () => _showConfigureModal(defaultGateway),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeVale.withValues(alpha: 0.2) : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.verdeVale : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.cinzaMedio,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayCard(GatewayItem item) {
    final bool hasConfiguredKeys = item.keys.values.any((val) => val.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isDefault
              ? AppColors.amareloVale.withValues(alpha: 0.6)
              : (item.isActive ? AppColors.verdeVale.withValues(alpha: 0.3) : Colors.white10),
          width: item.isDefault ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo do Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.brandColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.brandColor.withValues(alpha: 0.4)),
                ),
                child: FaIcon(item.icon, color: item.brandColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amareloVale.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.amareloVale),
                            ),
                            child: Text(
                              'PRINCIPAL',
                              style: GoogleFonts.inter(
                                color: AppColors.amareloVale,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.cinzaMedio,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: item.isActive,
                activeThumbColor: AppColors.verdeVale,
                onChanged: (val) => _toggleActive(item, val),
              ),
            ],
          ),

          // Métodos Suportados
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: item.supportedMethods.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  m,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),

          // Status de Configuração
          Row(
            children: [
              Icon(
                hasConfiguredKeys ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 14,
                color: hasConfiguredKeys ? AppColors.verdeVale : Colors.amberAccent,
              ),
              const SizedBox(width: 6),
              Text(
                hasConfiguredKeys ? 'Credenciais Configuradas' : 'Configuração Pendente',
                style: GoogleFonts.inter(
                  color: hasConfiguredKeys ? AppColors.verdeVale : Colors.amberAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.environment == 'production'
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.environment.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: item.environment == 'production' ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.sliders, size: 12),
                  label: const Text('Configurar API'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showConfigureModal(item),
                ),
              ),
              if (!item.isDefault) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.check, size: 12),
                    label: const Text('Tornar Principal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloVale,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _setAsDefault(item),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class GatewayItem {
  final String id;
  final String name;
  final String subtitle;
  final Color brandColor;
  final dynamic icon;
  final List<String> supportedMethods;
  final Map<String, String> keyLabels;
  final String docUrl;

  String? parseObjectId;
  bool isActive;
  bool isDefault;
  String environment; // 'production' ou 'sandbox'
  Map<String, String> keys;

  GatewayItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.brandColor,
    required this.icon,
    required this.supportedMethods,
    required this.keyLabels,
    required this.docUrl,
    this.parseObjectId,
    this.isActive = false,
    this.isDefault = false,
    this.environment = 'sandbox',
    required this.keys,
  });
}
