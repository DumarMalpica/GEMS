import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/auth/widgets/gems_design.dart';
import 'package:field_colector/features/auth/widgets/login_form.dart';
import 'package:field_colector/features/auth/widgets/register_form.dart';
import 'package:field_colector/features/auth/widgets/welcome_section.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

enum LoginZone { welcome, login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialZone = LoginZone.welcome,
    this.isProfileCompletion = false,
  });

  final LoginZone initialZone;
  final bool isProfileCompletion;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late LoginZone _zone = widget.initialZone;

  late final AnimationController _zoneController;
  late final AnimationController _formController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _zoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    if (_isFormZone) {
      _zoneController.value = 1;
      _formController.value = 1;
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _formController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _isFormZone =>
      _zone == LoginZone.login || _zone == LoginZone.register;

  void _switchTo(LoginZone zone) {
    if (zone == _zone) return;
    final prev = _zone;
    if ((prev == LoginZone.login && zone == LoginZone.register) ||
        (prev == LoginZone.register && zone == LoginZone.login)) {
      context.read<Authprovider>().clearAuthFormError();
    }
    final wasForm = _isFormZone;
    setState(() => _zone = zone);

    if (zone == LoginZone.login || zone == LoginZone.register) {
      if (!wasForm) _zoneController.forward();
      _formController.forward(from: 0);
    } else {
      _zoneController.reverse();
      _formController.reverse();
    }
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (!widget.isProfileCompletion) _splashLayer(),
          if (!widget.isProfileCompletion) _loginLayer(),
          _registerLayer(),
        ],
      ),
    );
  }

  // ── Layer scaffolding ──────────────────────────────────

  Widget _zoneFader({required LoginZone zone, required Widget child}) {
    return IgnorePointer(
      ignoring: _zone != zone,
      child: AnimatedOpacity(
        opacity: _zone == zone ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  // ── Splash / Inicio ────────────────────────────────────

  Widget _splashLayer() {
    return _zoneFader(
      zone: LoginZone.welcome,
      child: Stack(
        children: [
          const Positioned.fill(child: GemsSplashBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: const WelcomeSection(),
              ),
            ),
          ),
          _splashBottomBar(),
        ],
      ),
    );
  }

  Widget _splashBottomBar() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _switchTo(LoginZone.register),
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Registrarse',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.compassRose,
                color: AppColors.secondary,
                size: 22,
              ),
              GestureDetector(
                onTap: () => _switchTo(LoginZone.login),
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ingresar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login ──────────────────────────────────────────────

  Widget _loginLayer() {
    return _zoneFader(
      zone: LoginZone.login,
      child: Column(
        children: [
          _authHeader(
            color: AppColors.primaryDark,
            titleTop: 'Bienvenido',
            titleBottom: 'de vuelta',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Column(
                  children: [
                    LoginForm(animation: _formController),
                    const SizedBox(height: 28),
                    _loginFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginFooter() {
    return GestureDetector(
      onTap: () => _switchTo(LoginZone.register),
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          children: const [
            TextSpan(
              text: '¿No tienes cuenta? ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            TextSpan(
              text: 'Regístrate',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Registro ───────────────────────────────────────────

  Widget _registerLayer() {
    return _zoneFader(
      zone: LoginZone.register,
      child: Column(
        children: [
          _authHeader(
            color: AppColors.semilleroDarkGreen,
            titleTop: 'Crea tu',
            titleBottom: 'cuenta de campo',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: const RegisterForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header compartido (login / registro) ───────────────

  Widget _authHeader({
    required Color color,
    required String titleTop,
    required String titleBottom,
  }) {
    final headerHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      220.0,
      320.0,
    );

    return GemsWaveHeader(
      height: headerHeight,
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!widget.isProfileCompletion)
                    GestureDetector(
                      onTap: () => _switchTo(LoginZone.welcome),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8, top: 2, bottom: 2),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ),
                  const GemsWordmark(
                    fontSize: 14,
                    baseColor: Colors.white,
                    accentColor: AppColors.secondary,
                    accentLetter: 'E',
                  ),
                ],
              ),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.isProfileCompletion
                          ? 'Completa tu perfil\n'
                          : '$titleTop\n',
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: widget.isProfileCompletion
                          ? 'para continuar'
                          : titleBottom,
                      style: const TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
