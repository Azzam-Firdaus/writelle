import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/editorial_button.dart';
import '../../core/widgets/writelle_logo.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_paper_surface.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../main_shell_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool isEmbedded;

  const LoginScreen({
    super.key,
    this.initialTab = 0,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late int _tabIndex; // 0 = Sign In, 1 = Create Account
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Form Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password requires at least 6 characters.')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signIn(email: email, password: password);

      if (response.user == null || response.session == null) {
        throw Exception('Login has not created an active session. Please check your email confirmation.');
      }

      final currentUser = authRepo.currentUser;
      if (currentUser == null || currentUser.id != response.user!.id) {
        throw Exception('Sanctuary session could not be established.');
      }

      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);

      if (!mounted) return;

      if (!widget.isEmbedded) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const MainShellScreen()),
            (route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Writelle login error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (errorMsg.contains('Email not confirmed')) {
        errorMsg = 'Email address not confirmed. Please check your inbox or disable "Confirm email" in Supabase Dashboard.';
      } else if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Incorrect email or password. Please verify your credentials.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not enter sanctuary: $errorMsg'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _registerConfirmPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a moniker or pen name.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a valid email address.')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password confirmations do not match.')),
      );
      return;
    }
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service & Privacy Policy to join.')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signUp(email: email, password: password);

      if (response.session != null || authRepo.isAuthenticated) {
        try {
          await authRepo.updateProfile(penName: name);
        } catch (_) {}

        ref.invalidate(currentUserProfileProvider);
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sanctuary created! Welcome to Writelle.')),
          );
          if (!widget.isEmbedded) {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainShellScreen()),
                (route) => false,
              );
            }
          }
        }
      } else {
        // If registration succeeded but requires email confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 5),
              content: Text('Registration successful! Please check your email to verify before signing in.'),
            ),
          );
          setState(() {
            _tabIndex = 0;
            _loginEmailController.text = email;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');
        if (message.contains('rate limit') || message.contains('over_email_send_rate_limit')) {
          message = 'Email rate limit reached. Please try again in a few moments.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(message),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _loginEmailController.text.trim());
    bool emailSent = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  emailSent ? Icons.mark_email_read_outlined : Icons.vpn_key_outlined,
                  color: AppColors.burntSienna,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  emailSent ? 'Link Dispatched!' : 'Lost Sanctuary Key',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!emailSent) ...[
                    const Text(
                      'Enter your account email. We will send a sanctuary key recovery link:',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedCocoa, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Account Email',
                        hintText: 'author@writelle.app',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.burntSienna.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.burntSienna, size: 44),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Password reset link dispatched to:\n${emailCtrl.text.trim()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Open that email on your device and tap the "Reset password" link. The Writelle app will open automatically to set your new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.mutedCocoa, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: Text(emailSent ? 'Close' : 'Cancel'),
              ),
              if (!emailSent)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid email address.')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.sendPasswordResetEmail(email);
                            setModalState(() {
                              isSubmitting = false;
                              emailSent = true;
                            });
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Link'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burntSienna,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK, Open Mail'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSetNewPasswordDialog() {
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface(dialogCtx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recovery link verified. Enter a new password for your sanctuary:',
                style: TextStyle(fontSize: 13, color: AppColors.mutedCocoa),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password (Min. 8 Characters)',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntSienna,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final newPass = passCtrl.text;
                      if (newPass.length < 8) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 8 characters.')),
                        );
                        return;
                      }
                      if (newPass != confirmPassCtrl.text) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Password confirmations do not match.')),
                        );
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.updatePassword(newPassword: newPass);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully! Welcome back.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(builder: (_) => const MainShellScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      passCtrl.dispose();
      confirmPassCtrl.dispose();
    });
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
      // Browser launched; when user completes OAuth, Supabase deep-link redirect
      // fires and authStateProvider listener will navigate to MainShellScreen.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      final authState = next.value;
      if (authState != null) {
        if (authState.event == AuthChangeEvent.passwordRecovery) {
          _showSetNewPasswordDialog();
          return;
        }
        if (authState.session != null) {
          ref.invalidate(currentUserProfileProvider);
      ref.invalidate(bookmarkedStoriesProvider);
      ref.invalidate(feedStoriesProvider);
      ref.invalidate(myPublishedStoriesProvider);
      ref.invalidate(myDraftStoriesProvider);
          if (mounted && !widget.isEmbedded) {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const MainShellScreen()),
                (route) => false,
              );
            }
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryColor(context)),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.auth,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Official Brand Logo
                  const Center(
                    child: WritelleLogo.hero(
                      height: 110,
                      width: 110,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Poetic Tagline
                  Text(
                    'A sanctuary for unspoken truths and honest tales',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionMeta.copyWith(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mutedCocoa,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tactile Paper Surface Container
                  WrittlePaperSurface(
                    variant: PaperSurfaceVariant.white,
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Toggle [ Sign In | Create Account ]
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.softParchment,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warmSand),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            children: [
                              // Sign In Tab Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tabIndex = 0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _tabIndex == 0 ? AppColors.pureWhite : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: _tabIndex == 0
                                          ? [
                                              BoxShadow(
                                                color: AppColors.espresso.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _tabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                        color: _tabIndex == 0 ? AppColors.espresso : AppColors.mutedCocoa,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Create Account Tab Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tabIndex = 1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _tabIndex == 1 ? AppColors.pureWhite : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: _tabIndex == 1
                                          ? [
                                              BoxShadow(
                                                color: AppColors.espresso.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _tabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                        color: _tabIndex == 1 ? AppColors.espresso : AppColors.mutedCocoa,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Tab Content: Sign In vs Create Account
                        if (_tabIndex == 0) _buildLoginForm() else _buildRegisterForm(),

                        const SizedBox(height: 20),

                        // Divider: or enter with
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.softParchment)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                _tabIndex == 0 ? 'or enter with' : 'or join with',
                                style: AppTypography.captionMeta.copyWith(
                                  fontSize: 12,
                                  color: AppColors.mutedCocoa,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.softParchment)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Google Button
                        OutlinedButton(
                          onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.warmSand, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: AppColors.warmIvory.withValues(alpha: 0.5),
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.burntSienna),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CustomPaint(
                                      size: Size(18, 18),
                                      painter: _GoogleLogoPainter(),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _tabIndex == 0 ? 'Sign In with Google' : 'Join with Google',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.espresso,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch Tab Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tabIndex == 0 ? 'New to this sanctuary?' : 'Already hold a key?',
                        style: AppTypography.uiBody.copyWith(fontSize: 13, color: AppColors.espresso),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _tabIndex = _tabIndex == 0 ? 1 : 0);
                        },
                        child: Text(
                          _tabIndex == 0 ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.burntSienna,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Label & Input
        Text(
          'Email',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'name@email.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),

        // Password Label & Input
        Text(
          'Password',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Lost Sanctuary Key
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: Text(
              'Lost your key?',
              style: AppTypography.captionMeta.copyWith(
                color: AppColors.burntSienna,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Button: Sign In
        EditorialButton(
          label: 'Sign In to Sanctuary',
          isLoading: _isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'By entering, you honor our ',
                style: AppTypography.captionMeta.copyWith(fontSize: 11, color: AppColors.mutedCocoa),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                ),
                child: Text(
                  'Terms',
                  style: AppTypography.captionMeta.copyWith(
                    fontSize: 11,
                    color: AppColors.burntSienna,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                ' & ',
                style: AppTypography.captionMeta.copyWith(fontSize: 11, color: AppColors.mutedCocoa),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
                child: Text(
                  'Privacy Policy',
                  style: AppTypography.captionMeta.copyWith(
                    fontSize: 11,
                    color: AppColors.burntSienna,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pen Name
        Text(
          'Pen Name / Alias',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _registerNameController,
          decoration: const InputDecoration(
            hintText: 'Choose your author moniker...',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        // Email
        Text(
          'Email',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'name@email.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        Text(
          'Password',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _registerPasswordController,
          obscureText: _obscureRegisterPassword,
          decoration: InputDecoration(
            hintText: 'At least 8 characters',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegisterPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password
        Text(
          'Confirm Password',
          style: AppTypography.uiBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _registerConfirmPasswordController,
          obscureText: _obscureRegisterConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Repeat password',
            prefixIcon: const Icon(Icons.lock_reset, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegisterConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRegisterConfirmPassword = !_obscureRegisterConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Consent Checkbox for Google Play Policy Compliance
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreeToTerms,
                activeColor: AppColors.burntSienna,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'I agree to the ',
                    style: AppTypography.captionMeta.copyWith(fontSize: 11.5, color: AppColors.espresso),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                    ),
                    child: Text(
                      'Terms of Service',
                      style: AppTypography.captionMeta.copyWith(
                        fontSize: 11.5,
                        color: AppColors.burntSienna,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    ' and ',
                    style: AppTypography.captionMeta.copyWith(fontSize: 11.5, color: AppColors.espresso),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                    child: Text(
                      'Privacy Policy',
                      style: AppTypography.captionMeta.copyWith(
                        fontSize: 11.5,
                        color: AppColors.burntSienna,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Button: Create Account
        EditorialButton(
          label: 'Create Sanctuary Account',
          isLoading: _isLoading,
          onPressed: _handleRegister,
        ),
      ],
    );
  }
}

/// Vector Painter for official 4-colored Google 'G' brand mark
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red (top arc: ~ -135 deg to -45 deg)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.356, 1.57, false, paint);

    // Blue (right arc: ~ -45 deg to 45 deg)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.785, 1.57, false, paint);

    // Green (bottom arc: ~ 45 deg to 135 deg)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.785, 1.57, false, paint);

    // Yellow (left arc: ~ 135 deg to 225 deg)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.356, 1.57, false, paint);

    // Center horizontal blue bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius - strokeWidth / 2,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
