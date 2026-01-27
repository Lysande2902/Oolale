import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);
  String _selectedType = 'jam_session';
  bool _isLoading = false;
  
  final List<String> _types = ['jam_session', 'ensayo', 'concierto', 'festival', 'taller'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isLoading = true);
    try {
      final timeStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00";
      
      await _supabase.from('gigs').insert({
        'organizador_id': myId,
        'titulo_bolo': _titleController.text.trim(),
        'resumen_setlist': _descController.text.trim(),
        'tipo': _selectedType,
        'fecha_gig': _selectedDate.toIso8601String().split('T')[0],
        'hora_soundcheck': timeStr,
        'lugar_nombre': _locationController.text.trim(),
        'estatus_bolo': 'programado',
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear evento')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Evento', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información'),
              _buildTextField(_titleController, 'Título', Icons.campaign_outlined),
              const SizedBox(height: 20),
              _buildTextField(_locationController, 'Lugar', Icons.location_on_outlined),
              const SizedBox(height: 30),
              _buildSectionTitle('Fecha y Hora'),
              Row(
                children: [
                  Expanded(child: _buildPickerCard("Día", DateFormat('dd/MM/yyyy').format(_selectedDate), Icons.today, _pickDate)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPickerCard("Hora", _selectedTime.format(context), Icons.access_time, _pickTime)),
                ],
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Tipo'),
              _buildTypeSelector(),
              const SizedBox(height: 30),
              _buildSectionTitle('Detalles'),
              _buildTextField(_descController, 'Breve descripción...', Icons.notes, maxLines: 4),
              const SizedBox(height: 50),
              _buildSaveButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey[800]),
          prefixIcon: Icon(icon, color: AppConstants.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (v) => v!.isEmpty ? 'Requerido' : null,
      ),
    );
  }

  Widget _buildPickerCard(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.bgDarkPanel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 10)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 16),
                const SizedBox(width: 8),
                Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.bgDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: AppConstants.bgDarkPanel,
          icon: const Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor),
          items: _types.map((m) => DropdownMenuItem(
            value: m,
            child: Text(m.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text('Guardar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
