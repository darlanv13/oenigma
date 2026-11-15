import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/admin_modal.dart';

class MasterTenancyScreen extends StatefulWidget {
  const MasterTenancyScreen({super.key});

  @override
  State<MasterTenancyScreen> createState() => _MasterTenancyScreenState();
}

class _MasterTenancyScreenState extends State<MasterTenancyScreen> {
  List<ParseObject> _tenants = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Tenant'))
        ..orderByDescending('createdAt');
      final response = await query.query();
      if (mounted) {
        if (response.success && response.results != null) {
          _tenants = List<ParseObject>.from(response.results!);
        } else {
          _tenants = [];
        }
      }
    } catch (_) {
      _tenants = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showTenantDialog({ParseObject? tenantToEdit}) {
    final isEditing = tenantToEdit != null;
    final nameController = TextEditingController(
      text: tenantToEdit?.get<String>('name') ?? '',
    );
    final slugController = TextEditingController(
      text: tenantToEdit?.get<String>('slug') ?? '',
    );
    final documentController = TextEditingController(
      text: tenantToEdit?.get<String>('document') ?? '',
    );
    final managerController = TextEditingController(
      text: tenantToEdit?.get<String>('managerName') ?? '',
    );
    final emailController = TextEditingController(
      text: tenantToEdit?.get<String>('email') ?? '',
    );
    final phoneController = TextEditingController(
      text: tenantToEdit?.get<String>('phone') ?? '',
    );
    final commissionController = TextEditingController(
      text: (tenantToEdit?.get<num>('commissionPercent') ?? 15.0).toString(),
    );
    final cityController = TextEditingController(
      text: tenantToEdit?.get<String>('city') ?? '',
    );
    String status = tenantToEdit?.get<String>('status') ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AdminModal(
          title: isEditing ? 'Editar Tenant / Franquia' : 'Cadastrar Novo Tenant',
          icon: FontAwesomeIcons.buildingUser,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Tenant (Ex: Franquia São Paulo)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug / Identificador (sp-capital)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: managerController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Responsável',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: documentController,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ ou CPF',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail de Contato',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp / Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade / Região de Atuação',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: commissionController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Taxa da Plataforma (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status do Tenant',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: AppColors.darkCardColor,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Ativo e Operacional')),
                    DropdownMenuItem(value: 'pending', child: Text('Em Análise / Configuração')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspenso / Bloqueado')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => status = val);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeVale,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final slug = slugController.text.trim().toLowerCase().replaceAll(' ', '-');
                        final commission = double.tryParse(commissionController.text.replaceAll(',', '.')) ?? 15.0;

                        Navigator.pop(ctx);

                        final tenantObj = tenantToEdit ?? ParseObject('Tenant');
                        tenantObj.set('name', name);
                        tenantObj.set('slug', slug.isNotEmpty ? slug : name.toLowerCase().replaceAll(' ', '-'));
                        tenantObj.set('managerName', managerController.text.trim());
                        tenantObj.set('document', documentController.text.trim());
                        tenantObj.set('email', emailController.text.trim());
                        tenantObj.set('phone', phoneController.text.trim());
                        tenantObj.set('city', cityController.text.trim());
                        tenantObj.set('commissionPercent', commission);
                        tenantObj.set('status', status);

                        await tenantObj.save();
                        await _loadTenants();
                      },
                      child: Text(isEditing ? 'Salvar Alterações' : 'Criar Tenant'),
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

  Future<void> _toggleTenantStatus(ParseObject tenant) async {
    final currentStatus = tenant.get<String>('status') ?? 'active';
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    tenant.set('status', newStatus);
    await tenant.save();
    await _loadTenants();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'active' ? 'Tenant ativado com sucesso!' : 'Tenant suspenso com sucesso!',
          ),
          backgroundColor: newStatus == 'active' ? AppColors.verdeVale : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildMetricsOverview(),
        const SizedBox(height: 20),
        _buildSearchAndFilters(),
        const SizedBox(height: 14),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tenants.isEmpty
                  ? _buildEmptyState()
                  : _buildTenantsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestão de Tenancy (Multi-Tenant)',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gerencie franquias parceiras, cidades de operação e split de receitas.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.cinzaMedio,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showTenantDialog(),
          icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
          label: const Text('Novo Tenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verdeVale,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview() {
    final total = _tenants.length;
    final active = _tenants.where((t) => (t.get<String>('status') ?? 'active') == 'active').length;
    final suspended = _tenants.where((t) => t.get<String>('status') == 'suspended').length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Total de Tenants',
            value: '$total',
            icon: FontAwesomeIcons.building,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Tenants Ativos',
            value: '$active',
            icon: FontAwesomeIcons.circleCheck,
            color: AppColors.verdeVale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            title: 'Suspensos / Em Análise',
            value: '$suspended',
            icon: FontAwesomeIcons.triangleExclamation,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          icon is IconData
              ? Icon(icon, color: color, size: 20)
              : FaIcon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar tenant por nome, cidade ou responsável...',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
          icon: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 14, color: Colors.white38),
          border: InputBorder.none,
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.trim().toLowerCase());
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.buildingUser, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Nenhum Tenant cadastrado na plataforma',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique em "+ Novo Tenant" para cadastrar a primeira franquia parceira.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsList() {
    final filtered = _tenants.where((t) {
      if (_searchQuery.isEmpty) return true;
      final name = (t.get<String>('name') ?? '').toLowerCase();
      final city = (t.get<String>('city') ?? '').toLowerCase();
      final manager = (t.get<String>('managerName') ?? '').toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery) || manager.contains(_searchQuery);
    }).toList();

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tenant = filtered[index];
        final name = tenant.get<String>('name') ?? 'Tenant sem nome';
        final slug = tenant.get<String>('slug') ?? 'slug';
        final city = tenant.get<String>('city') ?? 'Região Geral';
        final manager = tenant.get<String>('managerName') ?? 'Não informado';
        final commission = (tenant.get<num>('commissionPercent') ?? 15.0).toDouble();
        final status = tenant.get<String>('status') ?? 'active';
        final isActive = status == 'active';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.danger.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.verdeVale.withValues(alpha: 0.15)
                      : AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? AppColors.verdeVale : AppColors.danger,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.building,
                    color: isActive ? AppColors.amareloVale : AppColors.danger,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            slug,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.verdeVale.withValues(alpha: 0.2)
                                : AppColors.danger.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'ATIVO' : 'SUSPENSO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.verdeVale : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Responsável: $manager | Região: $city | Taxa Plataforma: ${commission.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 15, color: Colors.white70),
                tooltip: 'Editar Tenant',
                onPressed: () => _showTenantDialog(tenantToEdit: tenant),
              ),
              IconButton(
                icon: FaIcon(
                  isActive ? FontAwesomeIcons.ban : FontAwesomeIcons.check,
                  size: 15,
                  color: isActive ? AppColors.danger : AppColors.verdeVale,
                ),
                tooltip: isActive ? 'Suspender Tenant' : 'Ativar Tenant',
                onPressed: () => _toggleTenantStatus(tenant),
              ),
            ],
          ),
        );
      },
    );
  }
}
