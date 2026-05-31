/// @file welcome_page.dart
/// @description Pantalla de bienvenida post-registro (onboarding).
/// Se muestra una sola vez tras crear la cuenta. Introduce las funciones
/// principales de la app y lleva al usuario a la pantalla de inicio.
/// @module Core
/// @layer Presentation
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING ITEMS
// ═══════════════════════════════════════════════════════════════════════════════

/// Elemento de la pantalla de onboarding.
///
/// Acepta o bien un [icon] (Material) o bien un [assetImage] (PNG en
/// `assets/images/`). El primer slide usa el logo corporativo; los demás
/// siguen usando iconos Material temáticos.
class _OnboardingItem {
  const _OnboardingItem({
    this.icon,
    this.assetImage,
    required this.title,
    required this.description,
  }) : assert(icon != null || assetImage != null,
              'Debe proporcionar icon o assetImage');
  final IconData? icon;
  final String?   assetImage;
  final String    title;
  final String    description;
}

const List<_OnboardingItem> _kItems = [
  _OnboardingItem(
    assetImage:  'assets/images/logo.png',
    title:       'Gestiona tus plantas',
    description: 'Registra todas tus plantas, sus cuidados y lleva un seguimiento de su salud.',
  ),
  _OnboardingItem(
    icon:        Icons.water_drop_rounded,
    title:       'Recordatorios de riego',
    description: 'Nunca olvides regar. Recibe notificaciones cuando tus plantas lo necesiten.',
  ),
  _OnboardingItem(
    icon:        Icons.cloud_outlined,
    title:       'Clima en tiempo real',
    description: 'Adaptamos los recordatorios al clima local para cuidar mejor tus plantas.',
  ),
  _OnboardingItem(
    icon:        Icons.people_outlined,
    title:       'Comunidad de plantas',
    description: 'Comparte tus plantas, consejos y aprende de otros aficionados.',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// WELCOME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Pantalla de bienvenida con un PageView de 4 slides de onboarding.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _pageCtrl = PageController();
  int   _current  = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Navegación ───────────────────────────────────────────────────────────────

  void _next() {
    if (_current < _kItems.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeInOut,
      );
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ─── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _kItems.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ──────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goToHome,
                child: Text(
                  'Omitir',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount:  _kItems.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _buildSlide(_kItems[i]),
              ),
            ),

            // ── Indicadores ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _kItems.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  i == _current ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:        i == _current
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Botón siguiente / empezar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Empezar' : 'Siguiente'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Slide ────────────────────────────────────────────────────────────────────

  Widget _buildSlide(_OnboardingItem item) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.assetImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                item.assetImage!,
                width:  120,
                height: 120,
                fit:    BoxFit.cover,
              ),
            )
          else
            Container(
              width:  120,
              height: 120,
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(item.icon, size: 64, color: AppColors.primary),
            ),
          const SizedBox(height: 40),
          Text(
            item.title,
            style:     tt.headlineMedium?.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style:     tt.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
