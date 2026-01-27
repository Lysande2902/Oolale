import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/constants.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundGradient(context),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        _buildFeatures(context),
                        _buildPricingCards(context),
                        _buildFAQ(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.accentColor.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.accentColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppConstants.accentColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'PREMIUM',
                  style: GoogleFonts.outfit(
                    color: AppConstants.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppConstants.accentColor, AppConstants.accentColor.withOpacity(0.5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.accentColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.black, size: 60),
            ),
          ),
          const SizedBox(height: 30),
          FadeInUp(
            child: Text(
              'Lleva tu música\nal siguiente nivel',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Desbloquea herramientas profesionales\ny conecta con más oportunidades',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      {'icon': Icons.verified_rounded, 'title': 'Badge Verificado', 'desc': 'Destaca con el check azul'},
      {'icon': Icons.visibility_rounded, 'title': 'Mayor Visibilidad', 'desc': 'Aparece primero en búsquedas'},
      {'icon': Icons.analytics_rounded, 'title': 'Analytics Avanzado', 'desc': 'Estadísticas de tu perfil'},
      {'icon': Icons.cloud_upload_rounded, 'title': 'Almacenamiento Ilimitado', 'desc': 'Sube todo tu portafolio'},
      {'icon': Icons.support_agent_rounded, 'title': 'Soporte Prioritario', 'desc': 'Atención VIP 24/7'},
      {'icon': Icons.campaign_rounded, 'title': 'Promoción de Eventos', 'desc': 'Destaca tus gigs'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BENEFICIOS PREMIUM',
            style: GoogleFonts.outfit(
              color: AppConstants.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map((f) => FadeInLeft(
            child: _buildFeatureTile(
              context,
              f['icon'] as IconData,
              f['title'] as String,
              f['desc'] as String,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConstants.accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppConstants.accentColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildPricingCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Text(
            'ELIGE TU PLAN',
            style: GoogleFonts.outfit(
              color: AppConstants.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          _buildPricingCard(
            'Mensual',
            '\$99',
            'MXN/mes',
            false,
            context,
          ),
          const SizedBox(height: 16),
          _buildPricingCard(
            'Anual',
            '\$990',
            'MXN/año',
            true,
            context,
            savings: 'Ahorra \$198',
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(String title, String price, String period, bool isPopular, BuildContext context, {String? savings}) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPopular
            ? LinearGradient(
                colors: [AppConstants.accentColor.withOpacity(0.2), AppConstants.primaryColor.withOpacity(0.2)],
              )
            : null,
        color: isPopular ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? AppConstants.accentColor : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.accentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Center(
                child: Text(
                  'MÁS POPULAR',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        color: AppConstants.accentColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      savings,
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppConstants.accentColor : AppConstants.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'SUSCRIBIRSE',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'PREGUNTAS FRECUENTES',
            style: GoogleFonts.outfit(
              color: AppConstants.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          _buildFAQItem('¿Puedo cancelar en cualquier momento?', 'Sí, sin compromisos ni penalizaciones.'),
          _buildFAQItem('¿Qué métodos de pago aceptan?', 'MercadoPago, PayPal, tarjetas de crédito/débito.'),
          _buildFAQItem('¿Hay prueba gratis?', 'Sí, 7 días gratis para nuevos usuarios.'),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: const Text('Próximamente', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, color: AppConstants.accentColor, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Estamos integrando los métodos de pago',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'MercadoPago • PayPal • Stripe',
              style: GoogleFonts.outfit(color: AppConstants.primaryColor, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: AppConstants.primaryColor)),
          ),
        ],
      ),
    );
  }
}
