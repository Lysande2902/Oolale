import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _instrumentController = TextEditingController(); 
  final _gearController = TextEditingController(); 
  
  List<String> _gearList = [];
  String? _avatarUrl;
  File? _imageFile;
  bool _isLoading = false;
  bool _isSaving = false;
  static const int MAX_GEAR = 8;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _nameController.text = data['nombre_artistico'] ?? '';
        _bioController.text = data['bio_rider'] ?? '';
        _locationController.text = data['ubicacion_base'] ?? '';
        _instrumentController.text = data['instrumento_principal'] ?? '';
        _avatarUrl = data['avatar_url'];
        _isLoading = false;
      });

      // Cargar Gear (Mi Equipo)
      final gearData = await _supabase
          .from('perfil_gear')
          .select('gear_catalog(nombre)')
          .eq('perfil_id', userId);
      
      final gearNames = (gearData as List).map((g) => g['gear_catalog']['nombre'].toString()).toList();
      setState(() {
        _gearList = gearNames;
        _gearController.text = gearNames.join(', ');
      });
        } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _addGear() {
    final newGear = _gearController.text.trim();
    if (newGear.isEmpty) return;
    
    if (_gearList.length >= MAX_GEAR) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $MAX_GEAR instrumentos permitidos', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (!_gearList.contains(newGear)) {
      setState(() {
        _gearList.add(newGear);
        _gearController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este instrumento ya está agregado', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: AppConstants.warningColor,
        ),
      );
    }
  }

  Future<void> _save() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      String? finalAvatarUrl = _avatarUrl;

      // 1. Subir imagen si se seleccionó una nueva
      if (_imageFile != null) {
        finalAvatarUrl = await StorageService.uploadAvatar(userId, _imageFile!);
      }

      // 2. Actualizar perfil
      await _supabase.from('profiles').update({
        'nombre_artistico': _nameController.text.trim(),
        'bio_rider': _bioController.text.trim(),
        'ubicacion_base': _locationController.text.trim(),
        'instrumento_principal': _instrumentController.text.trim(),
        'avatar_url': finalAvatarUrl,
      }).eq('id', userId);

      // 3. Actualizar Gear (Simplificado: Borrar y Reinsertar)
      if (_gearList.isNotEmpty) {
        // Validar máximo de instrumentos
        if (_gearList.length > MAX_GEAR) {
          throw Exception('Máximo $MAX_GEAR instrumentos permitidos');
        }
        
        // Primero borramos lo actual
        await _supabase.from('perfil_gear').delete().eq('perfil_id', userId);
        
        // Luego insertamos lo nuevo (Buscando o creando en el catálogo)
        for (var name in _gearList) {
          // Buscamos si existe en el catálogo
          var catalogItem = await _supabase.from('gear_catalog').select().ilike('nombre', name).maybeSingle();
          
          String gearId;
          if (catalogItem == null) {
            // Si no existe, lo creamos
            final newItem = await _supabase.from('gear_catalog').insert({'nombre': name}).select().single();
            gearId = newItem['id'].toString();
          } else {
            gearId = catalogItem['id'].toString();
          }
          
          // Insertamos la relación
          await _supabase.from('perfil_gear').insert({
            'perfil_id': userId,
            'gear_id': gearId,
          });
        }
      } else {
        // Si no hay instrumentos, limpiar los existentes
        await _supabase.from('perfil_gear').delete().eq('perfil_id', userId);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Editar Perfil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 30),
                _buildSectionTitle('Información Básica'),
                _buildTextField(_nameController, 'Nombre Artístico', Icons.person_outline),
                const SizedBox(height: 20),
                _buildTextField(_instrumentController, '¿Qué tocas?', Icons.music_note_outlined),
                const SizedBox(height: 20),
                _buildTextField(_locationController, 'Ubicación', Icons.location_on_outlined),
                const SizedBox(height: 30),
                _buildSectionTitle('Bio y Requisitos'),
                _buildTextField(_bioController, 'Sobre ti...', Icons.notes, maxLines: 3),
                const SizedBox(height: 20),
                _buildSectionTitle('Mis Instrumentos (Máx. 8)'),
                _buildGearSection(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppConstants.bgDarkAlt,
              backgroundImage: _imageFile != null 
                  ? FileImage(_imageFile!) 
                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
              child: (_imageFile == null && _avatarUrl == null)
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGearSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input para agregar instrumentos
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _gearController,
                  style: TextStyle(color: ThemeColors.primaryText(context)),
                  decoration: InputDecoration(
                    labelText: 'Nuevo instrumento (${_gearList.length}/$MAX_GEAR)',
                    labelStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 14),
                    prefixIcon: Icon(Icons.high_quality_outlined, color: AppConstants.primaryColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (_) => _addGear(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _gearList.length >= MAX_GEAR ? null : _addGear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.add, color: _gearList.length >= MAX_GEAR ? Colors.grey : Colors.black, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Lista de instrumentos
        if (_gearList.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _gearList.map((gear) {
                  return Chip(
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                    label: Text(gear, style: GoogleFonts.outfit(color: AppConstants.primaryColor, fontSize: 12)),
                    onDeleted: () {
                      setState(() {
                        _gearList.remove(gear);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Sin instrumentos agregados', 
              style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: ThemeColors.primaryText(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 14),
          prefixIcon: Icon(icon, color: AppConstants.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text('Guardar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
