import 'dart:async';

import 'package:field_colector/data/careers_asset.dart';
import 'package:field_colector/domain/mappers/register_user_dto_builder.dart';
import 'package:field_colector/domain/ports/auth_port.dart';
import 'package:field_colector/features/auth/providers/auth_provider.dart';
import 'package:field_colector/features/manual/providers/manual_intro_provider.dart';
import 'package:field_colector/features/auth/theme/auth_form_theme.dart';
import 'package:field_colector/features/auth/widgets/gems_design.dart';
import 'package:field_colector/features/auth/widgets/google_sign_in_button.dart';
import 'package:field_colector/features/utilities/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

bool _registerEmailOk(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

class _RegisterFormState extends State<RegisterForm> {
  int? _userType;
  String? _studyArea;
  String? _otherCareer;

  late final Future<List<String>> _careersFuture;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isExternalProfile = false;

  void _onFormEdited() {
    context.read<Authprovider>().clearAuthFormError();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _careersFuture = loadCareers();
    final authUser = context.read<Authprovider>().user;
    if (authUser != null && !authUser.profileComplete) {
      _isExternalProfile = true;
      final nameParts = authUser.fullName.trim().split(RegExp(r'\s+'));
      _firstNameController.text = nameParts.isEmpty ? '' : nameParts.first;
      _lastNameController.text = nameParts.length > 1
          ? nameParts.skip(1).join(' ')
          : '';
      _emailController.text = authUser.email;
    }
    for (final c in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.addListener(_onFormEdited);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.removeListener(_onFormEdited);
    }
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _confirmPasswordMismatch() {
    final confirm = _confirmPasswordController.text;
    return confirm.isNotEmpty && _passwordController.text != confirm;
  }

  bool _canSubmit() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final mail = _emailController.text.trim();
    final pwd = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (first.isEmpty || last.isEmpty) return false;
    if (!_isExternalProfile) {
      if (mail.isEmpty || !_registerEmailOk(mail)) return false;
      if (pwd.isEmpty || confirm.isEmpty || pwd != confirm) return false;
    }
    if (_userType == null) return false;
    final area = _studyArea?.trim();
    if (area == null || area.isEmpty) return false;
    if (area == 'Otra' && (_otherCareer?.trim().isEmpty ?? true)) {
      return false;
    }
    return true;
  }

  Future<void> _onRegisterPressed() async {
    final dto = buildRegisterUserDto(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      password: _isExternalProfile ? '' : _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      userType: _userType,
      studyArea: _studyArea,
      otherCareer: _otherCareer,
      externalProvider: _isExternalProfile,
    );
    if (dto == null) return;
    await _submitRegistration(dto);
  }

  Future<void> _submitRegistration(RegisterUserDto dto) async {
    setState(() => _isSubmitting = true);
    final auth = context.read<Authprovider>();
    final manualIntro = context.read<ManualIntroProvider>();
    try {
      if (_isExternalProfile) {
        final userId = auth.user?.id;
        if (userId != null && userId.isNotEmpty) {
          unawaited(manualIntro.markPendingAfterRegistration(userId));
        }
        await auth.completeExternalProfile(dto);
      } else {
        await auth.register(dto);
      }
      if (auth.errorMessage == null &&
          auth.isAuthenticated &&
          (!_isExternalProfile || auth.user?.profileComplete == true)) {
        final userId = auth.user?.id;
        if (!_isExternalProfile && userId != null && userId.isNotEmpty) {
          await manualIntro.markPendingAfterRegistration(userId);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isExternalProfile
                  ? 'Perfil completado. Bienvenido/a.'
                  : 'Cuenta creada. Bienvenido/a.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<Authprovider>().errorMessage ??
                'No se pudo registrar. Intenta de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _emailServerErrorText(
    String mailTrim,
    String? errMsg,
    AuthErrorType? errType,
  ) {
    if (errMsg == null || errType == null) return null;
    if (errType == AuthErrorType.invalidEmail ||
        errType == AuthErrorType.emailAlreadyInUse) {
      return errMsg;
    }
    return null;
  }

  String? _generalRegisterError(String? errMsg, AuthErrorType? errType) {
    if (errMsg == null) return null;
    if (errType == AuthErrorType.invalidEmail ||
        errType == AuthErrorType.emailAlreadyInUse) {
      return null;
    }
    return errMsg;
  }

  Widget _roleSelector() {
    return Row(
      children: [
        Expanded(child: _rolePill(value: 0, label: '🌿 Estudiante')),
        const SizedBox(width: 8),
        Expanded(child: _rolePill(value: 1, label: '🔬 Profesional')),
      ],
    );
  }

  Widget _rolePill({required int value, required String label}) {
    final active = _userType == value;
    return GestureDetector(
      onTap: () {
        context.read<Authprovider>().clearAuthFormError();
        setState(() => _userType = value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.semilleroViolet,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.semilleroDeepBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _careerDropdown() {
    return FutureBuilder<List<String>>(
      future: _careersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Text(
            'Error al cargar carreras',
            style: TextStyle(color: AppColors.errorText, fontSize: 12),
          );
        }

        final careers = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownMenu<String>(
              initialSelection: _studyArea,
              hintText: 'Selecciona una opción',
              trailingIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              selectedTrailingIcon: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              dropdownMenuEntries: careers.map((c) {
                return DropdownMenuEntry(
                  value: c,
                  label: c,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(
                      AuthFormTheme.menuItemTextColor,
                    ),
                  ),
                );
              }).toList(),
              onSelected: (v) {
                context.read<Authprovider>().clearAuthFormError();
                setState(() => _studyArea = v);
              },
              width: double.infinity,
            ),
            if (_studyArea == 'Otra')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GemsLabeledField(
                  label: 'Especifica tu carrera',
                  child: TextFormField(
                    style: const TextStyle(color: AuthFormTheme.fieldTextColor),
                    decoration: AuthFormTheme.fieldDecoration(
                      hintText: 'Ingresa tu carrera',
                    ),
                    onChanged: (v) {
                      context.read<Authprovider>().clearAuthFormError();
                      setState(() => _otherCareer = v);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mailTrim = _emailController.text.trim();
    return Selector<Authprovider, (String?, AuthErrorType?)>(
      selector: (_, a) => (a.errorMessage, a.lastAuthError),
      builder: (context, authErr, _) {
        final errMsg = authErr.$1;
        final errType = authErr.$2;
        final emailServerErr = _emailServerErrorText(mailTrim, errMsg, errType);
        final generalErr = _generalRegisterError(errMsg, errType);

        final emailFormatBad =
            !_isExternalProfile &&
            mailTrim.isNotEmpty &&
            !_registerEmailOk(mailTrim);
        final emailInvalid =
            !_isExternalProfile && (emailFormatBad || emailServerErr != null);
        final emailValid =
            !_isExternalProfile && mailTrim.isNotEmpty && !emailInvalid;
        final emailErrorText = _isExternalProfile
            ? null
            : (emailFormatBad ? 'Correo no válido' : emailServerErr);

        final confirmMismatch = _confirmPasswordMismatch();
        final confirmValid =
            _confirmPasswordController.text.isNotEmpty &&
            !confirmMismatch &&
            _passwordController.text.isNotEmpty;

        return Theme(
          data: AuthFormTheme.onGreen(Theme.of(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isExternalProfile) ...[
                const Text(
                  'Completa tu perfil para continuar. Estos datos son '
                  'necesarios para usar la aplicación.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  _emailController.text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.read<Authprovider>().logout(),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
              if (generalErr != null) ...[
                Text(
                  generalErr,
                  style: const TextStyle(
                    color: AppColors.errorText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _roleSelector(),
              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GemsLabeledField(
                      label: 'Nombre',
                      child: TextField(
                        controller: _firstNameController,
                        style: const TextStyle(
                          color: AuthFormTheme.fieldTextColor,
                        ),
                        decoration: AuthFormTheme.fieldDecoration(
                          hintText: 'Ana',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GemsLabeledField(
                      label: 'Apellido',
                      child: TextField(
                        controller: _lastNameController,
                        style: const TextStyle(
                          color: AuthFormTheme.fieldTextColor,
                        ),
                        decoration: AuthFormTheme.fieldDecoration(
                          hintText: 'García',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (!_isExternalProfile) ...[
                GemsLabeledField(
                  label: 'Correo',
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AuthFormTheme.fieldTextColor),
                    decoration: AuthFormTheme.fieldDecoration(
                      hintText: 'tu@correo.com',
                      errorText: emailErrorText,
                      borderColor: emailInvalid
                          ? AppColors.error
                          : (emailValid ? AppColors.semilleroDeepBlue : null),
                      suffixIcon: emailValid
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.semilleroDeepBlue,
                              size: 18,
                            )
                          : const Icon(Icons.mail_outline, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              GemsLabeledField(
                label: 'Área de estudio',
                child: _careerDropdown(),
              ),
              const SizedBox(height: 14),

              if (!_isExternalProfile) ...[
                GemsLabeledField(
                  label: 'Contraseña',
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AuthFormTheme.fieldTextColor),
                    decoration: AuthFormTheme.fieldDecoration(
                      hintText: '••••••••',
                      helperText: errType == AuthErrorType.weakPassword
                          ? 'Use al menos 6 caracteres; combine letras y números.'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  curve: Curves.easeOut,
                  child: _passwordController.text.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: GemsLabeledField(
                            label: 'Confirmar contraseña',
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(
                                color: AuthFormTheme.fieldTextColor,
                              ),
                              decoration: AuthFormTheme.fieldDecoration(
                                hintText: '••••••••',
                                errorText: confirmMismatch
                                    ? 'Las contraseñas no coinciden'
                                    : null,
                                borderColor: confirmMismatch
                                    ? AppColors.error
                                    : (confirmValid
                                          ? AppColors.semilleroDeepBlue
                                          : null),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 24),

              OutlinedButton(
                onPressed: _canSubmit() && !_isSubmitting
                    ? _onRegisterPressed
                    : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isExternalProfile
                            ? 'Completar perfil  →'
                            : 'Crear cuenta  →',
                      ),
              ),
              if (!_isExternalProfile) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                const GoogleSignInButton(),
              ],
              const SizedBox(height: 16),

              const GemsStepIndicator(activeIndex: 0),
            ],
          ),
        );
      },
    );
  }
}
