import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  String? _networkImageURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser!.uid;
    final playerData = await _firebaseService.getPlayerDetails(userId);
    if (playerData != null) {
      _fullNameController.text = playerData['name'] ?? '';
      _phoneController.text = playerData['phone'] ?? '';
      _birthDateController.text = playerData['birthDate'] ?? '';
      _cpfController.text = playerData['cpf'] ?? 'Não informado';
      setState(() {
        _networkImageURL = playerData['photoURL'];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final userId = _authService.currentUser!.uid;

      final error = await _authService.updateUserProfile(
        userId: userId,
        imageFile: _selectedImage,
        phone: _phoneController.text,
        birthDate: _birthDateController.text,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    _buildTextFormField(
                      controller: _fullNameController,
                      label: 'Nome Completo',
                      readOnly: true,
                    ),
                    const SizedBox(height: 32),
                    _buildTextFormField(
                      controller: _cpfController,
                      label: 'CPF (ID único)',
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Telefone (WhatsApp)',
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _birthDateController,
                      label: 'Data de Nascimento',
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAmber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Salvar Alterações',
                          style: TextStyle(
                            color: darkBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: cardColor,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_networkImageURL != null
                          ? NetworkImage(_networkImageURL!)
                          : null)
                      as ImageProvider?,
            child: (_selectedImage == null && _networkImageURL == null)
                ? const Icon(Icons.person, size: 60, color: secondaryTextColor)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: primaryAmber,
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: darkBackground,
                  size: 20,
                ),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? secondaryTextColor : textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }
}
