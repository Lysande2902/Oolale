import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';

class LeaveRatingScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const LeaveRatingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<LeaveRatingScreen> createState() => _LeaveRatingScreenState();
}

class _LeaveRatingScreenState extends State<LeaveRatingScreen> {
  final _supabase = Supabase.instance.client;
  final _commentController = TextEditingController();
  
  int _rating = 0;
  bool _isSubmitting = false;
  bool _hasWorkedTogether = false;
  bool _checkingConnection = true;

  @override
  void initState() {
    super.initState();
    _checkIfWorkedTogether();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfWorkedTogether() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) {
      if (mounted) setState(() => _checkingConnection = false);
      return;
    }

    try {
      // Verificar si trabajaron juntos en algún evento
      final gigsData = await _supabase
          .from('gig_lineup')
          .select('gig_id')
          .eq('perfil_id', myId);

      if (gigsData.isEmpty) {
        if (mounted) {
          setState(() {
            _hasWorkedTogether = false;
            _checkingConnection = false;
          });
        }
        return;
      }

      final gigIds = gigsData.map((g) => g['gig_id']).toList();

      // Verificar si el otro usuario estuvo en alguno de esos eventos
      final sharedGigs = await _supabase
          .from('gig_lineup')
          .select('gig_id')
          .eq('perfil_id', widget.userId)
          .inFilter('gig_id', gigIds);

      if (mounted) {
        setState(() {
          _hasWorkedTogether = sharedGigs.isNotEmpty;
          _checkingConnection = false;
        });
      }
    } catch (e) {
      debugPrint('Error verificando eventos compartidos: $e');
      if (mounted) {
        setState(() {
          _hasWorkedTogether = false;
          _checkingConnection = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una calificación', style: GoogleFonts.outfit()),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Insertar calificación
      await _supabase.from('referencias').insert({
        'evaluador_id': myId,
        'evaluado_id': widget.userId,
        'puntuacion': _rating,
        'comentario': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        'tipo_interaccion': 'evento', // o 'colaboracion'
        'verificado': _hasWorkedTogether,
      });

      // Actualizar rating promedio del usuario evaluado
      await _updateUserRating();

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Calificación enviada', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error enviando calificación: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar calificación', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _updateUserRating() async {
    try {
      // Calcular nuevo promedio
      final ratingsData = await _supabase
          .from('referencias')
          .select('puntuacion')
          .eq('evaluado_id', widget.userId);

      if (ratingsData.isEmpty) return;

      final ratings = ratingsData.map((r) => r['puntuacion'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;

      // Actualizar perfil
      await _supabase
          .from('profiles')
          .update({
            'rating_promedio': average,
            'total_calificaciones': ratings.length,
            'total_referencias': ratings.length,
          })
          .eq('id', widget.userId);
    } catch (e) {
      debugPrint('Error actualizando rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingConnection) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Calificar Usuario', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: ThemeColors.icon(context)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Calificar Usuario', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: ThemeColors.icon(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usuario a calificar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeColors.divider(context)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    child: Text(
                      widget.userName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppConstants.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_hasWorkedTogether)
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Trabajaron juntos',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Calificación
            Text(
              '¿Cómo fue tu experiencia?',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 48,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            
            // Comentario
            Text(
              'Comentario (opcional)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              style: GoogleFonts.outfit(color: ThemeColors.primaryText(context)),
              decoration: InputDecoration(
                hintText: 'Cuéntanos sobre tu experiencia trabajando con ${widget.userName}...',
                hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeColors.divider(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeColors.divider(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        'Enviar Calificación',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muy mala';
      case 2:
        return 'Mala';
      case 3:
        return 'Regular';
      case 4:
        return 'Buena';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
