import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';
import 'package:oenigma/features/profile/providers/profile_repository_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> playerData;

  const EditProfileScreen({
    super.key,
    required this.playerData,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  String _selectedAvatar = 'iniciais'; // Default value based on the image

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.playerData['name'] ?? '';
    _emailController.text = widget.playerData['email'] ?? '';
    _phoneController.text = widget.playerData['phone'] ?? '';
    _cityController.text = widget.playerData['city'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authRepository = ref.read(authRepositoryProvider);
        final currentUser = authRepository.currentUser;

        if (currentUser == null || currentUser.objectId == null) {
            throw Exception('Usuário não autenticado.');
        }

        final dataToUpdate = {
          'name': _nameController.text.trim(),
          // 'email': _emailController.text.trim(), // Normally, changing email might require special handling in Parse
          'phone': _phoneController.text.trim(),
          'city': _cityController.text.trim(),
        };

        await ref
            .read(profileRepositoryProvider)
            .updateUserProfile(currentUser.objectId!, dataToUpdate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Very dark background
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.angleLeft,
              color: Color(0xFFD6B570), // Gold
              size: 16,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('NOME COMPLETO'),
              _buildTextField(_nameController),
              const SizedBox(height: 24),

              _buildLabel('E-MAIL'),
              _buildTextField(_emailController, enabled: false), // Generally email shouldn't be freely editable here
              const SizedBox(height: 24),

              _buildLabel('TELEFONE'),
              _buildTextField(_phoneController),
              const SizedBox(height: 24),

              _buildLabel('CIDADE'),
              _buildTextField(_cityController),
              const SizedBox(height: 24),

              _buildLabel('AVATAR'),
              _buildDropdown(),
              const SizedBox(height: 48),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB39D82), // Muted gold/tan color for labels
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          isDense: true,
        ),
        validator: (value) {
          if (enabled && (value == null || value.trim().isEmpty)) {
            return 'Campo obrigatório';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    // In the future, this can be expanded. For now, it matches the image
    final List<String> options = ['iniciais', 'foto'];

    // Determine the initials based on the name
    String nameStr = _nameController.text;
    String initials = "FG";
    if (nameStr.isNotEmpty) {
      var parts = nameStr.split(' ');
      if (parts.length > 1) {
        initials = parts[0][0] + parts[parts.length - 1][0];
      } else {
        initials = parts[0][0];
      }
      initials = initials.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedAvatar,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          icon: const FaIcon(FontAwesomeIcons.angleDown, color: Colors.white, size: 14),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedAvatar = newValue;
              });
            }
          },
          items: options.map<DropdownMenuItem<String>>((String value) {
            String display = value;
            if (value == 'iniciais') {
               display = '$initials (iniciais)';
            } else if (value == 'foto') {
               display = 'Foto de Perfil';
            }
            return DropdownMenuItem<String>(
              value: value,
              child: Text(display),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFDEC388), Color(0xFFB1904C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC7A55C).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveProfile,
        icon: _isLoading
            ? const SizedBox(width: 14, height: 14)
            : const FaIcon(
                FontAwesomeIcons.check,
                color: Colors.black,
                size: 14,
              ),
        label: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SALVAR ALTERAÇÕES',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
