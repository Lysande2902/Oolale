import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../config/constants.dart';
import '../../services/storage_service.dart';

class UploadMediaScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onUploadComplete;

  const UploadMediaScreen({super.key, 
    required this.userId,
    required this.onUploadComplete,
  });

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  
  File? _selectedFile;
  String _selectedType = 'imagen'; 
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      if (type == 'imagen') {
        final picked = await _picker.pickImage(source: ImageSource.gallery);
        if (picked != null) setState(() => _selectedFile = File(picked.path));
      } else if (type == 'video') {
        final picked = await _picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) setState(() => _selectedFile = File(picked.path));
      } else if (type == 'audio') {
        final result = await FilePicker.platform.pickFiles(type: FileType.audio);
        if (result != null && result.files.single.path != null) {
          setState(() => _selectedFile = File(result.files.single.path!));
        }
      }
      setState(() => _selectedType = type);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final publicUrl = await StorageService.uploadPortfolio(widget.userId, _selectedFile!);
      
      if (publicUrl == null) throw Exception('No se pudo obtener la URL del archivo');

      await _supabase.from('portfolio_media').insert({
        'profile_id': widget.userId,
        'tipo': _selectedType,
        'titulo': _titleController.text.trim(),
        'url': publicUrl,
        'visibilidad': 'publico',
      });

      if (mounted) {
        widget.onUploadComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir archivo')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Subir Archivo', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tipo'),
            _buildTypeSelector(),
            const SizedBox(height: 30),
            _buildSectionTitle('Archivo'),
            _buildFileArea(),
            const SizedBox(height: 30),
            _buildSectionTitle('Título'),
            _buildTextField(),
            const SizedBox(height: 50),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: ['imagen', 'video', 'audio'].map((type) {
        final isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryColor : AppConstants.bgDarkPanel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    type == 'imagen' ? Icons.image : type == 'video' ? Icons.videocam : Icons.music_note,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                  const SizedBox(height: 4),
                  Text(type.toUpperCase(), style: GoogleFonts.outfit(color: isSelected ? Colors.black : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileArea() {
    return GestureDetector(
      onTap: () => _pickFile(_selectedType),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppConstants.bgDarkPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            if (_selectedFile == null) ...[
              Icon(Icons.cloud_upload_outlined, color: AppConstants.primaryColor, size: 40),
              const SizedBox(height: 12),
              Text('Toca para seleccionar', style: GoogleFonts.outfit(color: Colors.grey[600])),
            ] else ...[
              const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 40),
              const SizedBox(height: 12),
              Text(_selectedFile!.path.split('/').last, style: GoogleFonts.outfit(color: Colors.white), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.bgDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Nombre del archivo',
          hintStyle: GoogleFonts.outfit(color: Colors.grey[800]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _upload,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text('Subir', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
