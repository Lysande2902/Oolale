import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateReportScreen extends StatefulWidget {
  final int reportedUserId;
  final String reportedUserName;

  const CreateReportScreen({
    super.key, 
    required this.reportedUserId,
    required this.reportedUserName
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _descController = TextEditingController();
  String _selectedReason = 'spam';
  bool _isLoading = false;

  final Map<String, String> _reasons = {
    'spam': 'Spam o Publicidad no deseada',
    'acoso': 'Acoso o Comportamiento ofensivo',
    'contenido_inapropiado': 'Contenido Inapropiado (+18)',
    'estafa': 'Posible Estafa o Fraude',
    'otro': 'Otro motivo'
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_descController.text.isEmpty && _selectedReason == 'otro') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor describe el problema')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.post('/report', {
        'reportedUserId': widget.reportedUserId,
        'reason': _selectedReason,
        'description': _descController.text
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: AppConstants.cardColor,
            title: const Text('Reporte Enviado', style: TextStyle(color: Colors.white)),
            content: const Text('Gracias por alertarnos. Nuestro equipo revisará este caso en breve.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close screen
                },
                child: const Text('Entendido', style: TextStyle(color: AppConstants.primaryColor)),
              )
            ],
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('REPORTAR USUARIO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'Estás reportando a ',
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(text: widget.reportedUserName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const TextSpan(text: '. Esta acción es anónima y confidencial.')
                        ]
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            Text('SELECCIONA UN MOTIVO', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.circular(15)
              ),
              child: Column(
                children: _reasons.entries.map((entry) {
                  final isSelected = _selectedReason == entry.key;
                  return RadioListTile<String>(
                    activeColor: AppConstants.errorColor,
                    tileColor: Colors.transparent,
                    title: Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
                    value: entry.key,
                    groupValue: _selectedReason,
                    onChanged: (v) => setState(() => _selectedReason = v!),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),
            Text('DETALLES ADICIONALES', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 15),

            TextField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppConstants.cardColor,
                hintText: 'Describe la situación para ayudarnos a entender mejor el contexto...',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white24)),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0
                ),
                onPressed: _isLoading ? null : _submitReport,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text('ENVIAR REPORTE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
